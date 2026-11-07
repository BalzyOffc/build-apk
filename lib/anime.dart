import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tema hitam elegan (konsisten dengan halaman lain)
class AnimeTheme {
  static const Color background = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF1A1A1A); 
  static const Color primaryAccent = Colors.white;
  static const Color secondaryAccent = Colors.white;
  static const Color tertiaryAccent = Colors.white; 
  static const Color textLight = Color(0xFFF1F5F9); 
  static const Color textGrey = Color(0xFF9CA3AF); 
  static const Color statusOngoing = Color(0xFFFF9800);
  static const Color statusCompleted = Color(0xFF4CAF50);
}

class HomeAnimePage extends StatefulWidget {
  const HomeAnimePage({super.key});

  @override
  State<HomeAnimePage> createState() => _HomeAnimePageState();
}

class _HomeAnimePageState extends State<HomeAnimePage> {
  Map<String, dynamic>? animeData;
  bool isLoading = true;
  bool isSearching = false;
  List<dynamic> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _watchHistory = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnimeData();
    _loadWatchHistory();
  }

  void refreshHistory() {
    _loadWatchHistory();
  }

  Future<void> _loadWatchHistory() async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      setState(() {
        _watchHistory = historyJson
            .map((item) => Map<String, dynamic>.from(json.decode(item)))
            .toList();
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading watch history: $e');
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> fetchAnimeData() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/home'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeData = jsonData['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data anime');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> searchAnime(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/search/$query'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          searchResults = jsonData['data']['animeList'] ?? [];
        });
      } else {
        setState(() {
          searchResults = [];
        });
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() {
        searchResults = [];
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      searchResults.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimeTheme.background,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AnimeTheme.primaryAccent, AnimeTheme.secondaryAccent],
          ).createShader(bounds),
          child: const Text(
            'Tempat Wibu',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: AnimeTheme.card,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: AnimeTheme.primaryAccent),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: AnimeTheme.primaryAccent),
              decoration: InputDecoration(
                hintText: "Search anime...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: AnimeTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: AnimeTheme.primaryAccent.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: AnimeTheme.primaryAccent.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: AnimeTheme.primaryAccent),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  searchAnime(value);
                } else {
                  setState(() {
                    isSearching = false;
                    searchResults.clear();
                  });
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  searchAnime(value);
                }
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? _buildLoadingShimmer()
                : isSearching
                ? _buildSearchResults()
                : animeData == null
                ? _buildErrorWidget()
                : _buildHomeContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          fetchAnimeData(),
          _loadWatchHistory(),
        ]);
      },
      color: AnimeTheme.primaryAccent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.history, "Watch History"),
            const SizedBox(height: 12),
            if (_isHistoryLoading)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Shimmer.fromColors(
                        baseColor: AnimeTheme.card,
                        highlightColor: AnimeTheme.primaryAccent.withOpacity(0.2),
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: AnimeTheme.card,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_watchHistory.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  "No watch history yet. Start watching an anime!",
                  style: TextStyle(color: AnimeTheme.textGrey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _watchHistory.length,
                  itemBuilder: (context, index) {
                    final anime = _watchHistory[index];
                    return _buildHistoryCard(anime);
                  },
                ),
              ),
            _buildSectionHeader(Icons.dashboard, "Quick Access"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    "Genre",
                    Icons.category,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnimeGenreListPage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    "Schedule",
                    Icons.schedule,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnimeSchedulePage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(Icons.live_tv, "Currently Airing"),
            const SizedBox(height: 12),
            _buildAnimeGrid(animeData!['ongoing']['animeList'] ?? []),
            const SizedBox(height: 24),
            _buildSectionHeader(Icons.check_circle, "Completed Series"),
            const SizedBox(height: 12),
            _buildAnimeGrid(animeData!['completed']['animeList'] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AnimeTheme.primaryAccent, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AnimeTheme.primaryAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> anime) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (anime['last_watched_episode_slug'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeEpisodePage(
                  episodeSlug: anime['last_watched_episode_slug'],
                  animeSlug: anime['slug'],
                  animeTitle: anime['title'],
                  animePoster: anime['poster'],
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailPage(
                  slug: anime['slug'],
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    anime['poster'],
                    height: 160,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      width: 120,
                      color: AnimeTheme.card,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_not_supported, color: AnimeTheme.textGrey),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow, color: AnimeTheme.primaryAccent, size: 16),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    child: Text(
                      anime['last_watched_episode'] ?? '',
                      style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              anime['title'],
              style: TextStyle(
                color: AnimeTheme.primaryAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: AnimeTheme.textGrey, size: 64),
            const SizedBox(height: 16),
            Text("No results found", style: TextStyle(color: AnimeTheme.textGrey, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Try with different keywords", style: TextStyle(color: AnimeTheme.textGrey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final anime = searchResults[index];
        return _buildSearchResultCard(anime);
      },
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> anime) {
    final String title = anime['title'];
    final String poster = anime['poster'];
    final String? status = anime['status'];
    final String? score = anime['score'];
    final String slug = anime['animeId'];
    final List<dynamic> genres = anime['genreList'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AnimeTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(
                slug: slug,
                onHistoryUpdate: refreshHistory,
              ),
            ),
          ).then((_) => refreshHistory());
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  poster,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 120,
                    color: AnimeTheme.card,
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported, color: AnimeTheme.textGrey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AnimeTheme.primaryAccent,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (score != null && score.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(score, style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (status != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'ongoing' ? AnimeTheme.statusOngoing : AnimeTheme.statusCompleted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: genres.take(3).map<Widget>((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AnimeTheme.primaryAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              genre['title'],
                              style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 10),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimeGrid(List<dynamic> list) {
    return GridView.builder(
      itemCount: list.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final anime = list[index];
        final String title = anime['title'];
        final String poster = anime['poster'];
        final String? episode = anime['episodes']?.toString();
        final String? date = anime['latestReleaseDate'] ?? anime['lastReleaseDate'];
        final String slug = anime['animeId'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailPage(
                  slug: slug,
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  child: Image.network(
                    poster,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 170,
                      color: AnimeTheme.card,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_not_supported, color: AnimeTheme.textGrey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AnimeTheme.primaryAccent,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    episode != null ? "$episode Episodes" : "-",
                    style: TextStyle(fontSize: 12, color: AnimeTheme.textGrey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    "Updated: $date",
                    style: TextStyle(fontSize: 11, color: AnimeTheme.textGrey, height: 1.2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AnimeTheme.card,
        highlightColor: AnimeTheme.primaryAccent.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            color: AnimeTheme.card,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AnimeTheme.textGrey, size: 64),
          const SizedBox(height: 16),
          Text("Failed to load data", style: TextStyle(color: AnimeTheme.textGrey, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await Future.wait([fetchAnimeData(), _loadWatchHistory()]);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AnimeTheme.primaryAccent,
            ),
            child: Text("Try Again", style: TextStyle(color: AnimeTheme.background)),
          ),
        ],
      ),
    );
  }
}

Widget _buildQuickAccessCard(String title, IconData icon, VoidCallback onTap) {
  return Container(
    decoration: BoxDecoration(
      color: AnimeTheme.card,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AnimeTheme.primaryAccent, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: AnimeTheme.primaryAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class AnimeDetailPage extends StatefulWidget {
  final String slug;
  final Function()? onHistoryUpdate;

  const AnimeDetailPage({super.key, required this.slug, this.onHistoryUpdate});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  Map<String, dynamic>? animeDetail;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchAnimeDetail();
  }

  Future<void> fetchAnimeDetail() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/anime/${widget.slug}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeDetail = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimeTheme.background,
      appBar: AppBar(
        title: Text(
          "Anime Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AnimeTheme.primaryAccent,
          ),
        ),
        backgroundColor: AnimeTheme.card,
        iconTheme: IconThemeData(color: AnimeTheme.primaryAccent),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError || animeDetail == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AnimeTheme.textGrey, size: 64),
                  const SizedBox(height: 16),
                  Text("Failed to load anime details", style: TextStyle(color: AnimeTheme.textGrey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchAnimeDetail,
                    style: ElevatedButton.styleFrom(backgroundColor: AnimeTheme.primaryAccent),
                    child: Text("Try Again", style: TextStyle(color: AnimeTheme.background)),
                  ),
                ],
              ),
            )
          : _buildAnimeDetail(),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: AnimeTheme.card,
            highlightColor: AnimeTheme.primaryAccent.withOpacity(0.2),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: AnimeTheme.card, borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: AnimeTheme.card,
            highlightColor: AnimeTheme.primaryAccent.withOpacity(0.2),
            child: Container(height: 24, width: 200, decoration: BoxDecoration(color: AnimeTheme.card, borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: AnimeTheme.card,
            highlightColor: AnimeTheme.primaryAccent.withOpacity(0.2),
            child: Container(height: 16, width: double.infinity, decoration: BoxDecoration(color: AnimeTheme.card, borderRadius: BorderRadius.circular(4))),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeDetail() {
    final anime = animeDetail!;
    final List<dynamic> episodes = anime['episodeList'] ?? [];
    final List<dynamic> recommendations = anime['recommendedAnimeList'] ?? [];
    final List<dynamic> genres = anime['genreList'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  anime['poster'],
                  height: 200,
                  width: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    width: 140,
                    color: AnimeTheme.card,
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported, color: AnimeTheme.textGrey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AnimeTheme.primaryAccent,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anime['japanese'] ?? '-',
                      style: TextStyle(fontSize: 14, color: AnimeTheme.textGrey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(anime['score'] ?? '-', style: TextStyle(color: AnimeTheme.primaryAccent)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem('Type', anime['type']),
                    _buildInfoItem('Status', anime['status']),
                    _buildInfoItem('Episodes', anime['episodes']?.toString()),
                    _buildInfoItem('Duration', anime['duration']),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (genres.isNotEmpty) ...[
            Text("Genres", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres.map<Widget>((genre) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimeGenrePage(
                          genreSlug: genre['genreId'],
                          genreName: genre['title'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AnimeTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      genre['title'],
                      style: TextStyle(color: AnimeTheme.background, fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (anime['synopsis'] != null && anime['synopsis']['paragraphs'].isNotEmpty) ...[
            Text("Synopsis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AnimeTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
              ),
              child: Text(
                anime['synopsis']['paragraphs'].join('\n\n'),
                style: TextStyle(color: AnimeTheme.primaryAccent, height: 1.5),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (episodes.isNotEmpty) ...[
            Text("Episodes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent)),
            const SizedBox(height: 8),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AnimeTheme.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AnimeTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          episode['eps'].toString(),
                          style: TextStyle(color: AnimeTheme.background, fontSize: 12),
                        ),
                      ),
                    ),
                    title: Text(
                      episode['title'],
                      style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeEpisodePage(
                            episodeSlug: episode['episodeId'],
                            animeSlug: widget.slug,
                            animeTitle: anime['title'],
                            animePoster: anime['poster'],
                            episodes: episodes,
                            recommendations: recommendations,
                            onHistoryUpdate: widget.onHistoryUpdate,
                          ),
                        ),
                      ).then((_) {
                        if (widget.onHistoryUpdate != null) widget.onHistoryUpdate!();
                      });
                    },
                    trailing: Icon(Icons.play_arrow, color: AnimeTheme.primaryAccent),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
          if (anime['batch'] != null) ...[
            Container(
              decoration: BoxDecoration(
                color: AnimeTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: Icon(Icons.download, color: AnimeTheme.primaryAccent),
                title: Text("Download Batch", style: TextStyle(color: AnimeTheme.primaryAccent, fontWeight: FontWeight.bold)),
                subtitle: Text(anime['batch']['title'], style: TextStyle(color: AnimeTheme.textGrey)),
                onTap: () => _launchURL(anime['batch']['otakudesuUrl']),
                trailing: Icon(Icons.arrow_forward_ios, color: AnimeTheme.primaryAccent, size: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (recommendations.isNotEmpty) ...[
            Text("Recommendations", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final recommendation = recommendations[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeDetailPage(
                            slug: recommendation['animeId'],
                            onHistoryUpdate: widget.onHistoryUpdate,
                          ),
                        ),
                      ).then((_) {
                        if (widget.onHistoryUpdate != null) widget.onHistoryUpdate!();
                      });
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              recommendation['poster'],
                              height: 160,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 160,
                                width: 120,
                                color: AnimeTheme.card,
                                alignment: Alignment.center,
                                child: Icon(Icons.image_not_supported, color: AnimeTheme.textGrey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendation['title'],
                            style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label: ', style: TextStyle(color: AnimeTheme.textGrey, fontSize: 12)),
            TextSpan(text: value ?? '-', style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class AnimeGenrePage extends StatefulWidget {
  final String genreSlug;
  final String genreName;

  const AnimeGenrePage({super.key, required this.genreSlug, required this.genreName});

  @override
  State<AnimeGenrePage> createState() => _AnimeGenrePageState();
}

class _AnimeGenrePageState extends State<AnimeGenrePage> {
  List<dynamic> animeList = [];
  Map<String, dynamic>? pagination;
  bool isLoading = true;
  bool isError = false;
  int currentPage = 1;

  Future<void> fetchGenreAnime({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/genre/${widget.genreSlug}?page=$page'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeList = jsonData['data']['animeList'];
          pagination = jsonData['pagination'];
          isLoading = false;
          currentPage = page;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenreAnime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimeTheme.background,
      appBar: AppBar(
        title: Text(
          "Genre: ${widget.genreName}",
          style: TextStyle(fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent),
        ),
        backgroundColor: AnimeTheme.card,
        iconTheme: IconThemeData(color: AnimeTheme.primaryAccent),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AnimeTheme.textGrey, size: 64),
                  const SizedBox(height: 16),
                  Text("Failed to load genre data", style: TextStyle(color: AnimeTheme.textGrey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => fetchGenreAnime(),
                    style: ElevatedButton.styleFrom(backgroundColor: AnimeTheme.primaryAccent),
                    child: Text("Try Again", style: TextStyle(color: AnimeTheme.background)),
                  ),
                ],
              ),
            )
          : _buildGenreContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AnimeTheme.card,
          highlightColor: AnimeTheme.primaryAccent.withOpacity(0.2),
          child: Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AnimeTheme.card, borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
    );
  }

  Widget _buildGenreContent() {
    return Column(
      children: [
        if (pagination != null) _buildPaginationInfo(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return _buildAnimeCard(anime);
            },
          ),
        ),
        if (pagination != null) _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnimeTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Page $currentPage of ${pagination!['totalPages']}", style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 12)),
          Text("Total: ${animeList.length} anime", style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final hasNext = pagination!['hasNextPage'] ?? false;
    final hasPrev = pagination!['hasPrevPage'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasPrev)
            ElevatedButton(
              onPressed: () => fetchGenreAnime(page: currentPage - 1),
              style: ElevatedButton.styleFrom(backgroundColor: AnimeTheme.primaryAccent),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: AnimeTheme.background),
                  const SizedBox(width: 4),
                  Text("Previous", style: TextStyle(color: AnimeTheme.background)),
                ],
              ),
            ),
          const SizedBox(width: 16),
          if (hasNext)
            ElevatedButton(
              onPressed: () => fetchGenreAnime(page: currentPage + 1),
              style: ElevatedButton.styleFrom(backgroundColor: AnimeTheme.primaryAccent),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Next", style: TextStyle(color: AnimeTheme.background)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: AnimeTheme.background),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    final String title = anime['title'];
    final String poster = anime['poster'];
    final String score = anime['score'] ?? '-';
    final String episodeCount = anime['episodes']?.toString() ?? '?';
    final String season = anime['season'] ?? '-';
    final String studio = anime['studios'] ?? '-';
    final String synopsis = anime['synopsis'] != null && anime['synopsis']['paragraphs'] != null
        ? anime['synopsis']['paragraphs'].join('\n\n')
        : '';
    final String slug = anime['animeId'];
    final List<dynamic> genres = anime['genreList'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AnimeTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: slug)),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  poster,
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 140,
                    color: AnimeTheme.card,
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported, color: AnimeTheme.textGrey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(score, style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Text("$episodeCount Episodes", style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("$season • $studio", style: TextStyle(color: AnimeTheme.textGrey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    if (genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: genres.take(3).map<Widget>((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AnimeTheme.primaryAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(genre['title'], style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 10)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (synopsis.isNotEmpty) ...[
                      Text(
                        synopsis,
                        style: TextStyle(color: AnimeTheme.textGrey, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

class AnimeSchedulePage extends StatefulWidget {
  const AnimeSchedulePage({super.key});

  @override
  State<AnimeSchedulePage> createState() => _AnimeSchedulePageState();
}

class _AnimeSchedulePageState extends State<AnimeSchedulePage> {
  List<dynamic> scheduleData = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/schedule'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          scheduleData = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimeTheme.background,
      appBar: AppBar(
        title: Text("Release Schedule", style: TextStyle(fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent)),
        backgroundColor: AnimeTheme.card,
        iconTheme: IconThemeData(color: AnimeTheme.primaryAccent),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AnimeTheme.textGrey, size: 64),
                  const SizedBox(height: 16),
                  Text("Failed to load release schedule", style: TextStyle(color: AnimeTheme.textGrey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchSchedule,
                    style: ElevatedButton.styleFrom(backgroundColor: AnimeTheme.primaryAccent),
                    child: Text("Try Again", style: TextStyle(color: AnimeTheme.background)),
                  ),
                ],
              ),
            )
          : _buildScheduleContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AnimeTheme.card,
          highlightColor: AnimeTheme.primaryAccent.withOpacity(0.2),
          child: Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AnimeTheme.card, borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
    );
  }

  Widget _buildScheduleContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: scheduleData.length,
      itemBuilder: (context, index) {
        final daySchedule = scheduleData[index];
        final String day = daySchedule['day'];
        final List<dynamic> animeList = daySchedule['anime_list'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AnimeTheme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AnimeTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(day, style: TextStyle(color: AnimeTheme.background, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text("${animeList.length} Anime", style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                if (animeList.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: animeList.length,
                      itemBuilder: (context, animeIndex) {
                        final anime = animeList[animeIndex];
                        final String title = anime['title'];
                        final String poster = anime['poster'];
                        final String slug = anime['slug'];

                        return Container(
                          width: 120,
                          margin: EdgeInsets.only(right: animeIndex == animeList.length - 1 ? 0 : 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: slug)),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    poster,
                                    width: 120,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 120,
                                      height: 160,
                                      color: AnimeTheme.card,
                                      alignment: Alignment.center,
                                      child: Icon(Icons.image_not_supported, color: AnimeTheme.textGrey),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.w500),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimeGenreListPage extends StatefulWidget {
  const AnimeGenreListPage({super.key});

  @override
  State<AnimeGenreListPage> createState() => _AnimeGenreListPageState();
}

class _AnimeGenreListPageState extends State<AnimeGenreListPage> {
  List<dynamic> genreList = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchGenreList() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/genre/'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          genreList = jsonData['data']['genreList'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching genre list: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenreList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimeTheme.background,
      appBar: AppBar(
        title: Text("Anime Genres", style: TextStyle(fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent)),
        backgroundColor: AnimeTheme.card,
        iconTheme: IconThemeData(color: AnimeTheme.primaryAccent),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AnimeTheme.textGrey, size: 64),
                  const SizedBox(height: 16),
                  Text("Failed to load genre list", style: TextStyle(color: AnimeTheme.textGrey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchGenreList,
                    style: ElevatedButton.styleFrom(backgroundColor: AnimeTheme.primaryAccent),
                    child: Text("Try Again", style: TextStyle(color: AnimeTheme.background)),
                  ),
                ],
              ),
            )
          : _buildGenreGrid(),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 20,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AnimeTheme.card,
          highlightColor: AnimeTheme.primaryAccent.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(color: AnimeTheme.card, borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
    );
  }

  Widget _buildGenreGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: genreList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, index) {
        final genre = genreList[index];
        final String name = genre['title'];
        final String slug = genre['genreId'];

        return Container(
          decoration: BoxDecoration(
            color: AnimeTheme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimeGenrePage(genreSlug: slug, genreName: name),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                name,
                style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimeEpisodePage extends StatefulWidget {
  final String episodeSlug;
  final String? animeSlug;
  final String? animeTitle;
  final String? animePoster;
  final List<dynamic>? episodes;
  final List<dynamic>? recommendations;
  final Function()? onHistoryUpdate;

  const AnimeEpisodePage({
    super.key,
    required this.episodeSlug,
    this.animeSlug,
    this.animeTitle,
    this.animePoster,
    this.episodes,
    this.recommendations,
    this.onHistoryUpdate,
  });

  @override
  State<AnimeEpisodePage> createState() => _AnimeEpisodePageState();
}

class _AnimeEpisodePageState extends State<AnimeEpisodePage> with WidgetsBindingObserver {
  Map<String, dynamic>? episodeData;
  bool isLoading = true;
  bool isError = false;
  int _currentTabIndex = 0;

  late WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _isFullScreen = false;

  List<dynamic> _qualities = [];
  int _selectedQualityIndex = 0;
  int _selectedServerIndex = 0;
  bool _showQualitySelector = false;

  String? _streamUrl;
  int _currentEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchEpisodeData();
    _findCurrentEpisodeIndex();
  }

  void _findCurrentEpisodeIndex() {
    if (widget.episodes != null) {
      for (int i = 0; i < widget.episodes!.length; i++) {
        if (widget.episodes![i]['episodeId'] == widget.episodeSlug) {
          setState(() {
            _currentEpisodeIndex = i;
          });
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final physicalSize = WidgetsBinding.instance.window.physicalSize;
    final pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final logicalSize = physicalSize / pixelRatio;
    final isNowFullScreen = logicalSize.width > logicalSize.height;

    if (isNowFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = isNowFullScreen;
      });

      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  Future<void> fetchEpisodeData() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/episode/${widget.episodeSlug}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          episodeData = jsonData['data'];
          _qualities = episodeData?['server']?['qualities'] ?? [];
          if (_qualities.isNotEmpty) {
            for (int i = 0; i < _qualities.length; i++) {
              final quality = _qualities[i];
              final serverList = quality['serverList'] ?? [];
              if (serverList.isNotEmpty) {
                _selectedQualityIndex = i;
                _selectedServerIndex = 0;
                break;
              }
            }
          }
        });
        await _fetchStreamUrl();
        _initializeWebView();
        _addToWatchHistory();
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> _fetchStreamUrl() async {
    if (_qualities.isEmpty) return;
    final selectedQuality = _qualities[_selectedQualityIndex];
    final serverList = selectedQuality['serverList'] ?? [];
    if (serverList.isEmpty) return;
    final selectedServer = serverList[_selectedServerIndex];
    final serverId = selectedServer['serverId'];

    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/server/$serverId'),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _streamUrl = jsonData['data']['url'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching stream URL: $e');
    }
  }

  Future<void> _addToWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      List<Map<String, dynamic>> watchHistory = historyJson
          .map((item) => Map<String, dynamic>.from(json.decode(item)))
          .toList();

      final historyItem = {
        'slug': widget.animeSlug,
        'title': widget.animeTitle,
        'poster': widget.animePoster,
        'last_watched_episode': episodeData?['title'],
        'last_watched_episode_slug': widget.episodeSlug,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      watchHistory.removeWhere((item) => item['slug'] == widget.animeSlug);
      watchHistory.insert(0, historyItem);
      if (watchHistory.length > 20) {
        watchHistory = watchHistory.sublist(0, 20);
      }
      final newHistoryJson = watchHistory.map((item) => json.encode(item)).toList();
      await prefs.setStringList('watch_history', newHistoryJson);
      if (widget.onHistoryUpdate != null) {
        widget.onHistoryUpdate!();
      }
    } catch (e) {
      debugPrint('Error saving to watch history: $e');
    }
  }

  void _initializeWebView() {
    if (_streamUrl == null) return;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FullScreen',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'enter') {
            _enterFullScreen();
          } else if (message.message == 'exit') {
            _exitFullScreen();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isWebViewLoading = false;
              });
              _injectFullScreenDetection();
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isWebViewLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isWebViewLoading = false;
            });
            _injectFullScreenDetection();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isWebViewLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(_streamUrl!),
        headers: _getChromeHeaders(),
      );
  }

  void _injectFullScreenDetection() {
    _webViewController.runJavaScript('''
      function handleFullScreenChange() {
        if (document.fullscreenElement || document.webkitFullscreenElement || 
            document.mozFullScreenElement || document.msFullscreenElement) {
          FullScreen.postMessage('enter');
        } else {
          FullScreen.postMessage('exit');
        }
      }
      document.addEventListener('fullscreenchange', handleFullScreenChange);
      document.addEventListener('webkitfullscreenchange', handleFullScreenChange);
      document.addEventListener('mozfullscreenchange', handleFullScreenChange);
      document.addEventListener('MSFullscreenChange', handleFullScreenChange);
      document.addEventListener('click', function(e) {
        if (e.target.tagName === 'VIDEO' || e.target.closest('video')) {
          setTimeout(handleFullScreenChange, 100);
        }
      });
      document.addEventListener('touchend', function(e) {
        if (e.target.tagName === 'VIDEO' || e.target.closest('video')) {
          setTimeout(handleFullScreenChange, 100);
        }
      });
      document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
          setTimeout(handleFullScreenChange, 100);
        }
      });
      console.log('Fullscreen detection injected');
    ''');
  }

  void _enterFullScreen() {
    if (!_isFullScreen) {
      setState(() {
        _isFullScreen = true;
      });
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _exitFullScreen() {
    if (_isFullScreen) {
      setState(() {
        _isFullScreen = false;
      });
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Map<String, String> _getChromeHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
    };
  }

  void _refreshWebView() {
    setState(() {
      _isWebViewLoading = true;
    });
    _webViewController.reload();
  }

  void _openInExternalBrowser() {
    if (_streamUrl != null) {
      _launchURL(_streamUrl!);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AnimeTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Download Options", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent)),
                const SizedBox(height: 16),
                Text("Download options will be available soon.", style: TextStyle(color: AnimeTheme.textGrey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openInExternalBrowser();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AnimeTheme.primaryAccent),
                  child: Text("Open in Browser", style: TextStyle(color: AnimeTheme.background)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToNextEpisode() {
    if (widget.episodes != null && _currentEpisodeIndex < widget.episodes!.length - 1) {
      final nextEpisode = widget.episodes![_currentEpisodeIndex + 1];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeEpisodePage(
            episodeSlug: nextEpisode['episodeId'],
            animeSlug: widget.animeSlug,
            animeTitle: widget.animeTitle,
            animePoster: widget.animePoster,
            episodes: widget.episodes,
            recommendations: widget.recommendations,
            onHistoryUpdate: widget.onHistoryUpdate,
          ),
        ),
      );
    }
  }

  void _changeQuality(int qualityIndex, int serverIndex) async {
    setState(() {
      _selectedQualityIndex = qualityIndex;
      _selectedServerIndex = serverIndex;
      _isWebViewLoading = true;
      _streamUrl = null;
    });
    await _fetchStreamUrl();
    _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimeTheme.background,
      appBar: _isFullScreen ? null : AppBar(
        title: Text(
          episodeData?['title'] ?? "Streaming Anime",
          style: TextStyle(fontWeight: FontWeight.bold, color: AnimeTheme.primaryAccent, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AnimeTheme.card,
        iconTheme: IconThemeData(color: AnimeTheme.primaryAccent),
        actions: [
          if (episodeData != null) ...[
            IconButton(icon: Icon(Icons.refresh, color: AnimeTheme.primaryAccent), onPressed: _refreshWebView, tooltip: 'Refresh'),
            IconButton(icon: Icon(Icons.open_in_browser, color: AnimeTheme.primaryAccent), onPressed: _openInExternalBrowser, tooltip: 'Open in Browser'),
            IconButton(onPressed: _showDownloadOptions, icon: Icon(Icons.download, color: AnimeTheme.primaryAccent), tooltip: 'Download'),
          ],
        ],
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError || episodeData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AnimeTheme.textGrey, size: 64),
                  const SizedBox(height: 16),
                  Text("Failed to load episode", style: TextStyle(color: AnimeTheme.textGrey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchEpisodeData,
                    style: ElevatedButton.styleFrom(backgroundColor: AnimeTheme.primaryAccent),
                    child: Text("Try Again", style: TextStyle(color: AnimeTheme.background)),
                  ),
                ],
              ),
            )
          : _buildStreamingContent(),
    );
  }

  Widget _buildStreamingContent() {
    final List<dynamic> episodes = widget.episodes ?? [];
    final List<dynamic> recommendations = widget.recommendations ?? [];
    final List<dynamic> genres = episodeData?['genreList'] ?? [];

    return Column(
      children: [
        Container(
          height: _isFullScreen
              ? MediaQuery.of(context).size.height
              : MediaQuery.of(context).size.height * 0.35,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              if (_streamUrl != null)
                WebViewWidget(controller: _webViewController)
              else
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text("Loading stream URL...", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              if (_isWebViewLoading)
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text("Loading video player...", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              if (!_isFullScreen && _qualities.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: PopupMenuButton<int>(
                      icon: Icon(Icons.settings, color: AnimeTheme.primaryAccent),
                      tooltip: 'Quality Settings',
                      color: AnimeTheme.card,
                      onSelected: (index) {
                        setState(() {
                          _showQualitySelector = true;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<int>(
                          value: 0,
                          child: Text('Quality Settings', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isFullScreen)
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.fullscreen_exit, color: AnimeTheme.primaryAccent, size: 30),
                    ),
                    onPressed: _exitFullScreen,
                  ),
                ),
            ],
          ),
        ),
        if (_showQualitySelector && !_isFullScreen && _qualities.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: AnimeTheme.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Select Quality", style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close, color: AnimeTheme.primaryAccent),
                      onPressed: () {
                        setState(() {
                          _showQualitySelector = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _qualities.length,
                  itemBuilder: (context, qualityIndex) {
                    final quality = _qualities[qualityIndex];
                    final qualityTitle = quality['title'] ?? '';
                    final serverList = quality['serverList'] ?? [];
                    if (serverList.isEmpty) return const SizedBox.shrink();
                    return ExpansionTile(
                      title: Text(qualityTitle, style: TextStyle(color: AnimeTheme.primaryAccent, fontWeight: FontWeight.bold)),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(left: 16),
                      backgroundColor: AnimeTheme.background,
                      collapsedBackgroundColor: AnimeTheme.background,
                      children: serverList.map<Widget>((server) {
                        final serverTitle = server['title'] ?? '';
                        final serverIndex = serverList.indexOf(server);
                        final isSelected = _selectedQualityIndex == qualityIndex && _selectedServerIndex == serverIndex;
                        return ListTile(
                          title: Text(serverTitle, style: TextStyle(color: isSelected ? AnimeTheme.primaryAccent : AnimeTheme.textGrey)),
                          trailing: isSelected ? Icon(Icons.check, color: AnimeTheme.primaryAccent) : null,
                          onTap: () {
                            _changeQuality(qualityIndex, serverIndex);
                            setState(() {
                              _showQualitySelector = false;
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        if (!_isFullScreen && !_showQualitySelector) ...[
          Container(
            height: 50,
            color: AnimeTheme.card,
            child: Row(
              children: [
                _buildTabButton(0, Icons.playlist_play, 'Episodes'),
                _buildTabButton(1, Icons.recommend, 'Recommendations'),
                _buildTabButton(2, Icons.category, 'Genres'),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildEpisodeList(episodes),
                _buildRecommendations(recommendations),
                _buildGenresList(genres),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: Material(
        color: isSelected ? AnimeTheme.primaryAccent : Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentTabIndex = index;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AnimeTheme.background : AnimeTheme.textGrey, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? AnimeTheme.background : AnimeTheme.textGrey, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeList(List<dynamic> episodes) {
    if (episodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_play, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text("No episodes available", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_currentEpisodeIndex < episodes.length - 1)
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _goToNextEpisode,
              icon: const Icon(Icons.skip_next),
              label: const Text("Next Episode"),
              style: ElevatedButton.styleFrom(backgroundColor: AnimeTheme.primaryAccent),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              final isCurrentEpisode = episode['episodeId'] == widget.episodeSlug;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrentEpisode ? AnimeTheme.primaryAccent : AnimeTheme.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCurrentEpisode ? Colors.black.withOpacity(0.2) : AnimeTheme.card,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        episode['eps'].toString(),
                        style: TextStyle(
                          color: isCurrentEpisode ? AnimeTheme.background : AnimeTheme.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    episode['title'],
                    style: TextStyle(
                      color: isCurrentEpisode ? AnimeTheme.background : AnimeTheme.primaryAccent,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    if (!isCurrentEpisode) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeEpisodePage(
                            episodeSlug: episode['episodeId'],
                            animeSlug: widget.animeSlug,
                            animeTitle: widget.animeTitle,
                            animePoster: widget.animePoster,
                            episodes: widget.episodes,
                            recommendations: widget.recommendations,
                            onHistoryUpdate: widget.onHistoryUpdate,
                          ),
                        ),
                      );
                    }
                  },
                  trailing: Icon(
                    isCurrentEpisode ? Icons.play_arrow : Icons.play_circle_outline,
                    color: isCurrentEpisode ? AnimeTheme.background : AnimeTheme.primaryAccent,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(List<dynamic> recommendations) {
    if (recommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_creation, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text("No recommendations available", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailPage(
                  slug: recommendation['animeId'],
                  onHistoryUpdate: widget.onHistoryUpdate,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  child: Image.network(
                    recommendation['poster'],
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: AnimeTheme.card,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_not_supported, color: AnimeTheme.textGrey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation['title'],
                        style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (recommendation['score'] != null && recommendation['score'].toString().isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Text(recommendation['score'], style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 10)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenresList(List<dynamic> genres) {
    if (genres.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text("No genres available", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Anime Genres", style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map<Widget>((genre) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnimeGenrePage(
                        genreSlug: genre['genreId'],
                        genreName: genre['title'],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AnimeTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(genre['title'], style: TextStyle(color: AnimeTheme.background, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (widget.animeTitle != null) ...[
            Text("Anime Info", style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AnimeTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AnimeTheme.primaryAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      widget.animePoster ?? '',
                      height: 80,
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        width: 60,
                        color: AnimeTheme.card,
                        alignment: Alignment.center,
                        child: Icon(Icons.image_not_supported, color: AnimeTheme.textGrey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.animeTitle ?? '',
                      style: TextStyle(color: AnimeTheme.primaryAccent, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Shimmer.fromColors(
            baseColor: AnimeTheme.card,
            highlightColor: AnimeTheme.primaryAccent.withOpacity(0.2),
            child: Container(color: AnimeTheme.card),
          ),
        ),
      ],
    );
  }
}