import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['member', 'fullup', 'reseller', 'partner', 'owner'];
  String selectedRole = 'member';
  String createRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();

  final editUsernameController = TextEditingController();
  final editDayController = TextEditingController();

  bool isLoading = false;

  // --- BLUE THEME ---
  static const Color bgDark = Color(0xFFFFFFFF);
  static const Color accentBlue = Colors.black;
  static const Color darkBlue = Colors.black;
  static const Color softBlue = Colors.black;
  static const Color primaryWhite = Color(0xFF111111);
  static const Color softGrey = Color(0xFF6B7280);
  static const Color subtleGlass = Color(0xFFF5F5F5);
  static const Color borderSubtle = Color(0xFFE5E7EB);

  LinearGradient get blueGradient => const LinearGradient(
    colors: [accentBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get cyanGradient => const LinearGradient(
    colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  void dispose() {
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    editUsernameController.dispose();
    editDayController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/listUsers?key=${widget.keyToken}'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        filterAndPaginate();
      } else {
        showAlert("Information", data['message'] ?? 'Failed to load users.');
      }
    } catch (_) {
      showAlert("Error", "Failed to connect to server.");
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

  Future<void> createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      showAlert("Warning", "All fields are required.");
      return;
    }

    final days = int.tryParse(d);
    if (days == null || days <= 0) {
      showAlert("Warning", "Please enter a valid number of days.");
      return;
    }

    if (days > 30) {
      showAlert("Warning", "Maximum duration is 30 days.");
      return;
    }

    // Allow server to validate creator permission for selected role (owner may create any role).

    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/userAdd').replace(queryParameters: {
        'key': widget.keyToken,
        'username': u,
        'password': p,
        'role': createRole,
        'day': d,
      });
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        showAlert("Success", "Account created as ${createRole.toUpperCase()} successfully!");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        createRole = 'member';
        fetchUsers();
      } else {
        String msg = data['message'] ?? 'Failed to create account.';
        // Show server raw response for debugging when authorization issues occur
        if (data['authorized'] != null && data['authorized'] == false) {
          msg = "Not authorized: ${data['message'] ?? 'No message'}";
        }
        if (data['invalidDay'] == true) {
          msg += " (Max 30 days for Reseller)";
        }
        showAlert("Failed", msg);
      }
    } catch (e) {
      showAlert("Error", "Connection error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> editUser() async {
    final u = editUsernameController.text.trim();
    final d = editDayController.text.trim();

    if (u.isEmpty || d.isEmpty) {
      showAlert("Warning", "All fields are required.");
      return;
    }

    final days = int.tryParse(d);
    if (days == null || days <= 0) {
      showAlert("Warning", "Please enter a valid number of days.");
      return;
    }

    if (days > 30) {
      showAlert("Warning", "Maximum extension is 30 days.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          "http://fajzz-hosting.kalzzptero.my.id:25582/editUser?key=${widget.keyToken}&username=$u&addDays=$d"));
      final data = jsonDecode(res.body);

      if (data['edited'] == true) {
        showAlert("Success", "Duration updated successfully!");
        editUsernameController.clear();
        editDayController.clear();
        fetchUsers();
      } else {
        showAlert("Failed", data['message'] ?? 'Failed to update duration.');
      }
    } catch (e) {
      showAlert("Error", "Connection error: $e");
    }
    setState(() => isLoading = false);
  }

  void showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentBlue.withOpacity(0.2)),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: accentBlue),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(color: primaryWhite, fontWeight: FontWeight.w600),
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
              decoration: BoxDecoration(
                gradient: blueGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
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

  Widget buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String hint = "",
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: primaryWhite, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: softGrey.withOpacity(0.5), fontSize: 12),
          labelStyle: const TextStyle(color: accentBlue, fontSize: 12),
          prefixIcon: const Icon(Icons.person, color: accentBlue, size: 18),
          filled: true,
          fillColor: subtleGlass,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentBlue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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
        color: subtleGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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

  Widget buildUserItem(Map user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: subtleGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: accentBlue, size: 18),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ROLE: ${user['role'].toString().toUpperCase()} | EXP: ${user['expiredDate']}",
                  style: TextStyle(color: softGrey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPagination() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        return ElevatedButton(
          onPressed: () => setState(() => currentPage = page),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentPage == page ? accentBlue : Colors.transparent,
            foregroundColor: currentPage == page ? primaryWhite : softGrey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: borderSubtle),
            ),
            elevation: 0,
          ),
          child: Text("$page", style: const TextStyle(fontSize: 11)),
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: blueGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "SELLER DASHBOARD",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 32),

                // SECTION 1: CREATE ACCOUNT
                buildGlassCard(
                  title: "CREATE ACCOUNT",
                  icon: FontAwesomeIcons.userPlus,
                  children: [
                    buildInput(
                      label: "Username",
                      controller: createUsernameController,
                      icon: FontAwesomeIcons.user,
                    ),
                    buildInput(
                      label: "Password",
                      controller: createPasswordController,
                      icon: FontAwesomeIcons.lock,
                    ),
                    buildInput(
                      label: "Duration (Days)",
                      controller: createDayController,
                      icon: FontAwesomeIcons.calendarDay,
                      type: TextInputType.number,
                      hint: "Max 30 days",
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: subtleGlass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: createRole,
                          dropdownColor: bgDark,
                          style: const TextStyle(color: primaryWhite, fontSize: 13),
                          items: roleOptions.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => createRole = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: blueGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryWhite,
                                ),
                              )
                            : const Text(
                                "CREATE ACCOUNT",
                                style: TextStyle(
                                  color: primaryWhite,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // SECTION 2: EXTEND DURATION
                buildGlassCard(
                  title: "EXTEND DURATION",
                  icon: FontAwesomeIcons.clock,
                  children: [
                    buildInput(
                      label: "Username",
                      controller: editUsernameController,
                      icon: FontAwesomeIcons.userEdit,
                      hint: "Member username",
                    ),
                    buildInput(
                      label: "Add Days",
                      controller: editDayController,
                      icon: FontAwesomeIcons.calendarPlus,
                      type: TextInputType.number,
                      hint: "Max 30 days",
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: cyanGradient,
                        borderRadius: BorderRadius.circular(12),
                        ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : editUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryWhite,
                                ),
                              )
                            : const Text(
                                "ADD DAYS",
                                style: TextStyle(
                                  color: primaryWhite,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // SECTION 3: USER LIST
                buildGlassCard(
                  title: "ROLE LIST",
                  icon: FontAwesomeIcons.users,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: subtleGlass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: bgDark,
                          style: const TextStyle(color: primaryWhite, fontSize: 13),
                          items: roleOptions.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.toUpperCase()),
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
                        : Column(
                            children: [
                              ...getCurrentPageData()
                                  .map((u) => buildUserItem(u))
                                  .toList(),
                              buildPagination(),
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
    );
  }
}
