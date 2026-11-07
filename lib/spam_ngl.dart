import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NglPage extends StatefulWidget {
  const NglPage({super.key});

  @override
  State<NglPage> createState() => _NglPageState();
}

class _NglPageState extends State<NglPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isRunning = false;
  int counter = 0;
  int successCount = 0;
  int failCount = 0;
  String statusLog = "";
  Timer? timer;

  static const Color bgDark = Color(0xFF0A0A2A);
  static const Color deepPurple = Color(0xFF6B3FA0);
  static const Color lightPurple = Color(0xFF9B6BFF);
  static const Color primaryWhite = Colors.white;

  Color get textGrey => Colors.grey.shade400;
  Color get subtleGlass => Colors.white.withOpacity(0.03);
  Color get borderSubtle => Colors.white.withOpacity(0.08);
  LinearGradient get purpleGradient => const LinearGradient(
        colors: [deepPurple, lightPurple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  String generateDeviceId(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  Future<bool> sendMessage(String username, String message) async {
    final deviceId = generateDeviceId(42);
    final url = Uri.parse("https://ngl.link/api/submit");

    final headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0",
      "Accept": "*/*",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": "https://ngl.link/$username",
      "Origin": "https://ngl.link"
    };

    final body = "username=$username&question=$message&deviceId=$deviceId&gameSlug=&referrer=";

    try {
      final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.contains('success') || responseBody.contains('"status":"ok"')) {
          return true;
        } else if (responseBody.contains('rate_limit') || responseBody.contains('too many')) {
          return false;
        }
        return response.statusCode == 200;
      }
      return false;
    } catch (e) {
      debugPrint("Send error: $e");
      return false;
    }
  }

  Future<void> sendWithRetry(String username, String message) async {
    final bool success = await sendMessage(username, message);
    
    if (mounted) {
      setState(() {
        counter++;
        if (success) {
          successCount++;
          statusLog = "✅ [$successCount/$counter] Message sent successfully";
        } else {
          failCount++;
          statusLog = "❌ [$failCount/$counter] Failed - Rate limited or error";
        }
      });
    }
  }

  void startLoop() {
    final username = usernameController.text.trim();
    final message = messageController.text.trim();

    if (username.isEmpty || message.isEmpty) {
      setState(() {
        statusLog = "⚠️ Please fill in username and message!";
      });
      return;
    }

    if (username.contains(' ') || username.isEmpty) {
      setState(() {
        statusLog = "⚠️ Invalid username format!";
      });
      return;
    }

    setState(() {
      isRunning = true;
      counter = 0;
      successCount = 0;
      failCount = 0;
      statusLog = "▶️ Starting auto sender...";
    });

    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (isRunning && mounted) {
        sendWithRetry(username, message);
      }
    });
  }

  void stopLoop() {
    setState(() {
      isRunning = false;
      statusLog = "⏹️ Stopped. Total: $counter messages ($successCount success, $failCount failed)";
    });
    timer?.cancel();
  }

  @override
  void dispose() {
    timer?.cancel();
    usernameController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          "NGL Auto Sender",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
            color: primaryWhite,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Input Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: subtleGlass,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameController,
                        style: TextStyle(color: primaryWhite, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: "NGL Username",
                          labelStyle: TextStyle(color: lightPurple, fontSize: 12),
                          hintText: "example: username_ngl",
                          hintStyle: TextStyle(color: textGrey.withOpacity(0.5), fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderSubtle),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: lightPurple, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: subtleGlass,
                          prefixIcon: Icon(Icons.person, color: lightPurple, size: 18),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        style: TextStyle(color: primaryWhite, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: "Message",
                          labelStyle: TextStyle(color: lightPurple, fontSize: 12),
                          hintText: "Enter your message...",
                          hintStyle: TextStyle(color: textGrey.withOpacity(0.5), fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderSubtle),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: lightPurple, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: subtleGlass,
                          prefixIcon: Icon(Icons.message, color: lightPurple, size: 18),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Control Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: subtleGlass,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: isRunning ? null : purpleGradient,
                            color: isRunning ? textGrey.withOpacity(0.3) : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: isRunning ? null : startLoop,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, color: isRunning ? textGrey : primaryWhite, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  "START",
                                  style: TextStyle(
                                    color: isRunning ? textGrey : primaryWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: !isRunning ? null : purpleGradient,
                            color: !isRunning ? textGrey.withOpacity(0.3) : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: !isRunning ? null : stopLoop,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stop, color: !isRunning ? textGrey : primaryWhite, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  "STOP",
                                  style: TextStyle(
                                    color: !isRunning ? textGrey : primaryWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Status Section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: subtleGlass,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: deepPurple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.info_outline, color: lightPurple, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "STATUS LOG",
                              style: TextStyle(
                                color: primaryWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Status Log
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: subtleGlass,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                statusLog.isEmpty ? "Waiting for command..." : statusLog,
                                style: TextStyle(
                                  color: _getStatusColor(statusLog),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Counter Stats
                        if (counter > 0)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: lightPurple.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(Icons.send, "Total", "$counter", lightPurple),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: borderSubtle,
                                ),
                                _buildStatItem(Icons.check_circle, "Success", "$successCount", Colors.greenAccent),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: borderSubtle,
                                ),
                                _buildStatItem(Icons.error, "Failed", "$failCount", Colors.redAccent),
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: deepPurple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: lightPurple.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: lightPurple, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Auto-send every 3 seconds. Stop manually when done.",
                                  style: TextStyle(
                                    color: textGrey,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: primaryWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: textGrey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('✅')) return Colors.greenAccent;
    if (status.contains('❌')) return Colors.redAccent;
    if (status.contains('⚠️')) return Colors.orangeAccent;
    if (status.contains('▶️')) return lightPurple;
    if (status.contains('⏹️')) return Colors.orangeAccent;
    return textGrey;
  }
}
