import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class InstagramDownloaderPage extends StatefulWidget {
  const InstagramDownloaderPage({super.key});

  @override
  State<InstagramDownloaderPage> createState() => _InstagramDownloaderPageState();
}

class _InstagramDownloaderPageState extends State<InstagramDownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  List<dynamic>? _mediaData;
  String? _errorMessage;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _currentVideoUrl;

  // --- TEMA MODERN (Fix: Static Const agar tidak error 'this') ---
  static const Color bgDark = Color(0xFF0A0A2A);
  static const Color deepPurple = Color(0xFF6B3FA0);
  static const Color lightPurple = Color(0xFF9B6BFF);
  static const Color primaryWhite = Colors.white;

  @override
  void dispose() {
    _urlController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _downloadInstagram() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "URL Instagram tidak boleh kosong";
        _mediaData = null;
      });
      return;
    }

    if (!url.contains('instagram.com')) {
      setState(() {
        _errorMessage = "URL tidak valid. Harus dari Instagram.com";
        _mediaData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mediaData = null;
      _currentVideoUrl = null;
      _videoController?.dispose();
      _chewieController?.dispose();
    });

    final encodedUrl = Uri.encodeComponent(url);
    final apiUrl = Uri.parse("https://api.siputzx.my.id/api/d/igdl?url=$encodedUrl");

    try {
      final response = await http.get(apiUrl).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null && json['data'].isNotEmpty) {
          setState(() {
            _mediaData = json['data'];
          });
        } else {
          setState(() {
            _errorMessage = json['message'] ?? "Gagal mengambil data Instagram";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal terhubung ke server (HTTP ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: ${e.toString().replaceAll('TimeoutException', 'Request timeout')}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playVideo(String videoUrl) async {
    if (videoUrl == _currentVideoUrl && _chewieController != null) {
      return;
    }

    _currentVideoUrl = videoUrl;
    
    // Dispose lama sebelum buat baru
    await _videoController?.dispose();
    _chewieController?.dispose();

    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await _videoController!.initialize();
    
    if (mounted) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: lightPurple,
            handleColor: lightPurple,
            backgroundColor: Colors.grey.withOpacity(0.3),
            bufferedColor: Colors.grey.withOpacity(0.2),
          ),
        );
      });
    }
  }

  Future<void> _downloadMedia(String mediaUrl, String type) async {
    try {
      final response = await http.get(Uri.parse(mediaUrl));
      final tempDir = await getTemporaryDirectory();
      final extension = type == 'video' ? 'mp4' : 'jpg';
      final file = File('${tempDir.path}/instagram_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: bgDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: lightPurple.withOpacity(0.2)),
            ),
            title: const Text("Download Selesai", style: TextStyle(color: lightPurple)),
            content: const Text("Media berhasil disimpan sementara.", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: lightPurple)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(file.path)], text: 'Instagram Media');
                },
                style: ElevatedButton.styleFrom(backgroundColor: lightPurple),
                child: const Text("Share", style: TextStyle(color: primaryWhite)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna transparan di dalam build agar tidak error
    final Color subtleGlass = Colors.white.withOpacity(0.05);
    final Color borderSubtle = Colors.white.withOpacity(0.1);
    final Color textGrey = Colors.grey.shade400;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text('Instagram Downloader', style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Link Section
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
                    style: const TextStyle(color: primaryWhite),
                    decoration: InputDecoration(
                      labelText: 'Paste Link Instagram',
                      labelStyle: const TextStyle(color: lightPurple),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderSubtle),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: lightPurple),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.link, color: lightPurple),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _downloadInstagram,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('AMBIL MEDIA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
            ],

            const SizedBox(height: 24),

            // Video Player Area
            if (_chewieController != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Chewie(controller: _chewieController!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text("Download Video Ini"),
                    onPressed: () => _downloadMedia(_currentVideoUrl!, 'video'),
                  )
                ],
              ),

            // Gallery Area
            if (_mediaData != null)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _mediaData!.length,
                itemBuilder: (context, index) {
                  final item = _mediaData![index];
                  final isVideo = item['type'] == 'video';
                  return GestureDetector(
                    onTap: () => isVideo ? _playVideo(item['url']) : null,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(item['thumbnail'] ?? item['url'], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        ),
                        if (isVideo) const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: IconButton(
                            icon: const Icon(Icons.download_for_offline, color: lightPurple),
                            onPressed: () => _downloadMedia(item['url'], item['type']),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
              
            // Empty State Icon (Fix: Member not found 'instagram')
            if (_mediaData == null && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Opacity(
                  opacity: 0.3,
                  child: Column(
                    children: [
                      const Icon(Icons.camera_alt, size: 80, color: lightPurple),
                      const SizedBox(height: 10),
                      Text("Menunggu URL...", style: TextStyle(color: textGrey)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
