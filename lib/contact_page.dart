import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // --- BLACK/WHITE THEME ---
  static const Color bgDark = Colors.black;
  static const Color darkBlue = Colors.white;
  static const Color accentBlue = Colors.white;
  
  // Subtle glass effect with lower opacity
  static const Color subtleGlass = Color.fromARGB(8, 255, 255, 255); // ~3% opacity
  static const Color borderSubtle = Color.fromARGB(20, 255, 255, 255); // ~8% opacity

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: accentBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Customer Service",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgDark,
              accentBlue.withOpacity(0.05),
              bgDark,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 48,
                    color: accentBlue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Need Help?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Contact us through our social media platforms below",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Grid Buttons
                const Column(
                  children: [
                    _buildContactButton(
                      label: "Telegram",
                      icon: FontAwesomeIcons.telegram,
                      color: Color(0xFF0088CC),
                      url: "https://t.me/ownernya_sangat_ramah",
                    ),
                    SizedBox(height: 12),
                    _buildContactButton(
                      label: "WhatsApp",
                      icon: FontAwesomeIcons.whatsapp,
                      color: Color(0xFF25D366),
                      url: "https://wa.me/6281973026970",
                    ),
                    SizedBox(height: 12),
                    _buildContactButton(
                      label: "TikTok",
                      icon: FontAwesomeIcons.tiktok,
                      color: Colors.white,
                      url: "https://www.tiktok.com/@amellovelyy07",
                    ),
                    SizedBox(height: 12),
                    _buildContactButton(
                      label: "Instagram",
                      icon: FontAwesomeIcons.instagram,
                      color: Color(0xFFE4405F),
                      url: "https://www.instagram.com/",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _buildContactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String url;

  const _buildContactButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.url,
  });

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: ContactPage.subtleGlass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ContactPage.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}