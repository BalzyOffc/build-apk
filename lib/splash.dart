import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listBugGlobal;
  final List<Map<String, dynamic>> listBugGroup;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;
  final int? globalSenderLimit;
  final int? globalSenderRemaining;
  final int? globalSenderUsed;
  final int? globalSenderNextResetAt;
  final int? globalSenderResetHours;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    this.listBugGlobal = const [],
    this.listBugGroup = const [],
    required this.listDoos,
    required this.news,
    this.globalSenderLimit,
    this.globalSenderRemaining,
    this.globalSenderUsed,
    this.globalSenderNextResetAt,
    this.globalSenderResetHours,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController videoController;
  late AnimationController fadeController;
  late AnimationController progressController;
  bool fadeOutStarted = false;
  double loadingProgress = 0.0;
  bool hasNavigated = false;

  // --- BLACK/WHITE THEME ---
  static const Color accentRed = Color(0xFF0B0B0E);
  static const Color darkRed = Color(0xFFFFFFFF);
  static const Color softRed = Color(0xFFFFA0A0);
  static const Color bgDark = Colors.black;
  static const Color primaryWhite = Colors.white;

  LinearGradient get redGradient => const LinearGradient(
    colors: [accentRed, darkRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    
    progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
      setState(() {
        loadingProgress = progressController.value;
      });
    });
    
    videoController = VideoPlayerController.asset("assets/videos/splash.mp4")
      ..initialize().then((_) {
        setState(() {});
        videoController.setLooping(false);
        videoController.play();
        progressController.forward();

        fadeController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 1),
        );

        videoController.addListener(() {
          final position = videoController.value.position;
          final duration = videoController.value.duration;

          if (duration != null &&
              position >= duration - const Duration(seconds: 1) &&
              !fadeOutStarted) {
            fadeOutStarted = true;
            fadeController.forward();
          }

          if (position >= duration && !hasNavigated) {
            navigateToDashboard();
          }
        });
      }).catchError((error) {
        // If video fails to load, auto navigate after 3 seconds
        debugPrint("Video failed to load: $error");
        progressController.forward();
        Future.delayed(const Duration(seconds: 3), () {
          if (!hasNavigated && mounted) {
            fadeOutStarted = true;
            fadeController.forward();
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted && !hasNavigated) {
                navigateToDashboard();
              }
            });
          }
        });
      });
  }

  void navigateToDashboard() {
    if (hasNavigated) return;
    hasNavigated = true;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          username: widget.username,
          password: widget.password,
          role: widget.role,
          expiredDate: widget.expiredDate,
          sessionKey: widget.sessionKey,
          listBug: widget.listBug,
          listBugGlobal: widget.listBugGlobal,
          listBugGroup: widget.listBugGroup,
          listDoos: widget.listDoos,
          news: widget.news,
          globalSenderLimit: widget.globalSenderLimit,
          globalSenderRemaining: widget.globalSenderRemaining,
          globalSenderUsed: widget.globalSenderUsed,
          globalSenderNextResetAt: widget.globalSenderNextResetAt,
          globalSenderResetHours: widget.globalSenderResetHours,
        ),
      ),
    );
  }

  void skipToDashboard() {
    if (hasNavigated) return;
    
    // Stop video and animations
    videoController.pause();
    if (fadeController.isAnimating) {
      fadeController.stop();
    }
    if (progressController.isAnimating) {
      progressController.stop();
    }
    
    navigateToDashboard();
  }

  @override
  void dispose() {
    videoController.dispose();
    fadeController.dispose();
    progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: skipToDashboard,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: bgDark,
        body: Stack(
          children: [
            // --- VIDEO BACKGROUND FULL SCREEN ---
            if (videoController.value.isInitialized)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: videoController.value.size.width,
                    height: videoController.value.size.height,
                    child: VideoPlayer(videoController),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [
                      accentRed.withOpacity(0.15),
                      bgDark,
                      bgDark,
                    ],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentRed),
                  ),
                ),
              ),

            // --- GLASS OVERLAY FOR BETTER TEXT VISIBILITY ---
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        bgDark.withOpacity(0.4),
                        bgDark.withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // --- SKIP INDICATOR (Top Right) ---
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 12,
                      color: accentRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Lewati",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: primaryWhite.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- MAIN CONTENT (DI TENGAH LAYAR) ---
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo Container with Logo Image
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, double scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: redGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: accentRed.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: redGradient,
                                    ),
                                    child: const Icon(
                                      Icons.flash_on,
                                      color: primaryWhite,
                                      size: 60,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),

                    // Glass Text Container for Title
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [accentRed, darkRed, softRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              "LIGHT",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primaryWhite,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Glass Badge for Version
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Text(
                              "VERSION HIGH• Powered by amel",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: primaryWhite.withOpacity(0.8),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Modern Glass Loading Progress Bar
                    Container(
                      width: 250,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(
                              height: 4,
                              color: Colors.white.withOpacity(0.05),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 50),
                              width: 250 * loadingProgress,
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: redGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentRed.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Glass Percentage Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: accentRed,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "${(loadingProgress * 100).toInt()}% LOADING",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentRed,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- FADE OUT OVERLAY ---
            if (fadeOutStarted)
              FadeTransition(
                opacity: fadeController.drive(Tween(begin: 1.0, end: 0.0)),
                child: Container(color: bgDark),
              ),
          ],
        ),
      ),
    );
  }
}