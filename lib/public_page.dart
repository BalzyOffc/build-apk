import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PublicChatPage extends StatefulWidget {
  final String username;
  const PublicChatPage({super.key, required this.username});

  @override
  State<PublicChatPage> createState() => _PublicChatPageState();
}

class _PublicChatPageState extends State<PublicChatPage> {
  // --- URL SERVER ---
  final String baseUrl = "http://fajzz-hosting.kalzzptero.my.id:25582"; 

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  List<dynamic> _messages = [];
  Timer? _refreshTimer;
  bool _isSending = false;

  // --- STYLE BARU (NEON BLUE THEME) ---
  final Color _primaryNeonBlue = const Color(0xFF00E5FF); // Bright Neon Blue / Cyan
  final Color _softNeonBlue = const Color(0xFF80DEEA); // Soft Cyan
  final Color _bgDark = const Color(0xFF0A0F1D); // Cyberpunk Deep Dark Blue
  final Color _bubbleMe = const Color(0xFF00E5FF).withOpacity(0.25); // Neon Blue Glow Bubble
  final Color _bubbleOther = const Color(0xFF1E293B); // Dark Slate Grey

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    
    // Auto Refresh Chat Setiap 2 Detik (Polling)
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- FUNGSI API ---

  Future<void> _fetchMessages() async {
    try {
      final res = await http.post(Uri.parse("$baseUrl/get-public-chat"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          List newMsgs = data['messages'];
          
          // Cek apakah ada pesan baru, jika ya scroll ke bawah
          bool shouldScroll = newMsgs.length > _messages.length;

          if (mounted) {
            setState(() {
              _messages = newMsgs;
            });
            
            if (shouldScroll) _scrollToBottom();
          }
        }
      }
    } catch (e) {
      // Silent error agar tidak mengganggu UI
    }
  }

  Future<void> _sendMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    setState(() => _isSending = true);

    try {
      await http.post(
        Uri.parse("$baseUrl/send-public-chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": widget.username,
          "message": text,
        }),
      );
      await _fetchMessages(); // Refresh langsung
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mengirim pesan", style: TextStyle(color: Colors.white)), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally { 
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- UI BUILDER (NEON BLUE THEME) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, // Background Cyberpunk Dark
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            _buildHeader(),

            // CHAT LIST
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['username'] == widget.username;
                  return _buildChatBubble(msg, isMe);
                },
              ),
            ),

            // INPUT AREA
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _bgDark,
        border: Border(bottom: BorderSide(color: _primaryNeonBlue.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(color: _primaryNeonBlue.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_rounded, color: _softNeonBlue),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("LIGHT PUBLIC", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _primaryNeonBlue, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text("Live • ${_messages.length} messages", 
                    style: TextStyle(color: _softNeonBlue.withOpacity(0.7), fontSize: 11)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChatBubble(dynamic msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Nama User (Jika bukan saya)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(msg['username'], 
                  style: TextStyle(color: _softNeonBlue, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            
            // Bubble Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? _bubbleMe : _bubbleOther,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 20),
                ),
                border: isMe ? Border.all(color: _primaryNeonBlue.withOpacity(0.5), width: 1) : null,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg['message'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(msg['time'] ?? "", 
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // Sedikit lebih terang dari bgDark
        border: Border(top: BorderSide(color: _primaryNeonBlue.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _primaryNeonBlue.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white),
                cursorColor: _primaryNeonBlue,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: _softNeonBlue.withOpacity(0.4)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey : _primaryNeonBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!_isSending)
                    BoxShadow(color: _primaryNeonBlue.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
                ]
              ),
              child: Icon(
                _isSending ? Icons.hourglass_top_rounded : Icons.send_rounded, 
                color: isMe ? Colors.black : Colors.white, size: 22 // Menyesuaikan kontras icon send
              ),
            ),
          )
        ],
      ),
    );
  }
}