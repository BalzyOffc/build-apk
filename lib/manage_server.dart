import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageServerPage extends StatefulWidget {
  final String keyToken;
  const ManageServerPage({super.key, required this.keyToken});

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> {
  List<Map<String, dynamic>> vpsList = [];
  bool isLoading = false;

  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  // --- TEMA DEEP PURPLE MODERN ---
  final Color bgDark = const Color(0xFF0A0A2A);
  final Color deepPurple = const Color(0xFF6B3FA0);
  final Color lightPurple = const Color(0xFF9B6BFF);
  final Color primaryWhite = Colors.white;
  final Color textGrey = Colors.grey.shade400;
  final Color subtleGlass = Colors.white.withOpacity(0.03);
  final Color borderSubtle = Colors.white.withOpacity(0.08);

  @override
  void initState() {
    super.initState();
    _fetchVpsList();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _fetchVpsList() async {
    setState(() => isLoading = true);
    final uri = Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/myServer?key=${widget.keyToken}');
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      setState(() {
        vpsList = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {
      _showError("Failed to fetch VPS data.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _addVps() async {
    final host = _hostController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      _showError("Please fill all fields.");
      return;
    }

    final uri = Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/addServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
        'username': user,
        'password': pass,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _hostController.clear();
        _userController.clear();
        _passController.clear();
        _fetchVpsList();
      } else {
        _showError(data['error'] ?? 'Failed to add VPS');
      }
    } catch (_) {
      _showError("Connection failed.");
    }
  }

  Future<void> _deleteVps(String host) async {
    final uri = Uri.parse('http://fajzz-hosting.kalzzptero.my.id:25582/delServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _fetchVpsList();
      } else {
        _showError("Failed to delete VPS.");
      }
    } catch (_) {
      _showError("Connection failed.");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lightPurple.withOpacity(0.2)),
        ),
        title: Text(
          "Error",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          msg,
          style: TextStyle(color: textGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(color: lightPurple, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lightPurple.withOpacity(0.2)),
        ),
        title: Text(
          "Add VPS",
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput("IP / Host", _hostController),
            const SizedBox(height: 12),
            _buildInput("Username", _userController),
            const SizedBox(height: 12),
            _buildInput("Password", _passController, isPassword: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: TextStyle(color: textGrey),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [deepPurple, lightPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addVps();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "ADD",
                style: TextStyle(
                  color: primaryWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: subtleGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: primaryWhite, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: lightPurple, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          "Manage Server",
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: lightPurple, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgDark,
              deepPurple.withOpacity(0.05),
              bgDark,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: deepPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.dns, color: lightPurple, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "My VPS List",
                        style: TextStyle(
                          fontSize: 16,
                          color: primaryWhite,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [deepPurple, lightPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: primaryWhite, size: 20),
                      onPressed: _showAddDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: borderSubtle,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: lightPurple,
                          strokeWidth: 2,
                        ),
                      )
                    : vpsList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.dns_outlined,
                                  size: 64,
                                  color: textGrey.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No VPS added yet",
                                  style: TextStyle(
                                    color: textGrey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap the + button to add your first VPS",
                                  style: TextStyle(
                                    color: textGrey.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: vpsList.length,
                            itemBuilder: (context, index) {
                              final vps = vpsList[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: subtleGlass,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderSubtle),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: deepPurple.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.computer,
                                      color: lightPurple,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    vps['host'],
                                    style: TextStyle(
                                      color: primaryWhite,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "User: ${vps['username']}",
                                    style: TextStyle(
                                      color: textGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteVps(vps['host']),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}