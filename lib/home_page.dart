// BAGIAN 1 DARI 8
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listBugGlobal;
  final String role;
  final String expiredDate;
  final int? globalSenderLimit;
  final int? globalSenderRemaining;
  final int? globalSenderUsed;
  final int? globalSenderNextResetAt;
  final int? globalSenderResetHours;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    this.listBugGlobal = const [],
    required this.expiredDate,
    this.globalSenderLimit,
    this.globalSenderRemaining,
    this.globalSenderUsed,
    this.globalSenderNextResetAt,
    this.globalSenderResetHours,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  static DateTime? _sharedGlobalSenderNextResetAt;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _resultCtrl;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  final targetController = TextEditingController();
  final PageController _bugPageController = PageController(viewportFraction: 0.72);

  String? _selectedBugId;
  bool _isSending = false;
  String? _responseMessage; // format: "type|message"
  int _currentBugPage = 0;
  bool _globalSenderEnabled = true;
  String _globalSenderStatusMessage = '';
    // BAGIAN 2 DARI 8
  // Sender
  List<String> _globalSenders = [];
  bool _isLoadingSenders = false;
  int _privateSenderCount = 0;
  int _globalSenderCount = 0;
  bool _loadingSender = false;
  Timer? _senderTimer;
  Timer? _globalStatusTimer;
  Timer? _quotaResetTimer;
  DateTime? _globalCooldownUntil;
  int _globalSenderLimit = 3;
  int _globalSenderRemaining = 3;
  int _globalSenderUsed = 0;
  DateTime? _globalSenderNextResetAt;
  int _globalSenderResetHours = 10;

  String _selectedSender = 'private';

  bool get _canAccessGlobalSenderRole => widget.role.toLowerCase().trim() != 'member';

  // Monochrome Theme Colors (Glass + Grey)
  final Color _primaryWhite = Colors.white;
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFFBFC7D1);

  bool get canAccessGlobalSender {
    if (!_canAccessGlobalSenderRole) return false;
    final remaining = _globalSenderRemaining.clamp(0, _globalSenderLimit);
    return remaining > 0;
  }

  bool get _isDeveloper {
    final normalized = widget.role.toLowerCase();
    return normalized == 'developer' || normalized == 'pt-dev' || normalized == 'pt dev' || normalized == 'pt_dev';
  }

  @override
  void initState() {
    super.initState();

    final roleLimit = _getGlobalSenderLimitForRole(widget.role);
    _globalSenderLimit = widget.globalSenderLimit ?? roleLimit;
    _globalSenderRemaining = widget.globalSenderRemaining ?? roleLimit;
    _globalSenderUsed = widget.globalSenderUsed ?? _globalSenderUsed;
    _globalSenderResetHours = 10;

    if (widget.globalSenderNextResetAt != null) {
      _globalSenderNextResetAt = DateTime.fromMillisecondsSinceEpoch(widget.globalSenderNextResetAt!);
    } else if (_sharedGlobalSenderNextResetAt != null) {
      _globalSenderNextResetAt = _sharedGlobalSenderNextResetAt;
    } else {
      _globalSenderNextResetAt = DateTime.now().add(const Duration(hours: 10));
    }

    _sharedGlobalSenderNextResetAt = _globalSenderNextResetAt;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _fetchSenderStats();
    _loadGlobalSenders();
    _refreshGlobalSenderStatus();
    _initializeGlobalQuota();
    _syncGlobalSenderQuota();
    _senderTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchSenderStats();
    });
    _globalStatusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_globalCooldownUntil != null && DateTime.now().isAfter(_globalCooldownUntil!)) {
        if (mounted) {
          setState(() => _globalCooldownUntil = null);
        }
      }
    });

    _quotaResetTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _syncGlobalSenderQuota();
    });

    if (widget.listBug.isNotEmpty) {
      final firstBug = widget.listBug[0];
      _selectedBugId = firstBug['bug_id'] as String? ?? '0';
    }
  }

  List<Map<String, dynamic>> get _activeBugList {
    if (_selectedSender == 'global' && widget.listBugGlobal.isNotEmpty) {
      return widget.listBugGlobal;
    }
    return widget.listBug;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _resultCtrl.dispose();
    targetController.dispose();
    _bugPageController.dispose();
    _senderTimer?.cancel();
    _globalStatusTimer?.cancel();
    _quotaResetTimer?.cancel();
    super.dispose();
  }
    // BAGIAN 3 DARI 8
  // ─── Fetch sender stats (private & global count) ──────────────────────────
  Future<void> _fetchSenderStats() async {
    if (_loadingSender) return;
    setState(() => _loadingSender = true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/getSenderStats?key=${widget.sessionKey}"),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _privateSenderCount = data['private'] ?? 0;
            _globalSenderCount = data['global'] ?? 0;
            _loadingSender = false;
          });
        } else {
          setState(() => _loadingSender = false);
        }
      } else {
        setState(() => _loadingSender = false);
      }
    } catch (_) {
      setState(() => _loadingSender = false);
    }
  }

  // ─── Load global senders list from server ─────────────────────────────────
  Future<void> _loadGlobalSenders() async {
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(Uri.parse(
        '$baseUrl/getActiveSenders?key=${widget.sessionKey}',
      )).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['senders'] != null) {
        if (mounted) {
          setState(() {
            _globalSenders = List<String>.from(data['senders']);
            _globalSenderCount = _globalSenders.length;
          });
        }
      } else {
        if (mounted) setState(() => _globalSenders = []);
      }
    } catch (_) {
      if (mounted) setState(() => _globalSenders = []);
    } finally {
      if (mounted) setState(() => _isLoadingSenders = false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Future<void> _refreshGlobalSenderStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getGlobalSenderStatus?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _globalSenderEnabled = data['enabled'] ?? true;
            _globalSenderStatusMessage = data['message'] ?? '';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _initializeGlobalQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _quotaStorageKey();
      final saved = prefs.getString(key);
      if (saved == null) return;

      final data = jsonDecode(saved);
      if (!mounted) return;

      setState(() {
        if (data['limit'] is int) {
          _globalSenderLimit = data['limit'] as int;
        }
        if (data['remaining'] is int) {
          _globalSenderRemaining = (data['remaining'] as int).clamp(0, _globalSenderLimit);
        }
        if (data['used'] is int) {
          _globalSenderUsed = data['used'] as int;
        }
        if (data['nextResetAt'] is int) {
          _globalSenderNextResetAt = DateTime.fromMillisecondsSinceEpoch(data['nextResetAt'] as int);
        } else if (data['nextResetAt'] is String) {
          _globalSenderNextResetAt = DateTime.tryParse(data['nextResetAt'] as String);
        }
        if (_globalSenderNextResetAt == null) {
          _globalSenderNextResetAt = DateTime.now().add(Duration(hours: _globalSenderResetHours));
        }

        _sharedGlobalSenderNextResetAt = _globalSenderNextResetAt;
      });
    } catch (_) {}
  }

  Future<void> _persistGlobalQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _quotaStorageKey();
      final payload = {
        'limit': _globalSenderLimit,
        'remaining': _globalSenderRemaining,
        'used': _globalSenderUsed,
        'nextResetAt': (_globalSenderNextResetAt?.millisecondsSinceEpoch ?? 0),
        'resetHours': _globalSenderResetHours,
      };
      await prefs.setString(key, jsonEncode(payload));
    } catch (_) {}
  }

  String _quotaStorageKey() {
    final safeUser = widget.username.isEmpty ? 'guest' : widget.username;
    final safeRole = widget.role.isEmpty ? 'member' : widget.role;
    return 'global_sender_quota_${safeUser}_$safeRole';
  }

  void _syncGlobalSenderQuota() {
    if (!mounted) return;

    final now = DateTime.now();
    if (_globalSenderNextResetAt != null && !now.isBefore(_globalSenderNextResetAt!)) {
      _globalSenderRemaining = _globalSenderLimit.clamp(0, _globalSenderLimit);
      _globalSenderUsed = 0;
      _globalSenderNextResetAt = now.add(Duration(hours: _globalSenderResetHours));

      _sharedGlobalSenderNextResetAt = _globalSenderNextResetAt;

      if (mounted) {
        setState(() {});
      }
      _persistGlobalQuota();
    }
  }

  int _getGlobalSenderLimitForRole(String roleName) {
    final normalized = roleName.toLowerCase().trim();
    if (normalized == 'fullup' || normalized == 'vip' || normalized == 'pt' || normalized == 'pt-dev' || normalized == 'pt dev' || normalized == 'pt_dev') {
      return 5;
    }
    if (normalized == 'reseller') {
      return 10;
    }
    if (normalized == 'partner') {
      return 15;
    }
    if (normalized == 'owner') {
      return 25;
    }
    return 0;
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 5) return null; 
    return cleaned;
  }

  void _setResponse(String type, String msg) {
    if (!mounted) return;
    setState(() => _responseMessage = '$type|$msg');
    _resultCtrl.forward(from: 0);
  }

  bool _canUseGlobalSenderNow() {
    if (_selectedSender != 'global') return true;

    if (!_globalSenderEnabled) {
      _showAlert('✕ Sender Global Ditutup', 'Sender global sedang ditutup oleh dev. Semua user tidak bisa menggunakannya.');
      return false;
    }

    _syncGlobalSenderQuota();

    if (_globalSenderCount == 0) {
      _showAlert('✕ No Global Sender', 'Tidak ada global sender tersedia.');
      return false;
    }

    final remaining = _globalSenderRemaining.clamp(0, _globalSenderLimit);
    if (remaining <= 0) {
      _showAlert('✕ Kuota Habis', 'Kouta sender global anda hari ini telah habis');
      return false;
    }

    return true;
  }

  String _getGlobalStatusText() {
    if (_selectedSender != 'global') {
      return _globalSenderEnabled
          ? 'Pilih sender global untuk melihat sisa kuota'
          : 'Sender global sedang ditutup oleh bot.';
    }

    if (!_globalSenderEnabled) {
      return _globalSenderStatusMessage.isNotEmpty
          ? _globalSenderStatusMessage
          : 'Sender global sedang ditutup oleh bot.';
    }

    final remaining = _globalSenderRemaining.clamp(0, _globalSenderLimit);
    if (remaining <= 0) {
      return 'Kouta sender global anda hari ini telah habis';
    }

    final limit = _globalSenderLimit > 0 ? _globalSenderLimit : 1;
    final resetTime = _globalSenderNextResetAt != null
        ? ' • reset ${_globalSenderNextResetAt!.toLocal().toString().split(' ').last.substring(0, 5)}'
        : '';
    return 'Sisa global: $remaining / $limit$resetTime';
  }
    // BAGIAN 4 DARI 8
  // ─── Send Bug ─────────────────────────────────────────────────────────────
  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    if (formatPhoneNumber(rawInput) == null) {
      _showAlert("✕ Nomor Tidak Valid",
          "Periksa kembali format nomor tujuan Anda.");
      return;
    }

    if (_selectedBugId == null || _selectedBugId!.isEmpty) {
      _showAlert("✕ No Bug Selected", "Pilih 1 bug untuk dikirim.");
      return;
    }

    if (_selectedSender == 'private' && _privateSenderCount == 0) {
      _showAlert("✕ No Private Sender", "Tidak ada private sender tersedia.");
      return;
    }
    if (_selectedSender == 'global' && !_canUseGlobalSenderNow()) {
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });
    _resultCtrl.reset();

    try {
      final encodedTarget = Uri.encodeComponent(rawInput);
      final res = await http.get(Uri.parse(
        '$baseUrl/sendBug'
        '?key=$key'
        '&target=$encodedTarget'
        '&bug=${_selectedBugId}'
        '${_selectedSender == 'global' ? '&senderMode=global' : '&sender=private'}',
      )).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data['globalSenderForbidden'] == true) {
        _setResponse('error', 'Role member tidak memiliki akses sender global.');
      } else if (data['valid'] == false) {
        _setResponse('error', 'Session key tidak valid. Silakan login ulang.');
      } else if (data['cooldown'] == true) {
        final wait = data['wait'] ?? 0;
        _setResponse('warning', 'Cooldown aktif! Tunggu $wait detik lagi.');
      } else if (data['sended'] == true) {
        final role = data['role'] ?? widget.role;
        if (_selectedSender == 'global') {
          final serverRemaining = data['globalSenderRemaining'];
          if (serverRemaining is int) {
            _globalSenderRemaining = serverRemaining.clamp(0, _globalSenderLimit);
          } else {
            _globalSenderRemaining = (_globalSenderRemaining - 1).clamp(0, _globalSenderLimit);
          }

          if (data['globalSenderLimit'] is int) {
            _globalSenderLimit = data['globalSenderLimit'];
          }
          if (data['globalSenderNextResetAt'] != null) {
            _globalSenderNextResetAt = DateTime.fromMillisecondsSinceEpoch(data['globalSenderNextResetAt']);
          } else {
            _globalSenderNextResetAt = DateTime.now().add(const Duration(hours: 10));
          }

          _sharedGlobalSenderNextResetAt = _globalSenderNextResetAt;
          await _persistGlobalQuota();
        }
        _setResponse('success', 'Bug berhasil dikirim ke $rawInput! [$role]');
        targetController.clear();
      } else if (data['globalSenderBlocked'] == true) {
        _setResponse('error', 'Kuota sender global sudah habis. Tunggu reset berikutnya.');
      } else {
        _setResponse('error', 'Gagal mengirim. Server sedang maintenance.');
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _setResponse('error', 'Request timeout. Periksa koneksi internet.');
      } else {
        _setResponse('error', 'Koneksi error. Periksa jaringan dan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── Alert Dialog ─────────────────────────────────────────────────────────
  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.black.withOpacity(0.08), width: 1.5),
          ),
          title: Text(title,
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold)),
          content: Text(msg, style: TextStyle(color: _textGrey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK",
                  style: TextStyle(
                      color: _primaryWhite, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
    // BAGIAN 5 DARI 8
  // ─── Glass Card Helper ────────────────────────────────────────────────────
  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
    BorderRadius? borderRadius,
    Color? borderColor,
    double blurSigma = 12,
    Color? bgColor,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white.withOpacity(0.10),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ─── Top App Bar ──────────────────────────────────────────────────────────

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        border: Border(
          bottom: BorderSide(color: Color(0xFF20242A), width: 1.4),
        ),
      ),
      child: Row(
        children: [
          _retroIconButton(Icons.menu_rounded, () {}),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: Text(
                'LIGHT',
                style: const TextStyle(
                  color: Color(0xFF15181D),
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          _retroIconButton(Icons.settings_rounded, () {}),
        ],
      ),
    );
  }

  Widget _retroIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 44,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFC52F),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF15181D), width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF15181D),
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF15181D), size: 21),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 168,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEEFF),
              border: Border.all(color: const Color(0xFF15181D), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF15181D),
                  offset: Offset(4, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/banner.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/walpaper.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.62),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.92),
                              border: Border.all(
                                color: const Color(0xFF15181D),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF15181D),
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'WELCOME BACK',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 9,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Orbitron',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC52F),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF15181D),
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              'ONLINE',
                              style: TextStyle(
                                color: Color(0xFF15181D),
                                fontFamily: 'ShareTechMono',
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LIGHT BUG CENTER',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih target dan payload dari daftar yang tersedia.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontFamily: 'ShareTechMono',
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _headerBadge(widget.role.toUpperCase()),
                              const SizedBox(width: 7),
                              _headerBadge('EXPIRED ${widget.expiredDate}'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF15181D),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF15181D),
          fontFamily: 'ShareTechMono',
          fontWeight: FontWeight.bold,
          fontSize: 8,
        ),
      ),
    );
  }
  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  fontFamily: 'Orbitron')),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: _textGrey, fontSize: 9, fontFamily: 'ShareTechMono')),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 52, color: Colors.black.withOpacity(0.08));
  }
    // BAGIAN 6 DARI 8
   // --- Target Input + Bug Carousel ──────────────────────────────────────────

  Widget _buildNomorAndBugPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _retroSectionCard(
          icon: Icons.phone_android_rounded,
          title: 'TARGET NUMBER',
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF15181D),
                width: 1.7,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF15181D),
                  offset: Offset(2, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: targetController,
              style: const TextStyle(
                color: Color(0xFF15181D),
                fontFamily: 'ShareTechMono',
                fontSize: 12,
              ),
              cursorColor: const Color(0xFF15181D),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g. 8xxx...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontFamily: 'ShareTechMono',
                  fontSize: 11,
                ),
                prefixIcon: const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFF2196F3),
                  size: 19,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 45,
                  minHeight: 40,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 10,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _retroSectionCard(
          icon: Icons.bug_report_rounded,
          title: 'SELECT PAYLOAD BUG',
          trailing: IconButton(
            onPressed: () {
              _fetchSenderStats();
              _loadGlobalSenders();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF15181D),
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 104,
                child: PageView.builder(
                  controller: _bugPageController,
                  itemCount: _activeBugList.length,
                  onPageChanged: (i) {
                    setState(() {
                      _currentBugPage = i;
                      final bug = _activeBugList[i];
                      final bugId = bug['bug_id'] as String? ?? '$i';
                      _selectedBugId = bugId;
                    });
                  },
                  itemBuilder: (context, index) {
                    final bug = _activeBugList[index];
                    final bugId = bug['bug_id'] as String? ?? '$index';
                    final isSelected = _selectedBugId == bugId;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedBugId = bugId),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 10, bottom: 3),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2196F3)
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF15181D),
                            width: isSelected ? 2 : 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF15181D),
                              offset: Offset(2, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFE9F0F7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF15181D),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.bug_report_rounded,
                                color: isSelected
                                    ? const Color(0xFF2196F3)
                                    : const Color(0xFF15181D),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (bug['bug_name'] as String? ?? 'BUG')
                                        .toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF15181D),
                                      fontFamily: 'Orbitron',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    bug['bug_id']?.toString() ?? 'bug',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_activeBugList.length, (i) {
                  final active = i == _currentBugPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: active ? 20 : 6,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFFFC52F)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(5),
                      border: active
                          ? Border.all(
                              color: const Color(0xFF15181D),
                              width: 0.8,
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _retroSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFB8BCC2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF15181D),
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF15181D),
            offset: Offset(4, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF15181D), size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF15181D),
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }

  Widget _buildSenderPanel() {
    return _retroSectionCard(
      icon: Icons.swap_horiz_rounded,
      title: 'SENDER',
      trailing: GestureDetector(
        onTap: () {
          _fetchSenderStats();
          _loadGlobalSenders();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC52F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF15181D),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                (_isLoadingSenders || _loadingSender)
                    ? Icons.sync_rounded
                    : Icons.refresh_rounded,
                color: const Color(0xFF15181D),
                size: 14,
              ),
              const SizedBox(width: 4),
              const Text(
                'REFRESH',
                style: TextStyle(
                  color: Color(0xFF15181D),
                  fontFamily: 'ShareTechMono',
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSender = 'private'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 72,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedSender == 'private'
                          ? const Color(0xFF2196F3)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF15181D),
                        width: 1.6,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF15181D),
                          offset: Offset(2, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: _selectedSender == 'private'
                              ? Colors.white
                              : const Color(0xFF15181D),
                          size: 24,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRIVATE',
                                style: TextStyle(
                                  color: _selectedSender == 'private'
                                      ? Colors.white
                                      : const Color(0xFF15181D),
                                  fontFamily: 'Orbitron',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$_privateSenderCount sender',
                                style: TextStyle(
                                  color: _selectedSender == 'private'
                                      ? Colors.white70
                                      : const Color(0xFF6B7280),
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_canAccessGlobalSenderRole) ...[
                const SizedBox(width: 10),
                Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_globalSenderEnabled) {
                      _showAlert(
                        '✕ Sender Global Ditutup',
                        'Sender global sedang ditutup oleh bot. Semua user tidak bisa menggunakannya.',
                      );
                      return;
                    }
                    if (!canAccessGlobalSender) {
                      _showAlert(
                        '✕ Kuota Habis',
                        'Kouta sender global anda hari ini telah habis',
                      );
                      return;
                    }
                    setState(() => _selectedSender = 'global');
                    _loadGlobalSenders();
                    if (widget.listBugGlobal.isNotEmpty) {
                      setState(() => _selectedBugId =
                          widget.listBugGlobal[0]['bug_id']?.toString() ??
                              _selectedBugId);
                      _bugPageController.jumpToPage(0);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 72,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedSender == 'global'
                          ? const Color(0xFFFFC52F)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF15181D),
                        width: 1.6,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF15181D),
                          offset: Offset(2, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              color: const Color(0xFF15181D),
                              size: 24,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GLOBAL',
                                    style: const TextStyle(
                                      color: Color(0xFF15181D),
                                      fontFamily: 'Orbitron',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$_globalSenderCount sender',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!canAccessGlobalSender)
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: Icon(
                              Icons.lock_rounded,
                              color: Color(0xFF6B7280),
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFF15181D),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF2196F3),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedSender == 'global'
                        ? '${_globalSenderRemaining.clamp(0, _globalSenderLimit)}/${_globalSenderLimit} global sender tersisa'
                        : _getGlobalStatusText(),
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontFamily: 'ShareTechMono',
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF15181D),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF15181D),
                offset: Offset(
                  3,
                  4 + (_pulseController.value * 1.5),
                ),
                blurRadius: 0,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendBug,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'SEND BUG',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    final parts = _responseMessage!.split('|');
    final type = parts[0];
    final msg = parts.length > 1 ? parts[1] : '';

    Color color = _primaryWhite;
    IconData icon = Icons.info_outline;
    String title = 'Info';
    
    switch (type) {
      case 'success':
        color = _primaryWhite;
        icon = Icons.check_circle_outline;
        title = 'Berhasil';
        break;
      case 'warning':
        color = _textGrey;
        icon = Icons.warning_rounded;
        title = 'Peringatan';
        break;
      default:
        color = _textGrey;
        icon = Icons.error_outline;
        title = 'Gagal';
    }

    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: _textWhite,
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(msg,
                            style: TextStyle(
                                color: _textGrey,
                                fontFamily: 'ShareTechMono',
                                fontSize: 9,
                                height: 1.4)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _responseMessage = null);
                      _resultCtrl.reset();
                    },
                    child: Icon(Icons.close_rounded, color: _textGrey, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF3F6FA),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(),
                Container(height: 1.4, color: const Color(0xFF15181D)),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            60,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 12),
                          _buildNomorAndBugPanel(),
                          const SizedBox(height: 12),
                          _buildSenderPanel(),
                          const SizedBox(height: 16),
                          _buildSendButton(),
                          _buildResponseMessage(),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
