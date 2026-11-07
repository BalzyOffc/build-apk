import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TiktokDownloaderPage extends StatefulWidget {
  const TiktokDownloaderPage({super.key});

  @override
  State<TiktokDownloaderPage> createState() => _TiktokDownloaderPageState();
}

class _TiktokDownloaderPageState extends State<TiktokDownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _videoData;
  String? _errorMessage;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // --- TEMA DEEP PURPLE MODERN ---
  final Color bgDark = const Color(0xFF0A0A2A);
  final Color deepPurple = const Color(0xFF6B3FA0);
  final Color lightPurple = const Color(0xFF9B6BFF);
  final Color primaryWhite = Colors.white;
  final Color textGrey = Colors.grey.shade400;
  final Color subtleGlass = Colors.white.withOpacity(0.03);
  final Color borderSubtle = Colors.white.withOpacity(0.08);

  @override
  void dispose() {
    _urlController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _downloadTiktok() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "TikTok URL cannot be empty.";
        _videoData = null;
      });
      return;
    }

    // Validate TikTok URL
    if (!url.contains('tiktok.com') && !url.contains('vt.tiktok.com')) {
      setState(() {
        _errorMessage = "Invalid TikTok URL.";
        _videoData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoData = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    final apiUrl = Uri.parse("https://api.siputzx.my.id/api/d/tiktok?url=$url");

    try {
      final response = await http.get(apiUrl).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          setState(() {
            _videoData = json['data'];
          });
          _initializeVideoPlayer();
        } else {
          setState(() {
            _errorMessage = json['message'] ?? "Failed to fetch TikTok data.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to connect to server (HTTP ${response.statusCode}).";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString().replaceAll('TimeoutException', 'Request timeout')}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeVideoPlayer() {
    if (_videoData?['urls'] != null && _videoData!['urls'].isNotEmpty) {
      final videoUrl = _videoData!['urls'][0];
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _chewieController = ChewieController(
                videoPlayerController: _videoController!,
                autoPlay: true,
                looping: false,
                showControls: true,
                allowFullScreen: true,
                materialProgressColors: ChewieProgressColors(
                  playedColor: lightPurple,
                  handleColor: lightPurple,
                  backgroundColor: textGrey.withOpacity(0.3),
                  bufferedColor: textGrey.withOpacity(0.2),
                ),
              );
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _errorMessage = "Failed to load video: $error";
            });
          }
        });
    }
  }

  Future<void> _shareVideo() async {
    if (_videoData?['urls'] == null || _videoData!['urls'].isEmpty) return;

    try {
      final videoUrl = _videoData!['urls'][0];
      final response = await http.get(Uri.parse(videoUrl)).timeout(const Duration(seconds: 30));
      final tempDir = await getTemporaryDirectory();
      final fileName = 'tiktok_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'TikTok video from: ${_videoData!['metadata']?['creator'] ?? 'Unknown'}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e', style: TextStyle(color: primaryWhite)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          'TikTok Downloader',
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
                        controller: _urlController,
                        style: TextStyle(color: primaryWhite, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'TikTok URL',
                          labelStyle: TextStyle(color: lightPurple, fontSize: 12),
                          hintText: 'https://vt.tiktok.com/...',
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
                          prefixIcon: Icon(Icons.link, color: lightPurple, size: 18),
                          suffixIcon: _isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: lightPurple,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [deepPurple, lightPurple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _downloadTiktok,
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
                                Icon(_isLoading ? Icons.hourglass_top : Icons.download, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _isLoading ? 'PROCESSING...' : 'DOWNLOAD',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: textGrey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Video Result
                if (_videoData != null)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: subtleGlass,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Column(
                          children: [
                            // Video Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: deepPurple.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.videocam, color: lightPurple, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Video Preview",
                                  style: TextStyle(
                                    color: primaryWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (_chewieController != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: Chewie(controller: _chewieController!),
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: subtleGlass,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderSubtle),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(color: lightPurple, strokeWidth: 2),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Loading video...',
                                        style: TextStyle(
                                          color: lightPurple,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Video Info
                            if (_videoData?['metadata'] != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: subtleGlass,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderSubtle),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _videoData!['metadata']['title'] ?? 'No Title',
                                      style: TextStyle(
                                        color: primaryWhite,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.person, color: lightPurple, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Creator: ${_videoData!['metadata']['creator'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: textGrey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Share Button
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [deepPurple, lightPurple],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ElevatedButton(
                                  onPressed: _shareVideo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.share, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'SHARE VIDEO',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                    ),
                  ),

                // Placeholder
                if (_videoData == null && !_isLoading && _errorMessage == null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: subtleGlass,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderSubtle),
                            ),
                            child: Icon(
                              Icons.video_library,
                              size: 48,
                              color: lightPurple,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'TikTok Downloader',
                            style: TextStyle(
                              color: primaryWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Paste TikTok URL to download videos without watermark',
                              style: TextStyle(
                                color: textGrey,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
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
}