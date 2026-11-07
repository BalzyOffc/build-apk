import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class SlotMachineTools extends StatefulWidget {
  const SlotMachineTools({super.key});

  @override
  State<SlotMachineTools> createState() => _SlotMachineToolsState();
}

class _SlotMachineToolsState extends State<SlotMachineTools>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final List<String> _icons = ["🍒", "🍊", "🍋", "🍉", "⭐", "💎", "7️⃣", "🎰"];

  String _reel1 = "🎰";
  String _reel2 = "🎰";
  String _reel3 = "🎰";

  int _score = 100;
  int _bet = 10;
  bool _isSpinning = false;
  String _resultMessage = "Tekan SPIN untuk mulai!";

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  final Color bgDark = const Color(0xFF1A0B2E);
  final Color surfaceColor = const Color(0xFF2D1B4E);
  final Color cardColor = const Color(0xFF3D2A5E);
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color accentPurple = const Color(0xFF9C27B0);
  final Color lightPurple = const Color(0xFFCE93D8);
  final Color goldAccent = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;
    if (_score < _bet) {
      setState(() {
        _resultMessage = "❌ Saldo tidak cukup! Ambil koin gratis!";
      });
      return;
    }

    setState(() {
      _isSpinning = true;
      _resultMessage = "🔄 Memutar...";
      _score -= _bet;
    });

    int spinCount = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (spinCount >= 15) {
        timer.cancel();
        _stopSpin();
      } else {
        setState(() {
          _reel1 = _icons[_random.nextInt(_icons.length)];
          _reel2 = _icons[_random.nextInt(_icons.length)];
          _reel3 = _icons[_random.nextInt(_icons.length)];
        });
        spinCount++;
      }
    });
  }

  void _stopSpin() {
    final int winAmount = _calculateWin();

    setState(() {
      _isSpinning = false;

      if (winAmount > 0) {
        _score += winAmount;
        _resultMessage = "🎉 MENANG! +$winAmount koin! 🎉";
        _animationController.forward().then((_) => _animationController.reset());
      } else if (_reel1 == _reel2 && _reel2 == _reel3) {
        _score += _bet * 5;
        _resultMessage = "✨ JACKPOT! +${_bet * 5} koin! ✨";
        _animationController.forward().then((_) => _animationController.reset());
      } else {
        _resultMessage = "😢 Coba lagi!";
      }
    });
  }

  int _calculateWin() {
    if (_reel1 == "7️⃣" && _reel2 == "7️⃣" && _reel3 == "7️⃣") {
      return _bet * 10;
    }
    if (_reel1 == "💎" && _reel2 == "💎" && _reel3 == "💎") {
      return _bet * 8;
    }
    if (_reel1 == "⭐" && _reel2 == "⭐" && _reel3 == "⭐") {
      return _bet * 6;
    }
    if (_reel1 == _reel2 && _reel2 == _reel3) {
      return _bet * 3;
    }
    if (_reel1 == _reel2 || _reel2 == _reel3 || _reel1 == _reel3) {
      return _bet * 1;
    }
    return 0;
  }

  void _changeBet(int amount) {
    if (_isSpinning) return;
    int newBet = _bet + amount;
    if (newBet >= 5 && newBet <= 50) {
      setState(() {
        _bet = newBet;
      });
    }
  }

  void _takeFreeCoins() {
    if (_isSpinning) return;
    setState(() {
      _score += 50;
      _resultMessage = "🎁 +50 koin gratis! 🎁";
    });
  }

  void _resetGame() {
    if (_isSpinning) return;
    setState(() {
      _score = 100;
      _bet = 10;
      _reel1 = "🎰";
      _reel2 = "🎰";
      _reel3 = "🎰";
      _resultMessage = "Game direset!";
    });
  }

  void _shareScore() {
    final message = "🎰 *SLOT MACHINE SCORE* 🎰\n\n"
        "💰 Koin: $_score\n"
        "🎲 Bet: $_bet\n"
        "🎯 Hasil: $_reel1 $_reel2 $_reel3\n"
        "📊 Status: $_resultMessage\n\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "✨ Main slot seru tanpa judi! ✨";

    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          "Slot Machine",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        backgroundColor: primaryPurple,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFFFD700)),
            onPressed: _shareScore,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryPurple, accentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.casino,
                    color: Color(0xFFFFD700),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "SLOT MACHINE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "$_score",
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_play, color: Color(0xFFFFD700), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "$_bet",
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: accentPurple.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildReel(_reel1),
                          _buildReel(_reel2),
                          _buildReel(_reel3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSpinning ? null : _spin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSpinning
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                "SPIN",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _changeBet(-5),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: lightPurple),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "- BET",
                              style: TextStyle(color: Color(0xFFCE93D8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _takeFreeCoins,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "FREE COINS",
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _changeBet(5),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: lightPurple),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "+ BET",
                              style: TextStyle(color: Color(0xFFCE93D8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentPurple.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _resultMessage.contains("MENANG") || _resultMessage.contains("JACKPOT")
                                ? Icons.emoji_events
                                : _resultMessage.contains("Coba")
                                    ? Icons.sentiment_dissatisfied
                                    : Icons.info_outline,
                            color: _resultMessage.contains("MENANG") || _resultMessage.contains("JACKPOT")
                                ? goldAccent
                                : lightPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _resultMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
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
          ],
        ),
      ),
    );
  }

  Widget _buildReel(String icon) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: goldAccent.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Text(
          icon,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }
}

class LudoKingTools extends StatefulWidget {
  const LudoKingTools({super.key});

  @override
  State<LudoKingTools> createState() => _LudoKingToolsState();
}

class _LudoKingToolsState extends State<LudoKingTools> {
  final Random _random = Random();
  int _diceValue = 1;
  int _playerScore = 0;
  int _computerScore = 0;
  bool _isRolling = false;
  String _result = "";

  final List<String> _players = ["Player 1", "Player 2", "Player 3", "Player 4"];
  int _currentPlayer = 0;
  final Map<int, int> _playerPositions = {0: 0, 1: 0, 2: 0, 3: 0};
  String _gameMessage = "Tap dadu untuk mulai!";

  final Color bgDark = const Color(0xFF1A0B2E);
  final Color surfaceColor = const Color(0xFF2D1B4E);
  final Color cardColor = const Color(0xFF3D2A5E);
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color accentPurple = const Color(0xFF9C27B0);
  final Color lightPurple = const Color(0xFFCE93D8);
  final Color goldAccent = const Color(0xFFFFD700);

  final List<Color> _playerColors = [
    const Color(0xFFE91E63),
    const Color(0xFF4CAF50),
    const Color(0xFFFF9800),
    const Color(0xFF2196F3),
  ];

  void _rollDice() {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
      _result = "";
    });

    int rollCount = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (rollCount >= 10) {
        timer.cancel();
        final int value = _random.nextInt(6) + 1;
        setState(() {
          _diceValue = value;
          _isRolling = false;
          _processTurn(value);
        });
      } else {
        setState(() {
          _diceValue = _random.nextInt(6) + 1;
        });
        rollCount++;
      }
    });
  }

  void _processTurn(int diceValue) {
    final int currentPos = _playerPositions[_currentPlayer]!;
    int newPos = currentPos + diceValue;

    if (newPos > 57) {
      setState(() {
        _gameMessage = "${_players[_currentPlayer]} butuh angka pas!";
        _nextPlayer();
      });
      return;
    }

    _playerPositions[_currentPlayer] = newPos;
    _playerScore += diceValue;

    if (newPos == 57) {
      setState(() {
        _result = "🎉 ${_players[_currentPlayer]} MENANG! 🎉";
        _gameMessage = "Selamat! ${_players[_currentPlayer]} memenangkan permainan!";
        _playerScore = 0;
        _computerScore = 0;
        for (int i = 0; i < _players.length; i++) {
          _playerPositions[i] = 0;
        }
        _currentPlayer = 0;
      });
      return;
    }

    if (diceValue == 6) {
      setState(() {
        _gameMessage = "${_players[_currentPlayer]} dapat giliran lagi!";
      });
    } else {
      _nextPlayer();
    }
  }

  void _nextPlayer() {
    setState(() {
      _currentPlayer = (_currentPlayer + 1) % _players.length;
      _gameMessage = "Giliran ${_players[_currentPlayer]}";
    });
  }

  void _resetGame() {
    setState(() {
      _diceValue = 1;
      _playerScore = 0;
      _computerScore = 0;
      _currentPlayer = 0;
      _result = "";
      _gameMessage = "Game direset! Giliran Player 1";
      for (int i = 0; i < _players.length; i++) {
        _playerPositions[i] = 0;
      }
    });
  }

  void _shareGame() {
    final message = "🎲 *LUDO KING TOOLS* 🎲\n\n"
        "Player: ${_players[_currentPlayer]}\n"
        "Dadu terakhir: $_diceValue\n"
        "Score Player: $_playerScore\n"
        "Status: ${_result.isNotEmpty ? _result : "Sedang bermain"}\n\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "✨ Ayo main Ludo King! ✨";

    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          "Ludo King Tools",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        backgroundColor: primaryPurple,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFFFD700)),
            onPressed: _shareGame,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryPurple, accentPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.casino,
                  color: Color(0xFFFFD700),
                  size: 40,
                ),
                const SizedBox(height: 4),
                const Text(
                  "LUDO KING",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _gameMessage,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: goldAccent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "$_diceValue",
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRolling ? null : _rollDice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isRolling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "GULIR DADU",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _players.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _currentPlayer == index ? cardColor : surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _currentPlayer == index
                                  ? goldAccent
                                  : accentPurple.withOpacity(0.3),
                              width: _currentPlayer == index ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _playerColors[index],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _players[index],
                                      style: TextStyle(
                                        color: _currentPlayer == index ? goldAccent : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: _playerPositions[index]! / 57,
                                      backgroundColor: Colors.grey.shade800,
                                      color: _playerColors[index],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _playerColors[index].withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${_playerPositions[index]}/57",
                                  style: TextStyle(
                                    color: _playerColors[index],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (_result.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: goldAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: goldAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _result,
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}
