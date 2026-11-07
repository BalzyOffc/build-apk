import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;

  const ProfilePage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? profileImage;
  final ImagePicker picker = ImagePicker();

  // --- BLUE THEME ---
  static const Color bgDark = Color(0xFF0B0B0E);
  static const Color cardColor = Color(0xFF1A1A1E);
  static const Color accentBlue = Colors.white;
  static const Color darkBlue = Colors.white;
  static const Color softBlue = Colors.white;
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFFA0A0A0);
  static const Color borderSubtle = Color.fromARGB(13, 255, 255, 255);
  static const Color successGreen = Color(0xFF4CAF50);

  LinearGradient get blueGradient => const LinearGradient(
    colors: [accentBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    loadProfileImage();
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${widget.username}');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        profileImage = File(imagePath);
      });
    }
  }

  String censorText(String text, {bool isPassword = false}) {
    if (text.isEmpty) return "N/A";
    if (isPassword) {
      return "••••••••";
    }
    if (text.length <= 2) return "${text.substring(0, 1)}••";
    return "${text.substring(0, 2)}${'•' * (text.length - 2)}";
  }

  Future<void> showImageSourceDialog() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: accentBlue),
              title: const Text("Camera", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: accentBlue),
              title: const Text("Gallery", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${widget.username}', imageFile.path);

        setState(() {
          profileImage = imageFile;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
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
          "My Profile",
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar Profile
              Center(
                child: GestureDetector(
                  onTap: showImageSourceDialog,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: blueGradient,
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: profileImage != null
                              ? Image.file(
                                  profileImage!,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  FontAwesomeIcons.userAstronaut,
                                  size: 52,
                                  color: primaryWhite.withOpacity(0.8),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: bgDark, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Username with glass effect
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  widget.username,
                  style: const TextStyle(
                    color: primaryWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentBlue.withOpacity(0.2), darkBlue.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentBlue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, size: 14, color: accentBlue),
                    const SizedBox(width: 6),
                    Text(
                      widget.role.toUpperCase(),
                      style: const TextStyle(
                        color: accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Modern Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.calendar_today,
                      label: "Member Since",
                      value: "2024",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.verified,
                      label: "Status",
                      value: "Active",
                      color: successGreen,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Info Cards without copy functionality
              _buildInfoCard(
                icon: Icons.person_outline,
                label: "Username",
                value: censorText(widget.username),
              ),
              const SizedBox(height: 12),
              
              _buildInfoCard(
                icon: Icons.lock_outline,
                label: "Password",
                value: censorText(widget.password, isPassword: true),
                isPassword: true,
              ),
              const SizedBox(height: 12),
              
              _buildInfoCard(
                icon: Icons.verified_user_outlined,
                label: "Account Type",
                value: widget.role.toUpperCase(),
              ),
              const SizedBox(height: 12),
              
              _buildInfoCard(
                icon: Icons.calendar_today_outlined,
                label: "Expired Date",
                value: widget.expiredDate,
              ),
              const SizedBox(height: 12),
              
              _buildInfoCard(
                icon: Icons.vpn_key,
                label: "Session Key",
                value: "••••••••••••••••••••",
                isSessionKey: true,
              ),

              const SizedBox(height: 32),

              // Change Password Button
              Container(
                width: double.infinity,
                height: 54,
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
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_reset, color: primaryWhite, size: 20),
                  label: const Text(
                    "CHANGE PASSWORD",
                    style: TextStyle(
                      color: primaryWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangePasswordPage(
                          username: widget.username,
                          sessionKey: widget.sessionKey,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              
              // Security Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "For security reasons, sensitive information cannot be copied",
                        style: TextStyle(
                          color: softGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    Color color = accentBlue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: primaryWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: softGrey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool isPassword = false,
    bool isSessionKey = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: softGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: isPassword || isSessionKey ? accentBlue : primaryWhite,
                          fontSize: isSessionKey ? 13 : 15,
                          fontWeight: isSessionKey ? FontWeight.w500 : FontWeight.w600,
                          fontFamily: isSessionKey ? 'ShareTechMono' : null,
                          letterSpacing: isSessionKey ? 1 : 0,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isPassword)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "ENCRYPTED",
                          style: TextStyle(
                            color: accentBlue,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (isSessionKey)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "HIDDEN",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ✅ HAPUS KARAKTER '+' YANG ADA DI SINI