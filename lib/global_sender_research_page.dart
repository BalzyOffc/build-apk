import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = "http://fajzz-hosting.kalzzptero.my.id:25582";

class GlobalSenderResearchPage extends StatefulWidget {
  final String sessionKey;
  final String role;

  const GlobalSenderResearchPage({
    super.key,
    required this.sessionKey,
    required this.role,
  });

  @override
  State<GlobalSenderResearchPage> createState() => _GlobalSenderResearchPageState();
}

class _GlobalSenderResearchPageState extends State<GlobalSenderResearchPage> {
  bool _isLoading = false;
  String _message = '';

  Future<void> _runResearch() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/researchGlobalSender?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _message = '✅ Riset sender global berhasil. Semua akun dikembalikan penuh sesuai batas masing-masing.';
        });
      } else {
        setState(() {
          _message = data['message'] ?? 'Gagal menjalankan riset sender global.';
        });
      }
    } catch (_) {
      setState(() {
        _message = '⚠️ Gagal terhubung ke server.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloper = widget.role.toLowerCase() == 'developer';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        title: const Text('Riset Sender Global'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.science_rounded, color: Color(0xFF111827), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reset Kuota Sender Global',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isDeveloper
                      ? 'Fitur ini akan mengembalikan semua akun ke kuota sender global penuh sesuai batas masing-masing role.'
                      : 'Hanya role developer yang bisa mengakses fitur ini.',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isDeveloper && !_isLoading ? _runResearch : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.restart_alt_rounded),
                    label: Text(_isLoading ? 'Memproses...' : 'Jalankan Riset Sender'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (_message.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(_message, style: const TextStyle(color: Color(0xFF111827))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
