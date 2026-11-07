import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = "http://fajzz-hosting.kalzzptero.my.id:25582";

class ChangePasswordPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const ChangePasswordPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // --- MODERN DARK THEME ---
  static const Color bgDark = Colors.black;
  static const Color cardColor = Color(0xFF111111);
  static const Color accentBlue = Colors.white;
  static const Color darkBlue = Colors.white;
  static const Color primaryWhite = Colors.white;

  Color get textGrey => Colors.grey.shade400;
  Color get subtleGlass => Colors.white.withOpacity(0.03);
  Color get borderSubtle => Colors.white.withOpacity(0.08);
  
  LinearGradient get blueGradient => const LinearGradient(
        colors: [accentBlue, darkBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  void dispose() {
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPass = oldPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("Semua field harus diisi.");
      return;
    }

    if (newPass != confirmPass) {
      _showMessage("Password baru tidak cocok dengan konfirmasi.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/changepass"),
        body: {
          "username": widget.username,
          "oldPass": oldPass,
          "newPass": newPass,
          "sessionKey": widget.sessionKey,
        },
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        _showMessage("Password berhasil diubah!", isSuccess: true);
        oldPassCtrl.clear();
        newPassCtrl.clear();
        confirmPassCtrl.clear();
      } else {
        _showMessage(data['message'] ?? "Gagal mengubah password");
      }
    } catch (e) {
      _showMessage("Koneksi error: $e");
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: accentBlue.withOpacity(0.2)),
        ),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.info_outline,
              color: accentBlue,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isSuccess ? "Sukses" : "Peringatan",
              style: TextStyle(
                color: primaryWhite,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(msg, style: TextStyle(color: textGrey, fontSize: 14)),
        actions: [
          Center(
            child: Container(
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
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODERN INPUT WIDGET WITH GLASS DESIGN (BLUE THEME) ---
  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool isOldPassword = false,
    bool isNewPassword = false,
    bool isConfirmPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword
                ? (isOldPassword
                    ? _obscureOldPassword
                    : (isNewPassword
                        ? _obscureNewPassword
                        : (isConfirmPassword ? _obscureConfirmPassword : true)))
                : false,
            style: TextStyle(color: primaryWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Enter your $label",
              hintStyle: TextStyle(color: textGrey.withOpacity(0.5), fontSize: 13),
              prefixIcon: Icon(icon, color: accentBlue, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        (isOldPassword
                                ? _obscureOldPassword
                                : (isNewPassword
                                    ? _obscureNewPassword
                                    : _obscureConfirmPassword))
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: textGrey.withOpacity(0.6),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isOldPassword) {
                            _obscureOldPassword = !_obscureOldPassword;
                          } else if (isNewPassword) {
                            _obscureNewPassword = !_obscureNewPassword;
                          } else if (isConfirmPassword) {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          }
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: subtleGlass,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: accentBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "CHANGE PASSWORD",
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --- HEADER ICON (REDESIGNED - BLUE) ---
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: blueGradient,
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Icon(Icons.lock_reset, color: primaryWhite, size: 36),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  "UPDATE SECURITY",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Enter your old password and create a new one",
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // --- FORM INPUTS (BLUE THEME) ---
              _buildInput(
                oldPassCtrl,
                "Old Password",
                Icons.lock_outline,
                isPassword: true,
                isOldPassword: true,
              ),
              _buildInput(
                newPassCtrl,
                "New Password",
                Icons.vpn_key,
                isPassword: true,
                isNewPassword: true,
              ),
              _buildInput(
                confirmPassCtrl,
                "Confirm Password",
                Icons.enhanced_encryption,
                isPassword: true,
                isConfirmPassword: true,
              ),

              const SizedBox(height: 30),

              // --- UPDATE BUTTON (REDESIGNED - BLUE) ---
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: blueGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accentBlue.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryWhite,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.update, color: primaryWhite, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              "UPDATE PASSWORD",
                              style: TextStyle(
                                color: primaryWhite,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}