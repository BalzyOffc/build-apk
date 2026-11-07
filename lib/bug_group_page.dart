import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class BugGroupPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String role;
  final String expiredDate;
  final List<Map<String, dynamic>> listBugGroup;

  const BugGroupPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.role,
    required this.expiredDate,
    required this.listBugGroup,
  });

  @override
  State<BugGroupPage> createState() => _BugGroupPageState();
}

class _BugGroupPageState extends State<BugGroupPage> {
  final TextEditingController _groupLinkController = TextEditingController();
  String? _selectedBugId;
  bool _isSending = false;
  String? _responseMessage;
  bool _warningShown = false;

  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFFB0B0B0);
  final Color _borderWhite = Colors.white.withOpacity(0.18);

  @override
  void initState() {
    super.initState();
    if (widget.listBugGroup.isNotEmpty) {
      _selectedBugId = widget.listBugGroup[0]['bug_id']?.toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGroupWarning();
    });
  }

  @override
  void dispose() {
    _groupLinkController.dispose();
    super.dispose();
  }

  void _showGroupWarning() {
    if (_warningShown) return;
    _warningShown = true;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'PERINGATAN',
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'MOHON NOMOR SENDER SUDAH BERADA DI GROUP YG INGIN DI BUG',
          style: TextStyle(color: _textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: _textWhite)),
          ),
        ],
      ),
    );
  }

  bool _isValidGroupTarget(String value) {
    final groupLink = RegExp(r'chat\.whatsapp\.com\/[A-Za-z0-9_-]+');
    final groupJid = RegExp(r'^[0-9]{1,20}@g\.us$');
    return groupLink.hasMatch(value) || groupJid.hasMatch(value);
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold)),
        content: Text(message, style: TextStyle(color: _textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: _textWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBugGroup() async {
    final target = _groupLinkController.text.trim();
    if (!_isValidGroupTarget(target)) {
      _showAlert('LINK GROUP TIDAK VALID', 'Masukkan link group WA atau JID group yang benar.');
      return;
    }
    if (_selectedBugId == null || _selectedBugId!.isEmpty) {
      _showAlert('PILIH BUG', 'Pilih bug group terlebih dahulu.');
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final encodedTarget = Uri.encodeComponent(target);
      final response = await http.get(Uri.parse(
        '$baseUrl/sendBug?key=${widget.sessionKey}&target=$encodedTarget&bug=$_selectedBugId&senderMode=private',
      )).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (data['valid'] != true) {
        _setResponse('error', 'Session key tidak valid. Silakan login ulang.');
      } else if (data['cooldown'] == true) {
        _setResponse('warning', 'Cooldown aktif! Tunggu ${data['wait'] ?? 0} detik lagi.');
      } else if (data['sended'] == true) {
        _setResponse('success', 'Bug berhasil dikirim ke group!');
      } else {
        _setResponse('error', 'Gagal mengirim. Silakan coba lagi.');
      }
    } catch (e) {
      final message = e.toString().contains('TimeoutException')
          ? 'Request timeout. Periksa koneksi internet.'
          : 'Koneksi error. Periksa jaringan dan coba lagi.';
      _setResponse('error', message);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _setResponse(String type, String message) {
    setState(() {
      _responseMessage = '$type|$message';
    });
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderWhite, width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('BUG GROUP'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/walpaper.jpg'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.12),
              Colors.black.withOpacity(0.72),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Peringatan',
                            style: TextStyle(
                              color: _textWhite,
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            )),
                        const SizedBox(height: 10),
                        Text(
                          'MOHON NOMOR SENDER SUDAH BERADA DI GROUP YG INGIN DI BUG',
                          style: TextStyle(color: _textGrey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LINK GROUP TARGET',
                            style: TextStyle(
                              color: _textWhite,
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            )),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _groupLinkController,
                          style: TextStyle(color: _textWhite, fontFamily: 'ShareTechMono'),
                          cursorColor: _textWhite,
                          decoration: InputDecoration(
                            hintText: 'Masukkan link group WA / group JID',
                            hintStyle: TextStyle(color: _textGrey.withOpacity(0.6)),
                            prefixIcon: Icon(Icons.link_rounded, color: _textGrey),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: _borderWhite),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: _borderWhite),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PILIH BUG GROUP',
                            style: TextStyle(
                              color: _textWhite,
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            )),
                        const SizedBox(height: 14),
                        if (widget.listBugGroup.isEmpty)
                          Center(
                            child: Text(
                              'Tidak ada daftar bug group tersedia.',
                              style: TextStyle(color: _textGrey),
                            ),
                          )
                        else ...[
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.listBugGroup.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final bug = widget.listBugGroup[index];
                                final bugId = bug['bug_id']?.toString() ?? '';
                                final selected = bugId == _selectedBugId;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedBugId = bugId),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 190,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: selected ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: selected ? Colors.white : _borderWhite,
                                        width: selected ? 1.6 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (bug['bug_name'] as String? ?? 'BUG').toUpperCase(),
                                          style: TextStyle(
                                            color: selected ? _textWhite : _textGrey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        Text(
                                          bugId.toUpperCase(),
                                          style: TextStyle(color: _textGrey, fontSize: 12, fontFamily: 'ShareTechMono'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(widget.listBugGroup.length, (index) {
                              final selected = widget.listBugGroup[index]['bug_id']?.toString() == _selectedBugId;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: selected ? 18 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: selected ? Colors.white : Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendBugGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                          : const Text('KIRIM BUG GROUP', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_responseMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildResponseBanner(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponseBanner() {
    final parts = _responseMessage!.split('|');
    final status = parts[0];
    final message = parts.length > 1 ? parts[1] : '';
    Color background = Colors.white.withOpacity(0.08);
    Color textColor = _textGrey;
    IconData icon = Icons.info_outline;

    if (status == 'success') {
      background = Colors.green.withOpacity(0.15);
      textColor = Colors.greenAccent;
      icon = Icons.check_circle_outline;
    } else if (status == 'warning') {
      background = Colors.orange.withOpacity(0.18);
      textColor = Colors.orangeAccent;
      icon = Icons.warning_amber_rounded;
    } else if (status == 'error') {
      background = Colors.red.withOpacity(0.18);
      textColor = Colors.redAccent;
      icon = Icons.error_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontFamily: 'ShareTechMono'),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _responseMessage = null),
            child: Icon(Icons.close_rounded, color: textColor, size: 18),
          ),
        ],
      ),
    );
  }
}
