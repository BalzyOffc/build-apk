import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InfoPage extends StatefulWidget {
  final String sessionKey;

  const InfoPage({super.key, required this.sessionKey});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // --- State Data ---
  Map<String, dynamic>? serverInfo;
  bool isLoading = true;

  // API Status State
  bool isApiOnline = false;
  int apiPingMs = 0;
  Color apiStatusColor = Colors.grey;
  String apiStatusText = "Checking...";
  Timer? _pingTimer;

  // --- MODERN GLASS SOFT THEME (RED) ---
  static const Color bgDark = Color(0xFF0A0E1A);
  static const Color glassPrimary = Color(0x1AFFFFFF);
  static const Color glassSecondary = Color(0x0DFFFFFF);
  static const Color accentRed = Color(0xFF00BFFF);
  static const Color darkRed = Color(0xFF142244);
  static const Color softRed = Color(0xFF7FFFD4);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFF94A3B8);

  final LinearGradient primaryGradient = const LinearGradient(
    colors: [accentRed, darkRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final LinearGradient warningGradient = const LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchServerInfo();
    _startApiPingLoop();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1), 
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchServerInfo() async {
    try {
      final res = await http.get(
        Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/getServerInfo?key=${widget.sessionKey}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          serverInfo = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startApiPingLoop() {
    _checkApiPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkApiPing();
    });
  }

  Future<void> _checkApiPing() async {
    final start = DateTime.now();
    try {
      final res = await http.get(
        Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/ping?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 3));

      final end = DateTime.now();
      final duration = end.difference(start).inMilliseconds;

      if (res.statusCode == 200) {
        setState(() {
          isApiOnline = true;
          apiPingMs = duration;
          if (duration < 200) {
            apiStatusColor = Colors.greenAccent;
          } else if (duration < 500) {
            apiStatusColor = Colors.amber;
          } else {
            apiStatusColor = Colors.orangeAccent;
          }
          apiStatusText = "Online (${duration}ms)";
        });
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      setState(() {
        isApiOnline = false;
        apiPingMs = 0;
        apiStatusColor = Colors.redAccent;
        apiStatusText = "Offline";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryWhite.withOpacity(0.08)),
            ),
            child: const Text(
              "Info",
              style: TextStyle(color: primaryWhite, fontWeight: FontWeight.w600),
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: accentRed,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final List<Map<String, String>> rulesList = [
      {
        "title": "Larangan Barter Akun",
        "desc": "Akun tidak boleh ditukar dengan barang, jasa, atau akun lain dalam bentuk apa pun."
      },
      {
        "title": "Larangan Membagikan Akun",
        "desc": "Setiap akun bersifat pribadi dan hanya boleh digunakan oleh pemilik akun yang terdaftar."
      },
      {
        "title": "Larangan Menjual Akun",
        "desc": "Member TIDAK diperbolehkan menjual akun. Penjualan akun hanya boleh dilakukan oleh role yang diizinkan secara resmi."
      },
      {
        "title": "Larangan Jual Durasi Ilegal",
        "desc": "Dilarang menjual akses harian, mingguan, trial, atau sejenisnya di luar ketentuan yang telah ditetapkan."
      },
      {
        "title": "Larangan Banting Harga",
        "desc": "Dilarang merusak atau menurunkan harga yang telah ditentukan (banting harga) di bawah ketentuan LIGHT."
      },
    ];

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: glassSecondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryWhite.withOpacity(0.08)),
          ),
          child: const Text(
            "RULES & INFO",
            style: TextStyle(
              color: primaryWhite,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              accentRed.withOpacity(0.15),
              bgDark,
              bgDark,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: GridPainter(),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. API STATUS GLASS CARD
                      _buildGlassApiStatus(),
                      const SizedBox(height: 24),

                      // 2. HEADER PERATURAN
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.gavel, color: primaryWhite, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "USER RULES",
                            style: TextStyle(
                              color: primaryWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: primaryGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 3. LIST PERATURAN GLASS CARDS
                      ...rulesList.asMap().entries.map((entry) {
                        int index = entry.key + 1;
                        Map<String, String> rule = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildGlassRuleCard(index, rule),
                        );
                      }).toList(),

                      const SizedBox(height: 20),

                      // 4. SANKSI GLASS CARD
                      _buildSanctionsCard(),

                      const SizedBox(height: 24),

                      // 5. FOOTER DISCLAIMER GLASS CARD
                      _buildDisclaimerCard(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassApiStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassPrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryWhite.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: apiStatusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: apiStatusColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "System Status: ${apiStatusText.toUpperCase()}",
              style: TextStyle(
                color: softGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (isApiOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "Active",
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassRuleCard(int index, Map<String, String> rule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassPrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryWhite.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "$index",
                style: const TextStyle(
                  color: primaryWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule['title']!,
                  style: const TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rule['desc']!,
                  style: TextStyle(
                    color: softGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSanctionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.08),
            Colors.red.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: warningGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.warning_amber_rounded, color: primaryWhite, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            "SANCTIONS",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Violation of any rules above will result in:",
            style: TextStyle(
              color: softGrey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentRed.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Text(
              "PERMANENT ACCOUNT DELETION",
              style: TextStyle(
                color: primaryWhite,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "No refunds, compensation, or appeals",
            style: TextStyle(
              color: softGrey,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: glassPrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryWhite.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentRed.withOpacity(0.3),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(Icons.shield_moon_rounded, color: primaryWhite, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            "These rules are established to maintain security, comfort, and stability of the LIGHT ecosystem. By using this application, users are considered to have agreed to all the above rules.",
            style: TextStyle(
              color: softGrey,
              fontSize: 12,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            height: 3,
            width: 60,
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Grid Painter for background
class GridPainter extends CustomPainter {
  static const Color accentRed = Color(0xFFF44336);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    
    const gridSize = 30.0;
    
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw accent grid lines (every 5th line)
    final accentPaint = Paint()
      ..color = accentRed.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }
    
    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }
    
    // Draw dots at grid intersections
    final dotPaint = Paint()
      ..color = accentRed.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    
    for (double x = 0; x <= size.width; x += gridSize) {
      for (double y = 0; y <= size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}