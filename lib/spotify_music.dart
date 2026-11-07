import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SpotifyMusicPage extends StatefulWidget {
  const SpotifyMusicPage({super.key});

  @override
  State<SpotifyMusicPage> createState() => _SpotifyMusicPageState();
}

class _SpotifyMusicPageState extends State<SpotifyMusicPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  int _currentSongIndex = 0;
  bool _isRepeat = false;
  bool _isShuffle = false;
  bool _isLoading = false;

  // Daftar lagu yang diperbarui (Total: 19 Lagu)
  final List<Map<String, dynamic>> _playlist = [
    {
      'title': 'Beauty And A Beat',
      'artist': 'Justin Bieber ft. Nicki Minaj',
      'album': 'Believe',
      'duration': '3:48',
      'url': 'https://unable-aqua-fowna6zjld.edgeone.app/Beauty%20And%20A%20Beat_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/54a94dea-3226-44d9-ba84-2e605e7740c0.jpg',
      'year': '2012',
    },
    {
      'title': '8 Letters',
      'artist': 'Why Don\'t We',
      'album': '8 Letters',
      'duration': '3:11',
      'url': 'https://joyous-silver-c1ybquxot8.edgeone.app/8%20Letters_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/979e518a-3f87-4904-ac1f-95063ad2482b.jpg',
      'year': '2018',
    },
    {
      'title': 'Sampai Akhir Waktu',
      'artist': 'Yovie & Nuno',
      'album': 'The Special One',
      'duration': '4:28',
      'url': 'https://structural-pink-0swkuwj4ab.edgeone.app/Sampai%20Akhir%20Waktu_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/564a6cf7-a249-47f4-829d-edb00f63675e.jpg',
      'year': '2007',
    },
    {
      'title': 'Cinta Sejati',
      'artist': 'Bunga Citra Lestari',
      'album': 'Hit Singles',
      'duration': '4:15',
      'url': 'https://hostile-red-yl2z0ssk0f.edgeone.app/Cinta%20Sejati_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/0a45faf5-de1f-4f7c-a86e-7e92e6fa40bd.jpg',
      'year': '2013',
    },
    {
      'title': 'Sayang',
      'artist': 'Via Vallen',
      'album': 'Sayang',
      'duration': '5:04',
      'url': 'https://hostile-red-yl2z0ssk0f.edgeone.app/Sayang_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/1ebadf89-b47a-4afb-9fd0-2133c9e11063.jpg',
      'year': '2017',
    },
    {
      'title': 'Middle',
      'artist': 'DJ Snake ft. Bipolar Sunshine',
      'album': 'Encore',
      'duration': '3:40',
      'url': 'https://unable-aqua-fowna6zjld.edgeone.app/Middle_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/54a94dea-3226-44d9-ba84-2e605e7740c0.jpg',
      'year': '2016',
    },
    {
      'title': 'Be Me',
      'artist': 'Justin Bieber',
      'album': 'Changes (Deluxe)',
      'duration': '3:24',
      'url': 'https://unable-aqua-fowna6zjld.edgeone.app/Be%20Me_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/54a94dea-3226-44d9-ba84-2e605e7740c0.jpg',
      'year': '2020',
    },
    {
      'title': 'Hold Me Down',
      'artist': 'Halsey',
      'album': 'Badlands',
      'duration': '3:24',
      'url': 'https://joyous-silver-c1ybquxot8.edgeone.app/Hold%20Me%20Down_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/979e518a-3f87-4904-ac1f-95063ad2482b.jpg',
      'year': '2015',
    },
    {
      'title': 'Nights',
      'artist': 'Frank Ocean',
      'album': 'Blonde',
      'duration': '5:07',
      'url': 'https://structural-pink-0swkuwj4ab.edgeone.app/Nights_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/564a6cf7-a249-47f4-829d-edb00f63675e.jpg',
      'year': '2016',
    },
    {
      'title': 'The Visitor',
      'artist': 'The Black Keys',
      'album': 'Dropout Boogie',
      'duration': '3:00',
      'url': 'https://hostile-red-yl2z0ssk0f.edgeone.app/The%20Visitor_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/0a45faf5-de1f-4f7c-a86e-7e92e6fa40bd.jpg',
      'year': '2022',
    },
    {
      'title': 'Self Aware',
      'artist': 'Q',
      'album': 'The Soul, Tears to Ecstasy',
      'duration': '3:18',
      'url': 'https://hostile-red-yl2z0ssk0f.edgeone.app/Self%20Aware_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/1ebadf89-b47a-4afb-9fd0-2133c9e11063.jpg',
      'year': '2023',
    },
    {
      'title': 'Not You Too',
      'artist': 'Drake ft. Chris Brown',
      'album': 'Dark Lane Demo Tapes',
      'duration': '4:29',
      'url': 'https://unable-aqua-fowna6zjld.edgeone.app/Not%20You%20Too_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/54a94dea-3226-44d9-ba84-2e605e7740c0.jpg',
      'year': '2020',
    },
    {
      'title': 'with you tonight',
      'artist': 'Chinx',
      'album': 'Welcome to JFK',
      'duration': '3:42',
      'url': 'https://joyous-silver-c1ybquxot8.edgeone.app/with%20you%20tonight_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/979e518a-3f87-4904-ac1f-95063ad2482b.jpg',
      'year': '2015',
    },
    {
      'title': 'Stand by Me (Remastered)',
      'artist': 'Ben E. King',
      'album': 'Don\'t Play That Song!',
      'duration': '2:57',
      'url': 'https://structural-pink-0swkuwj4ab.edgeone.app/Stand%20by%20Me_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/564a6cf7-a249-47f4-829d-edb00f63675e.jpg',
      'year': '1961',
    },
    {
      'title': 'See You Again',
      'artist': 'Wiz Khalifa ft. Charlie Puth',
      'album': 'Furious 7 Soundtrack',
      'duration': '3:49',
      'url': 'https://hostile-red-yl2z0ssk0f.edgeone.app/See%20You%20Again_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/0a45faf5-de1f-4f7c-a86e-7e92e6fa40bd.jpg',
      'year': '2015',
    },
    {
      'title': 'Mind Over Matter',
      'artist': 'Young the Giant',
      'album': 'Mind over Matter',
      'duration': '4:04',
      'url': 'https://hostile-red-yl2z0ssk0f.edgeone.app/Mind%20Over%20Matter_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/1ebadf89-b47a-4afb-9fd0-2133c9e11063.jpg',
      'year': '2014',
    },
    {
      'title': 'nuts',
      'artist': 'Lil Peep',
      'album': 'Live Forever',
      'duration': '1:25',
      'url': 'https://unable-aqua-fowna6zjld.edgeone.app/nuts_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/54a94dea-3226-44d9-ba84-2e605e7740c0.jpg',
      'year': '2015',
    },
    {
      'title': 'Shut up My Moms Calling',
      'artist': 'Hotel Ugly',
      'album': 'Shut up My Moms Calling - Single',
      'duration': '2:44',
      'url': 'https://joyous-silver-c1ybquxot8.edgeone.app/Shut%20up%20My%20Moms%20Calling_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/979e518a-3f87-4904-ac1f-95063ad2482b.jpg',
      'year': '2020',
    },
    {
      'title': 'When I Was Your Man',
      'artist': 'Bruno Mars',
      'album': 'Unorthodox Jukebox',
      'duration': '3:33',
      'url': 'https://structural-pink-0swkuwj4ab.edgeone.app/When%20I%20Was%20Your%20Man_spotdown.org.mp3',
      'coverUrl': 'https://i.supaimg.com/f15077c4-6d5d-4ac0-87bf-9186d4cdfa87/564a6cf7-a249-47f4-829d-edb00f63675e.jpg',
      'year': '2012',
    }
  ];

  // Warna tema MERAH
  static const Color _accentRed = Color(0xFF00E5FF);
  static const Color _darkRed = Color(0xFF006064);
  static const Color _softRed = Color(0xFF80DEEA);
  static const Color _darkBg = Color(0xFF0B0E14);
  static const Color _darkCard = Color(0xFF151A26);
  static const Color _textWhite = Color(0xFFFFFFFF);
  static const Color _textGrey = Color(0xFF8A99AD);
  static const Color _textDarkGrey = Color(0xFF475569);

  LinearGradient get _primaryGradient => const LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        if (_isRepeat) {
          _playSong(_currentSongIndex);
        } else if (_isShuffle) {
          _playRandomSong();
        } else if (_currentSongIndex < _playlist.length - 1) {
          _playNextSong();
        } else {
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
          });
        }
      }
    });
  }

  Future<void> _playSong(int index) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isPlaying = false;
      });
    }
    
    try {
      await _audioPlayer.stop();
      _currentPosition = Duration.zero;
      
      await _audioPlayer.play(UrlSource(_playlist[index]['url']));
      
      if (mounted) {
        setState(() {
          _currentSongIndex = index;
          _isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error playing song: $e");
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isLoading = false;
        });
        _showErrorSnackbar();
      }
    }
  }

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gagal memutar lagu. Periksa koneksi internet Anda.'),
        backgroundColor: _accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _playRandomSong() {
    int newIndex;
    do {
      newIndex = (DateTime.now().millisecondsSinceEpoch % _playlist.length).toInt();
    } while (newIndex == _currentSongIndex && _playlist.length > 1);
    _playSong(newIndex);
  }

  void _playNextSong() {
    if (_currentSongIndex < _playlist.length - 1) {
      _playSong(_currentSongIndex + 1);
    } else {
      _playSong(0);
    }
  }

  void _playPreviousSong() {
    if (_currentPosition.inSeconds > 3) {
      _audioPlayer.seek(Duration.zero);
    } else {
      if (_currentSongIndex > 0) {
        _playSong(_currentSongIndex - 1);
      } else {
        _playSong(_playlist.length - 1);
      }
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      if (_currentPosition == Duration.zero && _totalDuration == Duration.zero) {
        _playSong(_currentSongIndex);
      } else {
        _audioPlayer.resume();
        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }
      }
    }
  }

  void _seekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = _playlist[_currentSongIndex];
    
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                FontAwesomeIcons.music,
                color: _accentRed,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "XØRA ENGINE Music",
              style: TextStyle(
                color: _textWhite,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _primaryGradient,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Album Art dengan loading indicator
                  Container(
                    margin: const EdgeInsets.all(24),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Hero(
                          tag: 'album_art',
                          child: Container(
                            width: MediaQuery.of(context).size.width - 80,
                            height: MediaQuery.of(context).size.width - 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentRed.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                currentSong['coverUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: _primaryGradient,
                                    ),
                                    child: const Icon(
                                      FontAwesomeIcons.music,
                                      color: _textWhite,
                                      size: 80,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (_isLoading)
                          Container(
                            width: MediaQuery.of(context).size.width - 80,
                            height: MediaQuery.of(context).size.width - 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: _accentRed,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Song Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          currentSong['title'],
                          style: const TextStyle(
                            color: _textWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentSong['artist'],
                          style: const TextStyle(
                            color: _textGrey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentSong['album']} • ${currentSong['year']}',
                          style: const TextStyle(
                            color: _textDarkGrey,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: _accentRed,
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                            thumbColor: _accentRed,
                            overlayColor: _accentRed.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _currentPosition.inSeconds.toDouble(),
                            max: _totalDuration.inSeconds.toDouble(),
                            onChanged: (value) {
                              _seekTo(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_currentPosition),
                                style: const TextStyle(
                                  color: _textGrey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(_totalDuration),
                                style: const TextStyle(
                                  color: _textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Playback Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Shuffle Button
                        IconButton(
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: _isShuffle ? _accentRed : _textGrey,
                            size: 24,
                          ),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _isShuffle = !_isShuffle;
                                if (_isShuffle) _isRepeat = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),

                        // Previous Button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, color: _textWhite, size: 32),
                            onPressed: _playPreviousSong,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Play/Pause Button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: _accentRed.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: _textWhite,
                              size: 40,
                            ),
                            onPressed: _togglePlayPause,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Next Button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.skip_next_rounded, color: _textWhite, size: 32),
                            onPressed: _playNextSong,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Repeat Button
                        IconButton(
                          icon: Icon(
                            Icons.repeat_rounded,
                            color: _isRepeat ? _accentRed : _textGrey,
                            size: 24,
                          ),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _isRepeat = !_isRepeat;
                                if (_isRepeat) _isShuffle = false;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Playlist Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: _primaryGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "PLAYLIST",
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Playlist Items
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _playlist.length,
                    itemBuilder: (context, index) {
                      final song = _playlist[index];
                      final isCurrentSong = index == _currentSongIndex;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentSong 
                              ? _accentRed.withOpacity(0.15)
                              : _darkCard.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentSong
                                ? _accentRed.withOpacity(0.3)
                                : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(song['coverUrl']),
                                fit: BoxFit.cover,
                              ),
                              color: _accentRed.withOpacity(0.1),
                            ),
                            child: isCurrentSong && _isPlaying
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.equalizer_rounded,
                                      color: _accentRed,
                                      size: 20,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            song['title'],
                            style: TextStyle(
                              color: isCurrentSong ? _accentRed : _textWhite,
                              fontWeight: isCurrentSong ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            song['artist'],
                            style: const TextStyle(
                              color: _textGrey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            song['duration'],
                            style: const TextStyle(
                              color: _textGrey,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            if (!_isLoading) {
                              _playSong(index);
                            }
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}