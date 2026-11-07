import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class AnimeStreamPage extends StatefulWidget {
  const AnimeStreamPage({super.key});

  @override
  State<AnimeStreamPage> createState() => _AnimeStreamPageState();
}

class _AnimeStreamPageState extends State<AnimeStreamPage> {
  List<dynamic> animeList = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedCategory = "All";
  
  final List<String> categories = [
    "All", "Action", "Adventure", "Comedy", "Drama", 
    "Fantasy", "Romance", "Sci-Fi", "Slice of Life"
  ];
  
  // --- BLUE THEME ---
  static const Color bgDark = Color(0xFF0A0A0A);
  static const Color glassPrimary = Color(0xFF1A1A1A);
  static const Color glassSecondary = Colors.white;
  static const Color accentBlue = Colors.white;
  static const Color darkBlue = Colors.white;
  static const Color softBlue = Color(0xFFF1F5F9);
  static const Color primaryWhite = Color(0xFF9CA3AF);
  static const Color softGrey = Color(0xFFFF9800);

  LinearGradient get blueGradient => const LinearGradient(
    colors: [accentBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    fetchAnimeList();
  }

  Future<void> fetchAnimeList() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Menggunakan API MyAnimeList atau Jikan API
      final response = await http.get(
        Uri.parse("https://api.jikan.moe/v4/top/anime?limit=20"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          animeList = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        // Jika API gagal, gunakan data lokal
        loadLocalAnime();
      }
    } catch (e) {
      loadLocalAnime();
    }
  }

  void loadLocalAnime() {
    setState(() {
      animeList = getLocalAnime();
      isLoading = false;
    });
  }

  List<dynamic> getLocalAnime() {
    return [
      {
        "title": "Attack on Titan",
        "episodes": 87,
        "rating": 9.0,
        "year": 2013,
        "synopsis": "Humans are on the brink of extinction after giant humanoid creatures known as Titans appear.",
        "image": "https://cdn.myanimelist.net/images/anime/10/47347.jpg",
        "category": "Action"
      },
      {
        "title": "Demon Slayer",
        "episodes": 44,
        "rating": 8.8,
        "year": 2019,
        "synopsis": "A young boy becomes a demon slayer after his family is slaughtered and his sister turned into a demon.",
        "image": "https://cdn.myanimelist.net/images/anime/1286/99889.jpg",
        "category": "Action"
      },
      {
        "title": "Jujutsu Kaisen",
        "episodes": 24,
        "rating": 8.7,
        "year": 2020,
        "synopsis": "A boy swallows a cursed talisman and becomes a host to a powerful curse.",
        "image": "https://cdn.myanimelist.net/images/anime/1171/109222.jpg",
        "category": "Action"
      },
      {
        "title": "One Punch Man",
        "episodes": 24,
        "rating": 8.5,
        "year": 2015,
        "synopsis": "A hero who can defeat any opponent with a single punch searches for a worthy challenge.",
        "image": "https://cdn.myanimelist.net/images/anime/1887/117294.jpg",
        "category": "Action"
      },
      {
        "title": "Your Name",
        "episodes": 1,
        "rating": 9.1,
        "year": 2016,
        "synopsis": "Two strangers find they are linked in a strange way.",
        "image": "https://cdn.myanimelist.net/images/anime/5/87048.jpg",
        "category": "Romance"
      },
      {
        "title": "Spy x Family",
        "episodes": 25,
        "rating": 8.9,
        "year": 2022,
        "synopsis": "A spy creates a fake family for a mission, not knowing his daughter is a telepath and his wife is an assassin.",
        "image": "https://cdn.myanimelist.net/images/anime/1441/122795.jpg",
        "category": "Comedy"
      },
      {
        "title": "Chainsaw Man",
        "episodes": 12,
        "rating": 8.7,
        "year": 2022,
        "synopsis": "A young boy becomes a devil hunter after merging with his pet devil.",
        "image": "https://cdn.myanimelist.net/images/anime/1806/126216.jpg",
        "category": "Action"
      },
      {
        "title": "My Hero Academia",
        "episodes": 138,
        "rating": 8.4,
        "year": 2016,
        "synopsis": "A boy without superpowers enrolls in a school for heroes.",
        "image": "https://cdn.myanimelist.net/images/anime/1799/114437.jpg",
        "category": "Action"
      }
    ];
  }

  List<dynamic> getFilteredAnime() {
    if (selectedCategory == "All") {
      return animeList;
    }
    return animeList.where((anime) {
      return anime['category'] == selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAnime = getFilteredAnime();

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: glassSecondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryWhite.withOpacity(0.08)),
          ),
          child: const Text(
            "Anime Stream",
            style: TextStyle(
              color: primaryWhite,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: accentBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? blueGradient : null,
                      color: isSelected ? null : glassSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : primaryWhite.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? primaryWhite : softGrey,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              accentBlue.withOpacity(0.15),
              bgDark,
              bgDark,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: GridPainter(),
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: glassSecondary,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: accentBlue.withOpacity(0.2)),
                        ),
                        child: CircularProgressIndicator(
                          color: accentBlue,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Loading anime list...",
                        style: TextStyle(color: softGrey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : filteredAnime.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: glassSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tv_off_rounded,
                              color: accentBlue,
                              size: 60,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No Anime Found",
                            style: TextStyle(
                              color: primaryWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Try selecting a different category",
                            style: TextStyle(color: softGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredAnime.length,
                      itemBuilder: (context, index) {
                        final anime = filteredAnime[index];
                        return buildAnimeCard(anime);
                      },
                    ),
        ),
      ),
    );
  }

  Widget buildAnimeCard(dynamic anime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: glassPrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryWhite.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and Title Section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Stack(
              children: [
                Image.network(
                  anime['image'] ?? '',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: glassSecondary,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: accentBlue, size: 50),
                      ),
                    );
                  },
                ),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        bgDark.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime['title'] ?? 'Unknown',
                        style: const TextStyle(
                          color: primaryWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentBlue.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              anime['category'] ?? 'Anime',
                              style: const TextStyle(
                                color: primaryWhite,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                anime['rating']?.toString() ?? '0',
                                style: const TextStyle(
                                  color: primaryWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.tv_rounded, color: softGrey, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                "${anime['episodes']} eps",
                                style: TextStyle(
                                  color: softGrey,
                                  fontSize: 11,
                                ),
                              ),
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
          
          // Synopsis Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Synopsis",
                  style: TextStyle(
                    color: accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  anime['synopsis'] ?? 'No synopsis available',
                  style: TextStyle(
                    color: softGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: blueGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded, color: primaryWhite, size: 18),
                          label: const Text(
                            "WATCH NOW",
                            style: TextStyle(
                              color: primaryWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            _showComingSoon(context, anime['title']);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.info_outline_rounded, color: accentBlue, size: 18),
                        label: const Text(
                          "DETAILS",
                          style: TextStyle(
                            color: accentBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accentBlue.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          _showAnimeDetail(anime);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: glassPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: primaryWhite.withOpacity(0.1), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: blueGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: primaryWhite, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "Coming Soon",
              style: TextStyle(color: primaryWhite, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "Streaming for $title will be available soon!",
          style: const TextStyle(color: softGrey, fontSize: 14),
        ),
        actions: [
          Center(
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                gradient: blueGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(color: primaryWhite, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnimeDetail(dynamic anime) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: glassPrimary,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: primaryWhite.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Image.network(
                  anime['image'] ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: glassSecondary,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: accentBlue, size: 50),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime['title'] ?? 'Unknown',
                      style: const TextStyle(
                        color: primaryWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            anime['category'] ?? 'Anime',
                            style: TextStyle(color: accentBlue, fontSize: 11),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                anime['rating']?.toString() ?? '0',
                                style: const TextStyle(color: Colors.amber, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: softBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${anime['episodes']} Episodes",
                            style: TextStyle(color: softBlue, fontSize: 11),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Year ${anime['year']}",
                            style: TextStyle(color: softGrey, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Synopsis",
                      style: TextStyle(
                        color: accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anime['synopsis'] ?? 'No synopsis available',
                      style: TextStyle(color: softGrey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: blueGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showComingSoon(context, anime['title']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "WATCH NOW",
                          style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold),
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
    );
  }
}

// Custom Grid Painter for background
class GridPainter extends CustomPainter {
  static const Color accentBlue = Colors.white;
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    
    const gridSize = 30.0;
    
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    final accentPaint = Paint()
      ..color = accentBlue.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }
    
    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }
    
    final dotPaint = Paint()
      ..color = accentBlue.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    
    for (double x = 0; x <= size.width; x += gridSize) {
      for (double y = 0; y <= size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}