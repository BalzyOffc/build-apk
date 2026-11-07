import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'dashboard_page.dart';

const String baseUrl = "http://fajzz-hosting.kalzzptero.my.id:25582";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool obscurePassword = true;
  bool freeRegistrationEnabled = true;
  String? androidId;

  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;

  // --- AURORA GLASS THEME ---
  static const Color bgDark = Color(0xFF07111F);
  static const Color glassPrimary = Color(0xD90D1E32);
  static const Color glassSecondary = Color(0xFF102A43);
  static const Color accentRed = Color(0xFF38BDF8);
  static const Color darkRed = Color(0xFF2563EB);
  static const Color softRed = Color(0xFF7DD3FC);
  static const Color primaryWhite = Colors.white;
  static const Color softGrey = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    initAnimations();
    initLogin();
    _loadFreeRegistrationStatus();
  }

  Future<void> _loadFreeRegistrationStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/free-registration-status'));
      if (!mounted) return;
      final data = jsonDecode(response.body);
      setState(() => freeRegistrationEnabled = data['enabled'] == true);
    } catch (_) {}
  }

  void initAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    
    fadeAnimation = CurvedAnimation(
      parent: animationController, 
      curve: Curves.easeOut,
    );
    
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController, 
      curve: Curves.easeOutCubic,
    ));
    
    scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
        "$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey",
      );

      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(
                  username: savedUser,
                  password: savedPass,
                  role: data['role'],
                  sessionKey: data['key'],
                  expiredDate: data['expiredDate'],
                  listBug: (data['listBug'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                  listBugGlobal: (data['listBugGlobal'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                  listBugGroup: (data['listBugGroup'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                  listDoos: (data['listDDoS'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                  news: (data['news'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                  globalSenderLimit: data['globalSenderLimit'] is int ? data['globalSenderLimit'] : null,
                  globalSenderRemaining: data['globalSenderRemaining'] is int ? data['globalSenderRemaining'] : null,
                  globalSenderUsed: data['globalSenderUsed'] is int ? data['globalSenderUsed'] : null,
                  globalSenderNextResetAt: data['globalSenderNextResetAt'] is int ? data['globalSenderNextResetAt'] : null,
                  globalSenderResetHours: data['globalSenderResetHours'] is int ? data['globalSenderResetHours'] : null,
                ),
              ),
            );
          }
        }
      } catch (_) {}
    }
  }

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        showGlassDialog(
          title: "Access Expired",
          message: "Your access has expired. Please renew your subscription.",
          icon: Icons.timer_outlined,
          color: Colors.orange,
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? "").toLowerCase();

        if (errorMsg.contains("perangkat") ||
            errorMsg.contains("device") ||
            errorMsg.contains("another")) {
          showGlassDialog(
            title: "Active Session",
            message: "This account is logged in on another device.\nPlease logout first.",
            icon: Icons.devices,
            color: Colors.orangeAccent,
          );
        } else {
          showGlassDialog(
            title: "Login Failed",
            message: "Invalid username or password.",
            icon: Icons.error_outline,
            color: accentRed,
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                username: username,
                password: password,
                role: validData['role'],
                sessionKey: validData['key'],
                expiredDate: validData['expiredDate'],
                listBug: (validData['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listBugGlobal: (validData['listBugGlobal'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
                listBugGroup: (validData['listBugGroup'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
                listDoos: (validData['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (validData['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                globalSenderLimit: validData['globalSenderLimit'] is int ? validData['globalSenderLimit'] : null,
                globalSenderRemaining: validData['globalSenderRemaining'] is int ? validData['globalSenderRemaining'] : null,
                globalSenderUsed: validData['globalSenderUsed'] is int ? validData['globalSenderUsed'] : null,
                globalSenderNextResetAt: validData['globalSenderNextResetAt'] is int ? validData['globalSenderNextResetAt'] : null,
                globalSenderResetHours: validData['globalSenderResetHours'] is int ? validData['globalSenderResetHours'] : null,
              ),
            ),
          );
        }
      }
    } catch (e) {
      showGlassDialog(
        title: "Connection Error",
        message: "Failed to connect to server.\nPlease check your internet connection.",
        icon: Icons.wifi_off_outlined,
        color: Colors.red,
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _createAccount(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'androidId': androidId ?? 'unknown_device',
        }),
      );
      final data = jsonDecode(response.body);

      if (!mounted) return;
      if (response.statusCode == 201 && data['success'] == true) {
        Navigator.pop(context);
        showGlassDialog(
          title: 'Account Created',
          message: data['message'] ?? 'Akun berhasil dibuat. Silakan login.',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF16A34A),
        );
      } else {
        showGlassDialog(
          title: 'Create Account Failed',
          message: data['message'] ?? 'Akun gagal dibuat.',
          icon: Icons.error_outline,
          color: Colors.red,
        );
      }
    } catch (_) {
      if (!mounted) return;
      showGlassDialog(
        title: 'Connection Error',
        message: 'Gagal terhubung ke server.',
        icon: Icons.wifi_off_outlined,
        color: Colors.red,
      );
    }
  }

  void _showCreateAccountDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool dialogLoading = false;
    bool dialogObscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Create Account',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: dialogObscurePassword,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(dialogObscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setDialogState(
                      () => dialogObscurePassword = !dialogObscurePassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Akun free berlaku selama 3 hari dan satu device hanya bisa membuat satu akun.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: dialogLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: dialogLoading
                  ? null
                  : () async {
                      final username = usernameController.text.trim();
                      final password = passwordController.text.trim();
                      if (username.isEmpty || password.isEmpty) {
                        showGlassDialog(
                          title: 'Invalid Input',
                          message: 'Username dan password wajib diisi.',
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange,
                        );
                        return;
                      }
                      setDialogState(() => dialogLoading = true);
                      await _createAccount(username, password);
                      if (mounted && Navigator.of(dialogContext).canPop()) {
                        setDialogState(() => dialogLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: dialogLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    ).then((_) {
      usernameController.dispose();
      passwordController.dispose();
    });
  }

  void showGlassDialog({
    required String title,
    required String message,
    required IconData icon,
    Color color = Colors.redAccent,
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: glassPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: primaryWhite.withOpacity(0.1), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: softGrey, fontSize: 14, height: 1.4),
        ),
        actions: [
          if (showContact)
            TextButton(
              onPressed: () async {
                await launchUrl(
                  Uri.parse("https://t.me/ownernya_sangat_ramah"),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentRed, darkRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Contact Admin",
                  style: TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: softGrey, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          Positioned.fill(child: _buildAuroraBackground()),
          SafeArea(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: SlideTransition(
                    position: slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        children: [
                          _buildBrandHeader(),
                          const SizedBox(height: 30),
                          ScaleTransition(
                            scale: scaleAnimation,
                            child: _buildLoginCard(),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'SECURE ACCESS  •  LIGHT SYSTEMS',
                            style: TextStyle(
                              color: Colors.white.withOpacity(.42),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuroraBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF07111F), Color(0xFF0B1D33), Color(0xFF081321)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -110,
          right: -70,
          child: _glowOrb(250, const Color(0xFF0EA5E9).withOpacity(.18)),
        ),
        Positioned(
          bottom: -130,
          left: -90,
          child: _glowOrb(280, const Color(0xFF4F46E5).withOpacity(.16)),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _LoginGridPainter()),
        ),
      ],
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 30)],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(.24), width: 1.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFF38BDF8).withOpacity(.32), blurRadius: 28, spreadRadius: 3),
            ],
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 18),
        const Text(
          'LIGHT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'ENTER THE NEXT GENERATION',
          style: TextStyle(
            color: accentRed,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: _loginCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(color: accentRed, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'WELCOME BACK',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue to your workspace',
                  style: TextStyle(color: softGrey, fontSize: 11.5),
                ),
                const SizedBox(height: 24),
                buildGlassInput(userController, 'Username', Icons.person_outline),
                const SizedBox(height: 14),
                buildGlassInput(passController, 'Password', Icons.lock_outline, isPassword: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _loginCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildGlassButton(),
                const SizedBox(height: 12),
                if (freeRegistrationEnabled)
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _showCreateAccountDialog,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('CREATE ACCOUNT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentRed,
                        side: BorderSide(color: accentRed.withOpacity(.55)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                _buildContactButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _loginCardDecoration() {
    return BoxDecoration(
      color: glassPrimary,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(.14)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(.28), blurRadius: 34, offset: const Offset(0, 18)),
      ],
    );
  }

  Future<void> _launchContactUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildContactButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildContactButton(
              title: 'HELP',
              icon: Icons.telegram,
              colors: const [Color(0xFF0088CC), Color(0xFF00C6FF), Color(0xFF004080)],
              shadowColor: const Color(0xFF0088CC),
              onTap: () => _launchContactUrl('https://t.me/ownernya_sangat_ramah'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildContactButton(
              title: 'INFORMASI APPS',
              icon: Icons.chat_bubble_outline,
              colors: const [Color(0xFF11998E), Color(0xFF25D366), Color(0xFF38EF7D)],
              shadowColor: const Color(0xFF25D366),
              onTap: () => _launchContactUrl(
                'https://whatsapp.com/channel/0029Vb8PkQY9sBI2nMz0aL41',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required String title,
    required IconData icon,
    required List<Color> colors,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(.45),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 21),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildGlassInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: glassSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscurePassword : false,
        style: const TextStyle(color: primaryWhite, fontSize: 15),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: softRed, fontSize: 13),
          prefixIcon: Icon(icon, color: accentRed, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: softGrey,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: accentRed.withOpacity(0.5), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget buildGlassButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : login,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFF2563EB).withOpacity(.35), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _LoginGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.035)
      ..strokeWidth = .7;
    const step = 34.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}