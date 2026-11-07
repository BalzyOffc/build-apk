import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'anime.dart';
import 'thanks_to.dart';
import 'spotify_music.dart';
import 'public_chat_page.dart';
import 'hadis_page.dart';
import 'bug_group_page.dart';
import 'global_sender_research_page.dart';
import 'device_dashboard.dart';

const Color primaryWhiteGlobal = Color(0xFFFFFFFF);

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listBugGlobal;
  final List<Map<String, dynamic>> listBugGroup;
  final List<Map<String, dynamic>> listDoos;
  final String sessionKey;
  final List<dynamic> news;
  final int? globalSenderLimit;
  final int? globalSenderRemaining;
  final int? globalSenderUsed;
  final int? globalSenderNextResetAt;
  final int? globalSenderResetHours;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listBugGlobal,
    required this.listBugGroup,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
    this.globalSenderLimit,
    this.globalSenderRemaining,
    this.globalSenderUsed,
    this.globalSenderNextResetAt,
    this.globalSenderResetHours,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  WebSocketChannel? channel;

  // --- Push-to-talk voice command ---
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String _voiceText = '';
  String _voiceStatus = '';

  // --- State Variables ---
  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listBugGlobal;
  late List<Map<String, dynamic>> listBugGroup;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  // --- Profile & Menu Features ---
  String androidId = "unknown";
  File? profileImage;

  int bottomNavIndex = 0;
  Widget selectedPage = const SizedBox();

  int onlineUsers = 0;
  int activeConnections = 0;

  bool get isDeveloper {
    final normalized = role.toLowerCase();
    return normalized == 'developer' || normalized == 'pt-dev' || normalized == 'pt dev' || normalized == 'pt_dev';
  }

  bool get isOwner => role.toLowerCase().trim() == 'owner';

  // --- Banner Carousel State ---
  final PageController _bannerPageController = PageController(viewportFraction: 0.9);
  int _currentBannerIndex = 0;

  final PageController _bugNavPageController = PageController(viewportFraction: 0.88);
  int _currentBugNavPage = 0;

  final List<Map<String, dynamic>> _bugNavCards = [
    {
      "title": "LIGHT NUM",
      "subtitle": "BUG NUMBER",
      "features": ["DELAY", "FORCLOSE", "CRASS", "BLANK"],
      "tag": "GACOR",
      "footer": "AUTO C1",
      "actionType": "home",
      "actionLabel": "MASUK LIGHT BUG",
    },
    {
      "title": "LIGHT GB",
      "subtitle": "BUG GROUP",
      "features": ["LINK GROUP WA", "BUG CRASH", "SENDER PRIVATE", "BUG RUB"],
      "tag": "GROUP ONLY",
      "footer": "WA GROUP TARGET",
      "actionType": "group",
      "actionLabel": "KIRIM BUG GROUP",
    },
    {
      "title": "MANAGE BUG SENDER",
      "subtitle": "sender",
      "features": ["MANAGE", "SENDER", "STATUS", "CONTROL"],
      "tag": "NEW",
      "footer": "BUG SENDER",
      "actionType": "sender",
      "actionLabel": "OPEN MANAGER",
    },
  ];

  final List<Map<String, String>> _bannerItems = [
    {"img": "assets/images/gojo.jpg", "title": "LIGHT", "sub": "hi, haters!"},
  ];

  // --- Quick Menu State Variables ---
  final PageController _quickMenuController = PageController();
  int _currentQuickMenuIndex = 0;
  final String _font = 'Sans-Serif';

  // --- State Variables Untuk Jadwal Sholat ---
  String selectedCity = "JAKARTA";
  Timer? _countdownTimer;
  String _nextSholatName = "ASHAR";
  String _countdownString = "00:00:00";
  String _currentDigitalTime = "00:00:00";

  // Daftar Kota Indonesia
  final List<String> indonesiaCities = [
    "JAKARTA", "BANDUNG", "MEDAN", "MAKASSAR", "DENPASAR", 
    "PALEMBANG", "MATARAM", "AMBON", "PADANG", "PEKANBARU", 
    "KENDARI", "SURABAYA", "KUPANG", "SORONG"
  ];

  // Database Simulasi Waktu Sholat
  final Map<String, Map<String, String>> prayerTimesDatabase = {
    "JAKARTA": {"SUBUH": "04:32", "DZUHUR": "11:45", "ASHAR": "15:05", "MAGHRIB": "17:55", "ISYA": "19:08"},
    "SURABAYA": {"SUBUH": "04:12", "DZUHUR": "11:28", "ASHAR": "14:48", "MAGHRIB": "17:36", "ISYA": "18:50"},
    "BANDUNG": {"SUBUH": "04:34", "DZUHUR": "11:48", "ASHAR": "15:08", "MAGHRIB": "17:56", "ISYA": "19:10"},
    "MEDAN": {"SUBUH": "04:52", "DZUHUR": "12:18", "ASHAR": "15:42", "MAGHRIB": "18:27", "ISYA": "19:41"},
    "MAKASSAR": {"SUBUH": "04:41", "DZUHUR": "11:59", "ASHAR": "15:21", "MAGHRIB": "17:58", "ISYA": "19:12"},
    "DENPASAR": {"SUBUH": "04:55", "DZUHUR": "12:15", "ASHAR": "15:35", "MAGHRIB": "18:15", "ISYA": "19:28"},
    "PALEMBANG": {"SUBUH": "04:38", "DZUHUR": "12:05", "ASHAR": "15:28", "MAGHRIB": "18:12", "ISYA": "19:25"},
    "MATARAM": {"SUBUH": "04:52", "DZUHUR": "12:12", "ASHAR": "15:32", "MAGHRIB": "18:12", "ISYA": "19:25"},
    "AMBON": {"SUBUH": "04:50", "DZUHUR": "12:15", "ASHAR": "15:40", "MAGHRIB": "18:25", "ISYA": "19:35"},
    "PADANG": {"SUBUH": "04:58", "DZUHUR": "12:22", "ASHAR": "15:48", "MAGHRIB": "18:28", "ISYA": "19:40"},
    "PEKANBARU": {"SUBUH": "04:48", "DZUHUR": "12:15", "ASHAR": "15:42", "MAGHRIB": "18:18", "ISYA": "19:30"},
    "KENDARI": {"SUBUH": "04:38", "DZUHUR": "12:05", "ASHAR": "15:25", "MAGHRIB": "18:05", "ISYA": "19:18"},
    "KUPANG": {"SUBUH": "04:35", "DZUHUR": "11:58", "ASHAR": "15:22", "MAGHRIB": "17:58", "ISYA": "19:10"},
    "SORONG": {"SUBUH": "04:45", "DZUHUR": "12:12", "ASHAR": "15:38", "MAGHRIB": "18:18", "ISYA": "19:30"},
  };

  // --- MODERN THEME ---
  static const Color bgDark = Color(0xFFF7F7F7);
  static const Color accentRed = Color(0xFF2F2F2F);
  static const Color darkRed = Color(0xFF1F1F1F);
  static const Color softRed = Color(0xFF4A4A4A);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color softGrey = Color(0xFF4B5563);

  Color get glassPrimary => const Color(0xFFFFFFFF);
  Color get glassSecondary => const Color(0xFFF3F4F6);
  Color get glassBorder => const Color(0xFFCBD5E1);

  Color get themeTextColor => const Color(0xFF111827);
  Color get themeMutedTextColor => const Color(0xFF6B7280);

  LinearGradient get redGradient => const LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF6B7280)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get secondaryGradient => const LinearGradient(
    colors: [Color(0xFF374151), Color(0xFFE5E7EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Appearance preferences
  String _navStyle = 'floating';
  String _appTheme = 'LIGHT';
  String _uiStyle = 'modern';
  int _accentValue = 0xFF2563EB;

  Color get _accentColor => Color(_accentValue);

  Color get _appearanceBackground {
    switch (_appTheme) {
      case 'midnight':
        return const Color(0xFF0F172A);
      case 'purple':
        return const Color(0xFFF5F3FF);
      case 'emerald':
        return const Color(0xFFF0FDF4);
      case 'sunset':
        return const Color(0xFFFFF7ED);
      default:
        return const Color(0xFFF7F9FC);
    }
  }

  Future<void> _loadAppearanceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _navStyle = prefs.getString('LIGHT_nav_style') ?? 'floating';
      _appTheme = prefs.getString('LIGHT_app_theme') ?? 'LIGHT';
      _uiStyle = prefs.getString('LIGHT_ui_style') ?? 'modern';
      _accentValue = prefs.getInt('LIGHT_accent') ?? 0xFF2563EB;
    });
  }

  Future<void> _saveAppearanceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('LIGHT_nav_style', _navStyle);
    await prefs.setString('LIGHT_app_theme', _appTheme);
    await prefs.setString('LIGHT_ui_style', _uiStyle);
    await prefs.setInt('LIGHT_accent', _accentValue);
  }

  void _showAppearanceSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final dark = _appTheme == 'midnight';
            return Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF111827) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF475569)
                                : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.palette_rounded,
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'APPEARANCE',
                                style: TextStyle(
                                  color: dark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .6,
                                ),
                              ),
                              Text(
                                'Customize LIGHT instantly',
                                style: TextStyle(
                                  color: dark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF6B7280),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      _appearanceTitle('NAVIGATION STYLE', dark),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: _appearanceChoice(
                              title: 'Original',
                              icon: Icons.navigation_rounded,
                              selected: _navStyle == 'original',
                              dark: dark,
                              onTap: () {
                                modalSetState(() => _navStyle = 'original');
                                setState(() {});
                                _saveAppearanceSettings();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _appearanceChoice(
                              title: 'Floating',
                              icon: Icons.rounded_corner_rounded,
                              selected: _navStyle == 'floating',
                              dark: dark,
                              onTap: () {
                                modalSetState(() => _navStyle = 'floating');
                                setState(() {});
                                _saveAppearanceSettings();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _appearanceTitle('THEME', dark),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _themeChip('LIGHT', 'LIGHT', const Color(0xFF2563EB), dark, modalSetState),
                          _themeChip('midnight', 'Midnight', const Color(0xFF0F172A), dark, modalSetState),
                          _themeChip('purple', 'Purple', const Color(0xFF7C3AED), dark, modalSetState),
                          _themeChip('emerald', 'Emerald', const Color(0xFF059669), dark, modalSetState),
                          _themeChip('sunset', 'Sunset', const Color(0xFFF97316), dark, modalSetState),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _appearanceTitle('STYLE', dark),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(child: _styleChoice('Modern', 'modern', Icons.auto_awesome_rounded, dark, modalSetState)),
                          const SizedBox(width: 8),
                          Expanded(child: _styleChoice('Glass', 'glass', Icons.blur_on_rounded, dark, modalSetState)),
                          const SizedBox(width: 8),
                          Expanded(child: _styleChoice('Retro', 'retro', Icons.grid_3x3_rounded, dark, modalSetState)),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _appearanceTitle('ACCENT COLOR', dark),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        children: [
                          _accentChoice(0xFF2563EB, dark, modalSetState),
                          _accentChoice(0xFF7C3AED, dark, modalSetState),
                          _accentChoice(0xFF059669, dark, modalSetState),
                          _accentChoice(0xFFF59E0B, dark, modalSetState),
                          _accentChoice(0xFFEF4444, dark, modalSetState),
                          _accentChoice(0xFFEC4899, dark, modalSetState),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text(
                            'DONE',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _appearanceTitle(String title, bool dark) {
    return Text(
      title,
      style: TextStyle(
        color: dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _appearanceChoice({
    required String title,
    required IconData icon,
    required bool selected,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? _accentColor.withOpacity(.10)
              : (dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? _accentColor
                : (dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? _accentColor : (dark ? Colors.white70 : const Color(0xFF64748B))),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: dark ? Colors.white : const Color(0xFF1F2937),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeChip(
    String value,
    String label,
    Color color,
    bool dark,
    StateSetter modalSetState,
  ) {
    final selected = _appTheme == value;
    return GestureDetector(
      onTap: () {
        modalSetState(() => _appTheme = value);
        setState(() {});
        _saveAppearanceSettings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(.12) : (dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? color : (dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: dark ? Colors.white : const Color(0xFF374151),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styleChoice(
    String title,
    String value,
    IconData icon,
    bool dark,
    StateSetter modalSetState,
  ) {
    final selected = _uiStyle == value;
    return GestureDetector(
      onTap: () {
        modalSetState(() => _uiStyle = value);
        setState(() {});
        _saveAppearanceSettings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? _accentColor.withOpacity(.10) : (dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accentColor : (dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? _accentColor : (dark ? Colors.white70 : const Color(0xFF64748B)), size: 19),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: dark ? Colors.white : const Color(0xFF374151),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accentChoice(int value, bool dark, StateSetter modalSetState) {
    final selected = _accentValue == value;
    final color = Color(value);
    return GestureDetector(
      onTap: () {
        modalSetState(() => _accentValue = value);
        setState(() {});
        _saveAppearanceSettings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? (dark ? Colors.white : const Color(0xFF111827))
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
            : null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initVoiceCommand();
    _loadAppearanceSettings();

    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listBugGlobal = widget.listBugGlobal;
    listBugGroup = widget.listBugGroup;
    listDoos = widget.listDoos;
    newsList = widget.news;

    initAnimations();
    selectedPage = buildHomePage();

    initAndroidIdAndConnect();
    loadProfileImage();
    startPrayerCountdown();
  }

  void initAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  void startPrayerCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final now = DateTime.now();

      final String clockHours = now.hour.toString().padLeft(2, '0');
      final String clockMinutes = now.minute.toString().padLeft(2, '0');
      final String clockSeconds = now.second.toString().padLeft(2, '0');
      final String currentClockString = "$clockHours:$clockMinutes:$clockSeconds";

      final currentCityTimes = prayerTimesDatabase[selectedCity]!;
      
      DateTime? targetTime;
      String nextSholat = "SUBUH";

      List<String> order = ["SUBUH", "DZUHUR", "ASHAR", "MAGHRIB", "ISYA"];
      
      for (String sholat in order) {
        final timeParts = currentCityTimes[sholat]!.split(":");
        final sholatDateTime = DateTime(
          now.year, now.month, now.day,
          int.parse(timeParts[0]), int.parse(timeParts[1]),
        );

        if (sholatDateTime.isAfter(now)) {
          targetTime = sholatDateTime;
          nextSholat = sholat;
          break;
        }
      }

      if (targetTime == null) {
        final timeParts = currentCityTimes["SUBUH"]!.split(":");
        targetTime = DateTime(
          now.year, now.month, now.day + 1,
          int.parse(timeParts[0]), int.parse(timeParts[1]),
        );
        nextSholat = "SUBUH";
      }

      final difference = targetTime.difference(now);
      
      final hours = difference.inHours.toString().padLeft(2, '0');
      final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

      setState(() {
        _nextSholatName = nextSholat;
        _countdownString = "$hours:$minutes:$seconds";
        _currentDigitalTime = currentClockString;
      });
    });
  }

  IconData getPrayerIcon(String name) {
    switch (name) {
      case "SUBUH": return Icons.brightness_3_rounded;
      case "DZUHUR": return Icons.wb_sunny_rounded;
      case "ASHAR": return Icons.cloud_rounded;
      case "MAGHRIB": return Icons.dark_mode_rounded;
      default: return Icons.nightlight_round;
    }
  }

  bool isCurrentActivePrayer(String sholatName) {
    final now = DateTime.now();
    final times = prayerTimesDatabase[selectedCity]!;
    
    int getMinutes(String timeStr) {
      final parts = timeStr.split(":");
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final currentMinutes = now.hour * 60 + now.minute;
    final subuh = getMinutes(times["SUBUH"]!);
    final dzuhur = getMinutes(times["DZUHUR"]!);
    final ashar = getMinutes(times["ASHAR"]!);
    final maghrib = getMinutes(times["MAGHRIB"]!);
    final isya = getMinutes(times["ISYA"]!);

    if (sholatName == "SUBUH" && currentMinutes >= subuh && currentMinutes < dzuhur) return true;
    if (sholatName == "DZUHUR" && currentMinutes >= dzuhur && currentMinutes < ashar) return true;
    if (sholatName == "ASHAR" && currentMinutes >= ashar && currentMinutes < maghrib) return true;
    if (sholatName == "MAGHRIB" && currentMinutes >= maghrib && currentMinutes < isya) return true;
    if (sholatName == "ISYA" && (currentMinutes >= isya || currentMinutes < subuh)) return true;

    return false;
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (!mounted) return;
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        profileImage = File(imagePath);
      });
    }
  }

  Future<void> initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    connectToWebSocket();
  }

  void connectToWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://ws-queen.official.com'),
    );
    channel?.sink.add(
      jsonEncode({
        "type": "validate",
        "key": sessionKey,
        "androidId": androidId,
      }),
    );
    channel?.sink.add(jsonEncode({"type": "stats"}));

    channel?.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          if (data['reason'] == 'androidIdMismatch') {
            handleInvalidSession("Your account has logged on another device.");
          } else if (data['reason'] == 'keyInvalid') {
            handleInvalidSession("Key is not valid. Please login again.");
          }
        }
      }
      if (data['type'] == 'stats') {
        if (!mounted) return;
        setState(() {
          onlineUsers = data['onlineUsers'] ?? 0;
          activeConnections = data['activeConnections'] ?? 0;
        });
      }
    });
  }

  Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  void handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: glassPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: glassBorder, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Session Expired",
              style: TextStyle(
                color: accentRed,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: softGrey, fontSize: 14),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: redGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
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

  Future<void> _initVoiceCommand() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _isListening = status == 'listening';
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _voiceStatus = 'Voice error';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _speechReady = available;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speechReady = false;
        _voiceStatus = 'Voice unavailable';
      });
    }
  }

  Future<void> _toggleVoiceCommand() async {
    if (!_speechReady) {
      await _initVoiceCommand();
      if (!_speechReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice command belum tersedia. Pastikan izin mikrofon aktif.'),
            ),
          );
        }
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() {
      _voiceText = '';
      _voiceStatus = 'Listening...';
      _isListening = true;
    });

    await _speech.listen(
      localeId: 'id_ID',
      listenFor: const Duration(seconds: 7),
      pauseFor: const Duration(seconds: 2),
      onResult: (result) {
        if (!mounted) return;
        setState(() => _voiceText = result.recognizedWords);
        if (result.finalResult) {
          _handleVoiceCommand(result.recognizedWords);
        }
      },
    );
  }

  void _handleVoiceCommand(String raw) {
    final command = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (command.isEmpty) return;

    if (command.contains('bug menu') ||
        command.contains('menu bug') ||
        command.contains('bug center') ||
        command.contains('home bug') ||
        command.contains('buka bug')) {
      _speech.stop();
      setState(() {
        _isListening = false;
        _voiceStatus = 'Opening Bug Menu...';
      });
      onBottomNavTapped(1);
      return;
    }

    if (command.contains('buka home') ||
        command.contains('home page') ||
        command == 'home') {
      _speech.stop();
      setState(() {
        _isListening = false;
        _voiceStatus = 'Opening Home...';
      });
      onBottomNavTapped(0);
      return;
    }

    if (command.contains('buka tools') ||
        command.contains('menu tools') ||
        command == 'tools') {
      _speech.stop();
      setState(() {
        _isListening = false;
        _voiceStatus = 'Opening Tools...';
      });
      onBottomNavTapped(3);
      return;
    }

    if (command.contains('buka setting') ||
        command.contains('buka settings') ||
        command.contains('menu setting') ||
        command.contains('pengaturan') ||
        command == 'setting') {
      _speech.stop();
      setState(() {
        _isListening = false;
        _voiceStatus = 'Opening Settings...';
      });
      onBottomNavTapped(4);
      return;
    }

    if (command.contains('buka rat') ||
        command.contains('device control') ||
        command.contains('control device')) {
      _speech.stop();
      setState(() {
        _isListening = false;
        _voiceStatus = 'Opening RAT...';
      });
      onBottomNavTapped(2);
      return;
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _voiceStatus = 'Command not found';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perintah tidak dikenali: "$raw"')),
      );
    }
  }

  Widget _buildVoiceCommandButton() {
    return Positioned(
      right: 18,
      bottom: _navStyle == 'floating' ? 92 : 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isListening || _voiceText.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: 240),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _isListening
                    ? (_voiceText.isEmpty ? '🎤 Listening...' : '“$_voiceText”')
                    : (_voiceStatus.isEmpty ? 'Tap mic to speak' : _voiceStatus),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleVoiceCommand,
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _isListening ? 62 : 56,
                height: _isListening ? 62 : 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? const Color(0xFFEF4444) : _accentColor,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? const Color(0xFFEF4444) : _accentColor)
                          .withOpacity(.30),
                      blurRadius: _isListening ? 22 : 15,
                      spreadRadius: _isListening ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== FUNGSI onBottomNavTapped YANG SUDAH DIPERBAIKI ==========
  void onBottomNavTapped(int index) {
    if (index == 2) {
      setState(() => bottomNavIndex = 2);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeviceDashboardPage(),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            bottomNavIndex = 0;
            selectedPage = buildHomePage();
          });
        }
      });
      return;
    }

    setState(() {
      bottomNavIndex = index;

      switch (index) {
        case 0:
          selectedPage = buildHomePage();
          break;
        case 1:
          // ========== PERUBAHAN: Memanggil _showWhatsAppMenu() ==========
          _showWhatsAppMenu();
          break;
        case 3:
          selectedPage = ToolsPage(
            sessionKey: sessionKey,
            userRole: role,
            listDoos: listDoos,
          );
          break;
        case 4:
          _showAppearanceSettings();
          break;
      }
    });
  }

  void _showWhatsAppMenu() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FontAwesomeIcons.whatsapp, 
                      size: 36, 
                      color: Color(0xFF25D366)
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "WHATSAPP TOOLS",
                    style: TextStyle(
                      color: Colors.black87,
                      fontFamily: 'Orbitron',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Choose an action to perform",
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  _buildWhatsAppOption(
                    icon: Icons.bug_report,
                    color: Colors.redAccent,
                    title: "WhatsApp Crash",
                    subtitle: "Send payloads & crash codes",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        bottomNavIndex = 1;
                        selectedPage = HomePage(
                          username: username,
                          password: password,
                          listBug: listBug,
                          role: role,
                          expiredDate: expiredDate,
                          sessionKey: sessionKey,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildWhatsAppOption(
                    icon: Icons.devices,
                    color: Colors.greenAccent,
                    title: "Manage Sender",
                    subtitle: "Pair devices & manage sessions",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => BugSenderPage(
                            sessionKey: sessionKey, 
                            username: username, 
                            role: role
                          )
                        )
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)
                        ),
                      ),
                      child: const Text(
                        "Cancel", 
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWhatsAppOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 14),
          ],
        ),
      ),
    );
  }

  void _showFeatureSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0B1220),
        content: Text(
          'FITUR INI AKAN SEGERA HADIR',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void onSidebarTabSelected(int index) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        if (index == 1) {
          selectedPage = SellerPage(keyToken: sessionKey);
        } else if (index == 2) {
          selectedPage = OwnerPage(
            sessionKey: sessionKey,
            username: username,
            currentUserRole: role,
          );
        } else if (index == 3) {
          selectedPage = OwnerPage(
            sessionKey: sessionKey,
            username: username,
            currentUserRole: role,
          );
        }
      });
    });
  }

  List<Map<String, dynamic>> get quickActions {
    return [
      {
        "icon": Icons.bug_report_rounded,
        "label": "Manage Bug",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BugSenderPage(
                sessionKey: sessionKey,
                username: username,
                role: role,
              ),
            ),
          );
        },
      },
      {
        "icon": FontAwesomeIcons.telegram,
        "label": "Join Channel",
        "onTap": () => openUrl("https://t.me/haiakuamel123"),
      },
      {
        "icon": Icons.access_time_filled_rounded,
        "label": "Jadwal Sholat",
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Menampilkan panel informasi ibadah di Dashboard!")),
          );
        },
      },
      {
        "icon": Icons.menu_book_rounded,
        "label": "Hadis Shahih",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HadisPage()),
          );
        },
      },
      {
        "icon": Icons.movie_rounded,
        "label": "Anime List",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeAnimePage()),
          );
        },
      },
      {
        "icon": Icons.favorite_rounded,
        "label": "Thanks To",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ThanksToPage()),
          );
        },
      },
      {
        "icon": Icons.music_note_rounded,
        "label": "Spotify",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpotifyMusicPage(),
            ),
          );
        },
      },
    ];
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fitur ini akan segera hadir!")),
    );
  }

  Widget _buildWelcomeMessage() {
    final hour = DateTime.now().hour;
    String waktu;

    if (hour >= 5 && hour < 11) {
      waktu = 'PAGI';
    } else if (hour < 15) {
      waktu = 'SIANG';
    } else if (hour < 18) {
      waktu = 'SORE';
    } else {
      waktu = 'MALAM';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HALLO ${username.toUpperCase()}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                blurRadius: 12,
                color: Colors.black.withOpacity(0.25),
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SELAMAT $waktu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontFamily: 'Orbitron',
            letterSpacing: 1.6,
            shadows: [
              Shadow(
                blurRadius: 16,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Selamat datang di LIGHT.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.96),
            fontSize: 13.2,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 0.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kami menghadirkan evolusi besar dengan sistem Global Sender yang lebih optimal, perbaikan bug secara menyeluruh, serta tampilan UI/UX yang lebih elegan dan modern.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 11.4,
            height: 1.6,
            letterSpacing: 0.18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Semoga hari mu menyenangkan bersama LIGHT.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _bubble(double radius, Color color) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // --- WIDGET JADWAL SHOLAT ---
  Widget _buildJadwalSholatWidget() {
    final currentTimes = prayerTimesDatabase[selectedCity]!;
    final List<String> prayers = ["SUBUH", "DZUHUR", "ASHAR", "MAGHRIB", "ISYA"];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: glassBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: glassBorder),
            ),
            child: Text(
              _currentDigitalTime,
              style: TextStyle(
                color: themeTextColor,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mosque_rounded, color: Color(0xFF4B5563), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    "JADWAL SHOLAT",
                    style: TextStyle(
                      color: themeTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: _font,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: glassSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF4B5563), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "MUNDUR : ",
                      style: TextStyle(color: themeMutedTextColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _countdownString,
                      style: TextStyle(color: themeTextColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: prayers.length,
              itemBuilder: (context, index) {
                final name = prayers[index];
                final time = currentTimes[name]!;
                final bool isActive = isCurrentActivePrayer(name);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 82,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFDE68A).withOpacity(0.35) : glassSecondary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive ? const Color(0xFFCA8A04) : glassBorder,
                      width: isActive ? 1.8 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        getPrayerIcon(name),
                        color: isActive ? const Color(0xFFB45309) : themeMutedTextColor,
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: isActive ? const Color(0xFFB45309) : themeMutedTextColor,
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: themeTextColor,
                          fontSize: 15,
                          fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: glassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCity,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 18),
                isExpanded: true,
                style: TextStyle(color: themeTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                items: indonesiaCities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF6B7280), size: 15),
                        const SizedBox(width: 8),
                        Text(city, style: TextStyle(fontFamily: _font, letterSpacing: 0.5, color: themeTextColor)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedCity = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenuSlider() {
    final links = [
      {
        'title': 'JOIN GB ALL BUYER',
        'url': 'https://t.me/xencodeapps',
        'icon': FontAwesomeIcons.telegram,
      },
      {
        'title': 'JOIN CHANNEL WHATSAPP',
        'url': 'https://whatsapp.com/channel/0029Vb8PkQY9sBI2nMz0aL41',
        'icon': FontAwesomeIcons.whatsapp,
      },
      {
        'title': 'CONTACT DEVELOPER',
        'url': 'https://t.me/ownernya_sangat_ramah',
        'icon': FontAwesomeIcons.telegram,
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 135,
          child: PageView.builder(
            controller: _quickMenuController,
            itemCount: links.length,
            onPageChanged: (i) => setState(() => _currentQuickMenuIndex = i),
            itemBuilder: (context, index) {
              final item = links[index];
              final title = item['title'] as String;
              final url = item['url'] as String;
              final icon = item['icon'] as IconData;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: GestureDetector(
                  onTap: () => openUrl(url),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: FaIcon(icon, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                url,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontFamily: 'ShareTechMono',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(links.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentQuickMenuIndex == i ? 20 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _currentQuickMenuIndex == i ? Colors.black : Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildConnectMantaTeamCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: glassPrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glassBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(Icons.hub_outlined, color: Color(0xFF4B5563), size: 20),
              const SizedBox(width: 10),
              Text(
                "CONNECT WITH LIGHT TEAM",
                style: TextStyle(
                  color: themeTextColor,
                  fontFamily: _font,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialCircleItem(
                icon: FontAwesomeIcons.telegram,
                label: "Telegram",
                iconColor: const Color(0xFF374151),
                onTap: () => openUrl("https://t.me/ownernya_sangat_ramah"),
              ),
              _buildSocialCircleItem(
                icon: FontAwesomeIcons.youtube,
                label: "YouTube",
                iconColor: const Color(0xFFDC2626),
                onTap: () => openUrl("https://youtube.com/@gdq"),
              ),
              _buildSocialCircleItem(
                icon: FontAwesomeIcons.tiktok,
                label: "TikTok",
                iconColor: const Color(0xFF111827),
                onTap: () => openUrl("https://tiktok.com/@amellovelyy07"),
              ),
              _buildSocialCircleItem(
                icon: Icons.favorite_rounded,
                label: "Thanks To",
                iconColor: const Color(0xFFEC4899),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ThanksToPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: const Color(0xFFCBD5E1), thickness: 1),
          const SizedBox(height: 8),
          Text(
            "Selalu nantikan project terbaru dari Team LIGHT",
            style: TextStyle(
              color: themeMutedTextColor,
              fontSize: 11.5,
              fontFamily: _font,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildBugCarouselPage() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/walpaper.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.12),
              Colors.black.withOpacity(0.72),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "LIGHT",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Geser untuk melihat kartu bug terbaru.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 360,
                  child: PageView.builder(
                    controller: _bugNavPageController,
                    itemCount: _bugNavCards.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBugNavPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final card = _bugNavCards[index];
                      return AnimatedBuilder(
                        animation: _bugNavPageController,
                        builder: (context, child) {
                          double scale = 1.0;
                          if (_bugNavPageController.position.haveDimensions) {
                            final diff = (_bugNavPageController.page! - index).abs();
                            scale = (1 - diff * 0.08).clamp(0.92, 1.0);
                          }
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14, left: 14),
                          child: GestureDetector(
                            onTap: () {
                              if (card['actionType'] == 'home') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(
                                      username: username,
                                      password: password,
                                      sessionKey: sessionKey,
                                      listBug: listBug,
                                      listBugGlobal: listBugGlobal,
                                      role: role,
                                      expiredDate: expiredDate,
                                      globalSenderLimit: widget.globalSenderLimit,
                                      globalSenderRemaining: widget.globalSenderRemaining,
                                      globalSenderUsed: widget.globalSenderUsed,
                                      globalSenderNextResetAt: widget.globalSenderNextResetAt,
                                      globalSenderResetHours: widget.globalSenderResetHours,
                                    ),
                                  ),
                                );
                              } else if (card['actionType'] == 'group') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BugGroupPage(
                                      username: username,
                                      password: password,
                                      sessionKey: sessionKey,
                                      role: role,
                                      expiredDate: expiredDate,
                                      listBugGroup: widget.listBugGroup,
                                    ),
                                  ),
                                );
                              } else if (card['actionType'] == 'sender') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BugSenderPage(
                                      sessionKey: sessionKey,
                                      username: username,
                                      role: role,
                                    ),
                                  ),
                                );
                              } else {
                                _showFeatureSoon();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: glassPrimary,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: glassBorder, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 24,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: -40,
                                      left: -30,
                                      child: Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -30,
                                      bottom: -40,
                                      child: Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(22.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                card['title'],
                                                style: TextStyle(
                                                  color: themeTextColor,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: glassSecondary,
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(color: glassBorder),
                                                ),
                                                child: Text(
                                                  card['subtitle'],
                                                  style: TextStyle(
                                                    color: themeMutedTextColor,
                                                    fontSize: 11,
                                                    letterSpacing: 0.8,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          Text(
                                            "FITUR:",
                                            style: TextStyle(
                                              color: themeTextColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...List<Widget>.from(card['features'].map((feature) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Color(0xFF4B5563),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      feature,
                                                      style: TextStyle(
                                                        color: themeMutedTextColor,
                                                        fontSize: 13,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          })),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: glassSecondary,
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: glassBorder),
                                                ),
                                                child: Text(
                                                  card['tag'],
                                                  style: TextStyle(
                                                    color: themeTextColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  card['footer'],
                                                  style: TextStyle(
                                                    color: themeMutedTextColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 18),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                              decoration: BoxDecoration(
                                                gradient: redGradient,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                card['actionLabel'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _buildBugCarouselIndicator(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBugCarouselIndicator() {
    return AnimatedBuilder(
      animation: _bugNavPageController,
      builder: (context, child) {
        final currentPage = _bugNavPageController.hasClients && _bugNavPageController.position.haveDimensions
            ? _bugNavPageController.page ?? _currentBugNavPage.toDouble()
            : _currentBugNavPage.toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_bugNavCards.length, ( index) {
            final distance = (currentPage - index).abs();
            final width = distance < 0.5 ? 24.0 : 8.0;
            final opacity = (1.0 - (distance.clamp(0.0, 1.0))).clamp(0.25, 1.0);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: width,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSocialCircleItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glassSecondary,
              border: Border.all(
                color: iconColor.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontFamily: _font,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ========================= MODERN HOME UI =========================
  Widget _modernCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    double radius = 22,
    Color? color,
    Color borderColor = const Color(0xFFD8E0E8),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, {IconData icon = Icons.auto_awesome_rounded}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 27,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 17, color: const Color(0xFF111827)),
                  const SizedBox(width: 7),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modernStat({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: _modernCard(
        radius: 18,
        padding: const EdgeInsets.all(13),
        borderColor: const Color(0xFFDCE3EA),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withOpacity(.11),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF20242A), width: 1.15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.10),
                blurRadius: 0,
                offset: const Offset(4, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF718096), fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10.8, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF758DA2), fontSize: 8.8),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Color(0xFF6D8498), fontSize: 8.5)),
        ],
      ),
    );
  }

  Widget _buildModernProfileHero() {
    final hour = DateTime.now().hour;
    final greeting = hour >= 5 && hour < 11
        ? "SELAMAT PAGI"
        : hour < 15
            ? "SELAMAT SIANG"
            : hour < 18
                ? "SELAMAT SORE"
                : "SELAMAT MALAM";

    final shortDevice = androidId == "unknown"
        ? "DEVICE READY"
        : androidId.length > 10
            ? "${androidId.substring(0, 10)}..."
            : androidId;

    return Container(
      height: 270,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF20242A), width: 1.35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.14),
            blurRadius: 0,
            offset: const Offset(5, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/gojo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/karges.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(.72),
                    Colors.black.withOpacity(.18),
                    Colors.black.withOpacity(.64),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(.18),
                          border: Border.all(color: Colors.white.withOpacity(.72), width: 1.5),
                        ),
                        child: profileImage != null
                            ? ClipOval(child: Image.file(profileImage!, fit: BoxFit.cover))
                            : const Icon(Icons.person_rounded, color: Colors.white, size: 29),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "WELCOME BACK",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    username,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.verified_rounded, color: Colors.white, size: 15),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC928),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0xFF20242A), width: 1),
                        ),
                        child: const Text(
                          "ONLINE",
                          style: TextStyle(
                            color: Color(0xFF20242A),
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Selamat datang kembali di LIGHT.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC928),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: const Color(0xFF20242A), width: .8),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF20242A),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Expired: $expiredDate",
                          style: const TextStyle(color: Colors.white70, fontSize: 8.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _heroMiniInfo(Icons.smartphone_rounded, "DEVICE", shortDevice),
                      const SizedBox(width: 7),
                      _heroMiniInfo(Icons.bolt_rounded, "SESSION", "ACTIVE"),
                      const SizedBox(width: 7),
                      _heroMiniInfo(Icons.devices_rounded, "DEVICES", activeConnections.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMiniInfo(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.92),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF20242A), width: .9),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF20242A)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 6.5, fontWeight: FontWeight.w800, letterSpacing: .6)),
                  const SizedBox(height: 2),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF20242A), fontSize: 7.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStatusCard() {
    final limit = widget.globalSenderLimit ?? 0;
    final remaining = widget.globalSenderRemaining ?? 0;
    final used = widget.globalSenderUsed ?? 0;
    final progress = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);

    return _modernCard(
      radius: 21,
      borderColor: const Color(0x3322D3EE),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x1422D3EE),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.public_rounded, color: Color(0xFF67E8F9), size: 22),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("GLOBAL SENDER", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text("Resource monitor", style: TextStyle(color: Color(0xFF7891A6), fontSize: 9)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x1422C55E),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text("ACTIVE", style: TextStyle(color: Color(0xFF86EFAC), fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: Colors.white.withOpacity(.06),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF22D3EE)),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(child: Text("USED  $used", style: const TextStyle(color: Color(0xFF8FA7BC), fontSize: 8.5))),
              Text(
                limit > 0 ? "$remaining REMAINING / $limit" : "DATA NOT AVAILABLE",
                style: const TextStyle(color: Color(0xFF67E8F9), fontSize: 8.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard() {
    String title = "SYSTEM UPDATE";
    String body = "Dashboard LIGHT siap digunakan. Pastikan session kamu tetap aktif.";

    if (newsList.isNotEmpty) {
      final item = newsList.first;
      if (item is Map) {
        title = (item["title"] ?? item["judul"] ?? title).toString();
        body = (item["description"] ?? item["message"] ?? item["text"] ?? body).toString();
      } else {
        body = item.toString();
      }
    }

    return _modernCard(
      radius: 20,
      borderColor: const Color(0x334F46E5),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF8CA2B5), fontSize: 9, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHomePage() {
    final bugCount = listBug.length + listBugGlobal.length + listBugGroup.length;
    final globalRemaining = widget.globalSenderRemaining ?? 0;
    final globalLimit = widget.globalSenderLimit ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernProfileHero(),
          const SizedBox(height: 15),

          _modernCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFDC2626), size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ACCESS ROLE",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            "Selamat datang kembali di LIGHT Project. Nikmati navigasi baru yang lebih mulus dan performa yang ditingkatkan.",
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 11.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicChatPage(
                    username: widget.username,
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFBFEAF1),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFF20242A), width: 1.15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.10), blurRadius: 0, offset: const Offset(4, 5)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF20242A), width: 1),
                    ),
                    child: const Icon(Icons.groups_rounded, color: Color(0xFF20242A), size: 21),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("GLOBAL CHAT", style: TextStyle(color: Color(0xFF20242A), fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                        SizedBox(height: 4),
                        Text("Gabung obrolan dan update terbaru", style: TextStyle(color: Color(0xFF475569), fontSize: 8.5)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFF20242A), size: 23),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          _sectionHeader(
            "LATEST UPDATE",
            "Informasi terbaru dari sistem",
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _bannerPageController,
              itemCount: _bannerItems.length,
              onPageChanged: (i) => setState(() => _currentBannerIndex = i),
              itemBuilder: (_, index) {
                final banner = _bannerItems[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD4DCE5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            banner["img"]!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE2E8F0)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(.10),
                                  Colors.black.withOpacity(.72),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 17,
                            right: 15,
                            bottom: 16,
                            child: Text(
                              newsList.isNotEmpty
                                  ? (newsList.first is Map
                                      ? ((newsList.first["title"] ?? "SYSTEM UPDATE").toString()).toUpperCase()
                                      : "SYSTEM UPDATE")
                                  : "PEMBAHARUAN SENDER GLOBAL",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Orbitron',
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_bannerItems.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _bannerItems.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentBannerIndex ? 18 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == _currentBannerIndex ? const Color(0xFF111827) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 22),

          _sectionHeader(
            "QUICK ACTIONS",
            "Akses cepat fitur favorit kamu",
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _quickTile(
                icon: Icons.bug_report_rounded,
                title: "BUG MANAGER",
                subtitle: "Kelola bug",
                accent: const Color(0xFFF59E0B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BugSenderPage(
                      sessionKey: sessionKey,
                      username: username,
                      role: role,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              _quickTile(
                icon: Icons.public_rounded,
                title: "BUG MENU",
                subtitle: "BUG MENU",
                accent: const Color(0xFF0F766E),
                onTap: () => setState(() {
                  bottomNavIndex = 1;
                  selectedPage = buildBugCarouselPage();
                }),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              _quickTile(
                icon: Icons.menu_book_rounded,
                title: "HADIS",
                subtitle: "Daily reading",
                accent: const Color(0xFF16A34A),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HadisPage())),
              ),
              const SizedBox(width: 9),
              _quickTile(
                icon: Icons.movie_filter_rounded,
                title: "ANIME",
                subtitle: "Anime list",
                accent: const Color(0xFFEA580C),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeAnimePage())),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              _modernStat(
                icon: Icons.lock_rounded,
                value: listBug.length.toString(),
                label: "PRIVATE BUG",
                accent: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 9),
              _modernStat(
                icon: Icons.public_rounded,
                value: globalLimit > 0 ? globalRemaining.toString() : listBugGlobal.length.toString(),
                label: "GLOBAL POOL",
                accent: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              _modernStat(
                icon: Icons.bug_report_rounded,
                value: bugCount.toString(),
                label: "BUG TERSEDIA",
                accent: const Color(0xFF9333EA),
              ),
              const SizedBox(width: 9),
              _modernStat(
                icon: Icons.people_alt_rounded,
                value: onlineUsers.toString(),
                label: "ONLINE USER",
                accent: const Color(0xFF0891B2),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (isOwner) _buildGlobalStatusCard(),
          const SizedBox(height: 20),

          _sectionHeader(
            "BUG COLLECTION",
            "${listBug.length} private • ${listBugGlobal.length} global • ${listBugGroup.length} group",
            icon: Icons.bug_report_rounded,
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 188,
            child: PageView.builder(
              controller: _bugNavPageController,
              itemCount: _bugNavCards.length,
              onPageChanged: (index) => setState(() => _currentBugNavPage = index),
              itemBuilder: (context, index) {
                final item = _bugNavCards[index];
                final accent = [
                  const Color(0xFF2563EB),
                  const Color(0xFF9333EA),
                  const Color(0xFF0891B2),
                ][index % 3];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _modernCard(
                    radius: 18,
                    borderColor: const Color(0xFFDCE3EA),
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item["tag"].toString(),
                                style: TextStyle(color: accent, fontSize: 7.5, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_forward_rounded, color: accent, size: 17),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Text(
                          item["title"].toString(),
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item["subtitle"].toString(),
                          style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                        const SizedBox(height: 11),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (item["features"] as List).map<Widget>((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                feature.toString(),
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Spacer(),
                        Text(
                          item["footer"].toString(),
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bugNavCards.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _currentBugNavPage ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: index == _currentBugNavPage ? const Color(0xFF111827) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionHeader(
            "JADWAL SHOLAT",
            "Jadwal dan countdown sholat",
            icon: Icons.mosque_rounded,
          ),
          const SizedBox(height: 10),
          _buildJadwalSholatWidget(),
          const SizedBox(height: 20),

          _sectionHeader(
            "AKTIVITAS TERKINI",
            "Status sistem dan koneksi kamu",
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 10),
          _modernCard(
            radius: 18,
            child: Column(
              children: [
                _activityItem(
                  icon: Icons.login_rounded,
                  title: "Session aktif",
                  subtitle: "Akun $username sedang online",
                  time: _currentDigitalTime.substring(0, 5),
                  accent: const Color(0xFF16A34A),
                ),
                _activityItem(
                  icon: Icons.public_rounded,
                  title: "Global pool ready",
                  subtitle: globalLimit > 0 ? "$globalRemaining sender tersisa" : "Data pool tersedia",
                  time: "LIVE",
                  accent: const Color(0xFF0891B2),
                ),
                _activityItem(
                  icon: Icons.bug_report_rounded,
                  title: "Bug collection loaded",
                  subtitle: "$bugCount item terdeteksi dari server",
                  time: "SYNC",
                  accent: const Color(0xFF7C3AED),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _sectionHeader(
            "COMMUNITY",
            "Gabung dan dapatkan update terbaru",
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: 10),
          _buildConnectMantaTeamCard(),
          const SizedBox(height: 12),

          _modernCard(
            radius: 18,
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 23),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "LIGHT PREMIUM",
                        style: TextStyle(color: Color(0xFF111827), fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Lebih banyak akses • lebih nyaman • lebih cepat",
                        style: TextStyle(color: Color(0xFF718096), fontSize: 8.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Center(
            child: Text(
              "LIGHT • DESIGNED BY AMEL",
              style: TextStyle(
                color: Colors.black.withOpacity(.35),
                fontSize: 7.5,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildModernQuickAction({
    required IconData icon,
    required String label,
    required Color color, 
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 125, 
        height: 85,  
        decoration: BoxDecoration(
          color: glassPrimary,
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(
            color: color.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color, 
              size: 26,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCustomDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(gradient: redGradient),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryWhite, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profileImage != null
                            ? Image.file(profileImage!, fit: BoxFit.cover)
                            : Container(
                                decoration: BoxDecoration(gradient: secondaryGradient),
                                child: Icon(
                                  FontAwesomeIcons.userAstronaut,
                                  size: 45,
                                  color: primaryWhite.withOpacity(0.9),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      username,
                      style: const TextStyle(
                        color: primaryWhiteGlobal,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryWhite.withOpacity(0.2)),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: primaryWhiteGlobal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  if (role.toLowerCase() == "owner")
                    buildGlassMenuItem(
                      icon: Icons.workspace_premium_rounded,
                      label: "Owner Page",
                      onTap: () => onSidebarTabSelected(3),
                    ),
                  buildGlassMenuItem(
                    icon: Icons.history_rounded,
                    label: "Riwayat Aktivitas",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RiwayatPage(sessionKey: sessionKey, role: role),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFFCBD5E1), height: 32, thickness: 0.5),
                  buildGlassMenuItem(
                    icon: Icons.logout_rounded,
                    label: "Log Out",
                    isLogout: true,
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGlassMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isLogout ? Colors.red.withOpacity(0.1) : glassSecondary,
        borderRadius: BorderRadius.circular(16),
        border: isLogout
            ? null
            : Border.all(color: glassBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout
                ? Colors.red.withOpacity(0.15)
                : accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.redAccent : accentRed,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout ? Colors.redAccent : primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        trailing: isLogout
            ? null
            : const Icon(Icons.chevron_right_rounded, color: softGrey, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCustomBottomNavigationBar() {
    final isFloating = _navStyle == 'floating';
    final dark = _appTheme == 'midnight';

    final nav = Container(
      margin: isFloating
          ? const EdgeInsets.fromLTRB(22, 0, 22, 14)
          : EdgeInsets.zero,
      height: isFloating ? 72 : 68,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(isFloating ? 36 : 0),
        border: Border.all(
          color: dark ? const Color(0xFF334155) : const Color(0xFFD7DEE7),
        ),
        boxShadow: isFloating
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(.10),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ]
            : const [],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Expanded(child: _bottomNavItem(0, Icons.home_rounded, "Home")),
              Expanded(child: _bottomNavItem(1, Icons.bug_report_rounded, "Bug")),
              const SizedBox(width: 66),
              Expanded(child: _bottomNavItem(3, Icons.build_rounded, "Tools")),
              Expanded(child: _bottomNavItem(4, Icons.settings_rounded, "setting")),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: isFloating ? -28 : -4,
            child: Center(
              child: GestureDetector(
                onTap: () => onBottomNavTapped(2),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutBack,
                      width: bottomNavIndex == 2 ? 62 : 58,
                      height: bottomNavIndex == 2 ? 62 : 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentColor,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withOpacity(.28),
                            blurRadius: bottomNavIndex == 2 ? 18 : 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.devices_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "RAT",
                      style: TextStyle(
                        color: dark ? Colors.white70 : const Color(0xFF374151),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      top: false,
      child: nav,
    );
  }

  Widget _bottomNavItem(int index, IconData icon, String label) {
    final selected = bottomNavIndex == index;

    return GestureDetector(
      onTap: () => onBottomNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 72,
        child: Center(
          child: AnimatedSlide(
            offset: selected ? const Offset(0, -0.18) : Offset.zero,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: selected ? 1.0 : 0.92,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: selected ? 52 : 42,
                    height: selected ? 52 : 42,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            )
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: _accentColor.withOpacity(.16),
                                blurRadius: 18,
                                spreadRadius: 2,
                                offset: const Offset(0, 7),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : const [],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          icon,
                          key: ValueKey('${index}_$selected'),
                          size: selected ? 23 : 20,
                          color: selected
                              ? _accentColor
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? _accentColor
                          : const Color(0xFF6B7280),
                      fontSize: 8.5,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color(0xFFE3F2FD),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1,
            color: glassBorder,
          ),
        ),
        title: const Text(
          'LIGHT',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // ========== TOMBOL WHATSAPP ==========
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: glassBorder),
            ),
            child: IconButton(
              icon: const Icon(
                FontAwesomeIcons.whatsapp,
                color: Color(0xFF25D366),
                size: 20,
              ),
              tooltip: 'WhatsApp Tools',
              onPressed: _showWhatsAppMenu,
            ),
          ),
          // ========== TOMBOL PROFILE ==========
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: glassSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: glassBorder),
            ),
            child: IconButton(
              icon: const Icon(
                FontAwesomeIcons.circleUser,
                color: accentRed,
                size: 20,
              ),
              tooltip: 'My Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      username: username,
                      password: password,
                      role: role,
                      expiredDate: expiredDate,
                      sessionKey: sessionKey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: buildCustomDrawer(),
      
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE3F2FD),
            ),
          ),

          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: selectedPage,
              ),
            ),
          ),
          _buildVoiceCommandButton(),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    channel?.sink.close(status.goingAway);
    animationController.dispose();
    _bannerPageController.dispose();
    _bugNavPageController.dispose();
    super.dispose();
  }
}

class PrayerScheduleWidget extends StatelessWidget {
  const PrayerScheduleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage('https://files.catbox.moe/kcqodz.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black45,
                BlendMode.darken,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            children: [
              const Text(
                'Jadwal Sholat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Main Bug Boleh, Asal Jangan Lupa Agama — Minimal Sholat Bagi Muslim.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.25,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPrayerColumn('04:37', Icons.wb_twilight_rounded, 'Subuh'),
                  _buildPrayerColumn('11:56', Icons.wb_sunny_rounded, 'Dzuhur'),
                  _buildPrayerColumn('15:17', Icons.cloud_rounded, 'Ashar'),
                  _buildPrayerColumn('17:54', Icons.nightlight_round, 'Maghrib'),
                  _buildPrayerColumn('19:08', Icons.dark_mode_rounded, 'Isya'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Kita terlalu sibuk mengejar hasil, sampai lupa mendekati Dia yang memegang semua keputusan akhir. Yuk, utamakan sholat.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildPrayerColumn(String time, IconData icon, String name) {
    return Column(
      children: [
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          icon,
          color: Colors.orangeAccent,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class HoneycombPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.14)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double radius = 12.0; 
    final double hexWidth = radius * math.sqrt(3);
    final double hexHeight = radius * 2;

    for (double y = -radius; y < size.height + radius; y += hexHeight * 0.75) {
      final bool isEven = ((y + radius) / (hexHeight * 0.75)).round() % 2 == 0;
      final double startX = isEven ? 0 : hexWidth / 2;

      for (double x = startX - hexWidth; x < size.width + hexWidth; x += hexWidth) {
        _drawHexagon(canvas, Offset(x, y), radius, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final Path path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (i * 60) * math.pi / 180;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}