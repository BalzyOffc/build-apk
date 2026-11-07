import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _splashController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _showSplash = true;

  // --- RED THEME ---
  static const Color bgDark = Colors.black;
  static const Color glassPrimary = Color(0x1AFFFFFF);
  static const Color glassSecondary = Color(0x0DFFFFFF);
  static const Color accentRed = Colors.white;
  static const Color darkRed = Color(0xFF000000);
  static const Color softRed = Colors.white;
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFA0A0A0);

  @override
  void initState() {
    super.initState();
    
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    
    _splashController.forward();
    
    // Hide splash screen after 5 seconds
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return _buildSplashScreen();
    }
    
    return _buildMainScreen();
  }
  
  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _splashController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeInAnimation.value * (1 - _fadeOutAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          colors: [accentRed, softRed, darkRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: const Text(
                        "LIGHT",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryWhite,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildMainScreen() {
    return Scaffold(
      backgroundColor: bgDark,
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
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: GridPainter(), // Grid tanpa titik-titik
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildTitle(),
                  const SizedBox(height: 16),
                  _buildSubtitle(),
                  const SizedBox(height: 48),
                  _buildSignInButton(),
                  const SizedBox(height: 12),
                  _buildContactSection(),
                  const SizedBox(height: 40),
                  _buildFooter(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accentRed, darkRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentRed.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentRed, darkRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: primaryWhite,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTitle() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: glassPrimary,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: primaryWhite.withOpacity(0.1), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: primaryWhite.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [accentRed, softRed, darkRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: const Text(
                  "LIGHT",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryWhite,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSubtitle() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: glassSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryWhite.withOpacity(0.05)),
              ),
              child: Text(
                "Advanced Security & Protection System",
                style: TextStyle(
                  color: softGrey,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSignInButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentRed, darkRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accentRed.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, "/login");
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, color: primaryWhite, size: 20),
                    SizedBox(width: 12),
                    Text(
                      "SIGN IN",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryWhite,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContactSection() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: glassPrimary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryWhite.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: glassSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryWhite.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cable, size: 12, color: accentRed),
                        const SizedBox(width: 8),
                        Text(
                          "CONNECT WITH US",
                          style: TextStyle(
                            color: accentRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassContactButton(
                          icon: FontAwesomeIcons.telegram,
                          label: "Telegram",
                          url: "https://t.me/ownernya_sangat_ramah",
                          color: const Color(0xFF0088cc),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGlassContactButton(
                          icon: FontAwesomeIcons.whatsapp,
                          label: "WhatsApp",
                          url: "https://wa.me/6281973026970",
                          color: const Color(0xFF25D366),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildGlassContactButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return InkWell(
      onTap: () => openUrl(url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: glassSecondary,
          border: Border.all(color: primaryWhite.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: primaryWhite,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFooter() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: glassSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryWhite.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Text(
                    "© 2026 developer LIGHT",
                    style: TextStyle(
                      color: softGrey.withOpacity(0.8),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusChip(Icons.shield, "Secure", accentRed),
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: softGrey.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      _buildStatusChip(Icons.verified, "Reliable", softRed),
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: softGrey.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      _buildStatusChip(Icons.bolt, "Professional", darkRed),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: softGrey.withOpacity(0.7),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ✅ Grid Painter tanpa titik-titik (clean)
class GridPainter extends CustomPainter {
  static const Color accentRed = Color(0xFFF44336);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Regular grid lines
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}