import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OwnerPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String currentUserRole;

  const OwnerPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.currentUserRole,
  });

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = [
    'member',
    'fullup',
    'reseller',
    'partner',
    'owner',
  ];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final deleteController = TextEditingController();
  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  String newUserRole = 'member';
  bool isLoading = false;

  final List<String> roleHierarchy = [
    'member',
    'fullup',
    'reseller',
    'partner',
    'owner',
  ];

  String normalizeRole(String role) {
    final lower = role.toLowerCase().trim();
    if (lower == 'pt-dev' || lower == 'pt dev' || lower == 'pt_dev') return 'developer';
    if (lower == 'admin') return 'owner';
    if (lower == 'vip') return 'fullup';
    return lower;
  }

  int get currentUserRank {
    return roleHierarchy.indexOf(normalizeRole(widget.currentUserRole));
  }

  List<String> get allowedCreateRoles {
    final normalized = normalizeRole(widget.currentUserRole);
    final map = {
      'owner': ['member', 'fullup', 'reseller', 'partner', 'owner'],
      'partner': ['member', 'fullup', 'reseller'],
      'reseller': ['member', 'fullup'],
      'fullup': const <String>[],
      'member': const <String>[],
    };
    return map[normalized] ?? const <String>[];
  }

  bool get canAccessOwnerPage {
    final normalized = normalizeRole(widget.currentUserRole);
    return [
      'owner',
      'pt',
      'tangan kanan',
      'moderator',
      'developer',
    ].contains(normalized);
  }

  // --- BLUE THEME ---
  static const Color bgDark = Color(0xFFFFFFFF);
  static const Color glassPrimary = Color(0xFFFFFFFF);
  static const Color glassSecondary = Color(0xFFF5F5F5);
  static const Color accentBlue = Colors.black;
  static const Color darkBlue = Colors.black;
  static const Color softBlue = Colors.black;
  static const Color primaryWhite = Color(0xFF111111);
  static const Color softGrey = Color(0xFF6B7280);

  LinearGradient get blueGradient => const LinearGradient(
    colors: [accentBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get dangerGradient => const LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get successGradient => const LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get warningGradient => const LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    initAnimations();
    sessionKey = widget.sessionKey;
    newUserRole = allowedCreateRoles.isNotEmpty ? allowedCreateRoles.first : 'member';
    fetchUsers();
  }

  void initAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    fadeAnimation = CurvedAnimation(
      parent: animationController, 
      curve: Curves.easeOut,
    );
    
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1), 
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController, 
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    animationController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    deleteController.dispose();
    editUsernameController.dispose();
    editDayController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        filterAndPaginate();
      } else {
        showGlassDialog("Information", data['message'] ?? 'Failed to load users.', Icons.info_outline);
      }
    } catch (_) {
      showGlassDialog("Error", "Failed to connect to server.", Icons.error_outline);
    }
    setState(() => isLoading = false);
  }

  void filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList
          .where((u) => u['role'] == selectedRole)
          .toList();
    });
  }

  List<dynamic> getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      showGlassDialog("Warning", "Please enter username to delete.", Icons.warning_amber_rounded);
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/deleteUser?key=$sessionKey&username=$username'),
      );
      final data = jsonDecode(res.body);

      if (data['deleted'] == true) {
        showGlassDialog("Success", "User deleted successfully.", Icons.check_circle_outline);
        deleteController.clear();
        fetchUsers();
      } else {
        showGlassDialog("Failed", data['message'] ?? 'Failed to delete user.', Icons.error_outline);
      }
    } catch (_) {
      showGlassDialog("Error", "Failed to connect to server.", Icons.error_outline);
    }
    setState(() => isLoading = false);
  }

      Future<void> createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      showGlassDialog("Warning", "All fields are required.", Icons.warning_amber_rounded);
      return;
    }

    if (!allowedCreateRoles.contains(newUserRole)) {
      showGlassDialog(
        "Forbidden",
        "You cannot create a ${newUserRole.toUpperCase()} account with your current role.",
        Icons.block,
      );
      return;
    }

    setState(() => isLoading = true);
    try {
            final uri = Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/userAdd').replace(queryParameters: {
        'key': sessionKey,
        'username': u,
        'password': p,
        'role': newUserRole,
        'day': d,
      });
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        showGlassDialog("Success", "Account created as ${newUserRole.toUpperCase()}.", Icons.check_circle_outline);
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = allowedCreateRoles.isNotEmpty ? allowedCreateRoles.first : 'member';
        fetchUsers();
      } else {
        showGlassDialog("Failed", data['message'] ?? 'Failed to create account.', Icons.error_outline);
      }
    } catch (_) {
      showGlassDialog("Error", "Failed to connect to server.", Icons.error_outline);
    }
    setState(() => isLoading = false);
  }

    Future<void> editUser() async {
      final u = editUsernameController.text.trim();
      final d = editDayController.text.trim();

      if (u.isEmpty || d.isEmpty) {
        showGlassDialog("Warning", "All fields are required.", Icons.warning_amber_rounded);
        return;
      }

      setState(() => isLoading = true);
      try {
        final url = Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/editUser?key=$sessionKey&username=$u&addDays=$d');
        final res = await http.get(url);
        final data = jsonDecode(res.body);

        if (data['edited'] == true) {
          showGlassDialog("Success", "Duration updated successfully.", Icons.check_circle_outline);
          editUsernameController.clear();
          editDayController.clear();
          fetchUsers();
        } else {
          showGlassDialog("Failed", data['message'] ?? 'Failed to update duration.', Icons.error_outline);
        }
      } catch (_) {
        showGlassDialog("Error", "Failed to connect to server.", Icons.error_outline);
      }
      setState(() => isLoading = false);
    }

  void showGlassDialog(String title, String message, IconData icon) {
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
                gradient: title == "Success" ? successGradient : blueGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryWhite, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: title == "Success" ? Colors.greenAccent : accentBlue,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: softGrey, fontSize: 14),
        ),
        actions: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: blueGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(color: primaryWhite, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGlassInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: softGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryWhite.withOpacity(0.05)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: type,
              style: const TextStyle(color: primaryWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Enter $label",
                hintStyle: TextStyle(color: softGrey.withOpacity(0.5), fontSize: 12),
                prefixIcon: Icon(icon, color: accentBlue, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGlassCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassPrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryWhite.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: blueGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: primaryWhite, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  color: primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget buildGlassUserItem(Map user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: glassSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryWhite.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: blueGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: primaryWhite, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: const TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: getRoleColor(user['role']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: getRoleColor(user['role']).withOpacity(0.3)),
                      ),
                      child: Text(
                        user['role'].toString().toUpperCase(),
                        style: TextStyle(
                          color: getRoleColor(user['role']),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "EXP: ${user['expiredDate']}",
                      style: TextStyle(color: softGrey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              onPressed: () async {
                final confirm = await showDeleteConfirmation(user['username']);
                if (confirm == true) {
                  deleteController.text = user['username'];
                  deleteUser();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> showDeleteConfirmation(String username) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: glassPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primaryWhite.withOpacity(0.1)),
        ),
        title: const Text(
          "Confirm Delete",
          style: TextStyle(color: primaryWhite, fontWeight: FontWeight.w700),
        ),
        content: Text(
          "Delete user '$username'?",
          style: TextStyle(color: softGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: softGrey)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: dangerGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: primaryWhite, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.redAccent;
      case 'developer':
        return Colors.purpleAccent;
      case 'moderator':
        return Colors.deepOrangeAccent;
      case 'tangan kanan':
        return Colors.blueGrey;
      case 'pt':
        return Colors.tealAccent;
      case 'partner':
        return Colors.indigoAccent;
      case 'reseller':
        return Colors.greenAccent;
      case 'fullup':
        return Colors.amber;
      case 'member':
        return Colors.cyanAccent;
      default:
        return accentBlue;
    }
  }

  Widget buildGlassPagination() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        return ElevatedButton(
          onPressed: () => setState(() => currentPage = page),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentPage == page ? accentBlue : glassSecondary,
            foregroundColor: currentPage == page ? primaryWhite : softGrey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: primaryWhite.withOpacity(0.05)),
            ),
            elevation: 0,
          ),
          child: Text("$page", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
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
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Glass Header
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      builder: (context, double scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: blueGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentBlue.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                color: primaryWhite,
                                size: 36,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => blueGradient.createShader(bounds),
                      child: const Text(
                        "OWNER DASHBOARD",
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: glassSecondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryWhite.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back, ${widget.username}",
                            style: TextStyle(color: softGrey, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Role: ${widget.currentUserRole}",
                            style: TextStyle(color: softGrey, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section 1: DELETE USER
                    buildGlassCard(
                      title: "DELETE USER",
                      icon: FontAwesomeIcons.userSlash,
                      children: [
                        buildGlassInput(
                          label: "Username",
                          controller: deleteController,
                          icon: FontAwesomeIcons.user,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: dangerGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : deleteUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryWhite,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_rounded, size: 18, color: primaryWhite),
                                      SizedBox(width: 10),
                                      Text(
                                        "DELETE ACCOUNT",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // Section 2: CREATE ACCOUNT
                    buildGlassCard(
                      title: "CREATE ACCOUNT",
                      icon: FontAwesomeIcons.userPlus,
                      children: [
                        buildGlassInput(
                          label: "Username",
                          controller: createUsernameController,
                          icon: FontAwesomeIcons.user,
                        ),
                        buildGlassInput(
                          label: "Password",
                          controller: createPasswordController,
                          icon: FontAwesomeIcons.lock,
                        ),
                        buildGlassInput(
                          label: "Duration (Days)",
                          controller: createDayController,
                          icon: FontAwesomeIcons.calendarDay,
                          type: TextInputType.number,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: glassSecondary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primaryWhite.withOpacity(0.05)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: newUserRole,
                              dropdownColor: bgDark,
                              style: const TextStyle(color: primaryWhite, fontSize: 13),
                              items: allowedCreateRoles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: getRoleColor(role),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(role.toUpperCase()),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => newUserRole = val ?? (allowedCreateRoles.isNotEmpty ? allowedCreateRoles.first : 'member')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: successGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : createAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryWhite,
                                    ),
                                  )
                                : const Text(
                                    "CREATE ACCOUNT",
                                    style: TextStyle(
                                      color: primaryWhite,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // Section 3: EXTEND DURATION
                    buildGlassCard(
                      title: "EXTEND DURATION",
                      icon: FontAwesomeIcons.clock,
                      children: [
                        buildGlassInput(
                          label: "Username",
                          controller: editUsernameController,
                          icon: FontAwesomeIcons.userEdit,
                        ),
                        buildGlassInput(
                          label: "Add Days",
                          controller: editDayController,
                          icon: FontAwesomeIcons.calendarPlus,
                          type: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: blueGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accentBlue.withOpacity(0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : editUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryWhite,
                                    ),
                                  )
                                : const Text(
                                    "ADD DAYS",
                                    style: TextStyle(
                                      color: primaryWhite,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // Section 4: USER LIST
                    buildGlassCard(
                      title: "USER LIST",
                      icon: FontAwesomeIcons.users,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: glassSecondary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primaryWhite.withOpacity(0.05)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedRole,
                              dropdownColor: bgDark,
                              style: const TextStyle(color: primaryWhite, fontSize: 13),
                              items: roleOptions.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: getRoleColor(role),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(role.toUpperCase()),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  selectedRole = val;
                                  filterAndPaginate();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: accentBlue,
                                  strokeWidth: 2,
                                ),
                              )
                            : filteredList.isEmpty
                                ? Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.person_off_outlined,
                                          color: softGrey,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "No ${selectedRole.toUpperCase()} users found",
                                          style: TextStyle(color: softGrey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      ...getCurrentPageData()
                                          .map((u) => buildGlassUserItem(u))
                                          .toList(),
                                      const SizedBox(height: 16),
                                      buildGlassPagination(),
                                    ],
                                  ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




