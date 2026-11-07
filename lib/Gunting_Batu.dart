import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SuitPage(),
  ));
}

class SuitPage extends StatefulWidget {
  const SuitPage({super.key});

  @override
  State<SuitPage> createState() => _SuitPageState();
}

class _SuitPageState extends State<SuitPage> {
  // === VARIABEL STATE ===
  int playerScore = 0;
  int aiScore = 0;
  String playerChoice = ""; // Pilihan pemain saat ini
  String aiChoice = ""; // Pilihan AI saat ini
  String statusText = "Tekan MULAI untuk Bermain";
  
  bool isGameStarted = false; // Apakah permainan sudah dimulai
  bool isCountingDown = false; // Apakah sedang countdown
  bool canSelect = false; // Apakah pemain bisa memilih tombol
  bool showRoundResult = false; // Apakah sedang menampilkan hasil ronde
  bool isMatchOver = false; // Apakah pertandingan sudah selesai (ada yang 3 poin)
  String matchResult = ""; // Hasil akhir: "WIN" atau "LOSE"

  final List<String> choices = ['batu', 'gunting', 'kertas'];
  final Random random = Random();

  // === LOGIKA GAME ===

  // 1. Memulai Pertandingan Baru
  void startMatch() {
    setState(() {
      playerScore = 0;
      aiScore = 0;
      isMatchOver = false;
      matchResult = "";
      playerChoice = "";
      aiChoice = "";
    });
    startCountdown();
  }

  // 2. Proses Hitungan Mundur (3, 2, 1, MULAI)
  void startCountdown() async {
    setState(() {
      isCountingDown = true;
      canSelect = false;
      showRoundResult = false;
      statusText = "Bersiap...";
    });

    // Loop 3, 2, 1
    for (int i = 3; i > 0; i--) {
      setState(() {
        statusText = i.toString();
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    // Tampilkan MULAI
    setState(() {
      statusText = "MULAI!";
    });
    await Future.delayed(const Duration(milliseconds: 600));

    // Masuk ke mode pilih
    setState(() {
      isCountingDown = false;
      isGameStarted = true;
      canSelect = true;
      statusText = "Pilih Senjata!";
    });
  }

  // 3. Saat Pemain Memilih (Batu/Gunting/Kertas)
  void onPlayerSelect(String choice) async {
    if (!canSelect) return; // Cegah input jika tidak boleh

    // Set pilihan pemain
    setState(() {
      playerChoice = choice;
      canSelect = false; // Hentikan input sementara
      statusText = "Lawan Memilih...";
    });

    // Simulasi AI berpikir
    await Future.delayed(const Duration(milliseconds: 800));

    // AI Memilih Acak
    String aiPicked = choices[random.nextInt(3)];
    
    // Tentukan Pemenang Ronde
    String roundResult = determineWinner(choice, aiPicked);

    setState(() {
      aiChoice = aiPicked;
      showRoundResult = true;
    });

    // Update Skor
    if (roundResult == "win") {
      playerScore++;
      statusText = "Kamu Menang!";
    } else if (roundResult == "lose") {
      aiScore++;
      statusText = "Kamu Kalah!";
    } else {
      statusText = "Seri!";
    }

    // Delay sebelum cek skor total
    await Future.delayed(const Duration(seconds: 1));

    // Cek Apakah Sudah Ada yang 3 Poin
    if (playerScore == 3) {
      endMatch("WIN");
    } else if (aiScore == 3) {
      endMatch("LOSE");
    } else {
      // Lanjut Ronde Berikutnya
      setState(() {
        showRoundResult = false;
        playerChoice = "";
        aiChoice = "";
        statusText = "Ronde Selanjutnya...";
      });
      await Future.delayed(const Duration(milliseconds: 500));
      startCountdown();
    }
  }

  // Logika Menentukan Pemenang Ronde
  String determineWinner(String p, String a) {
    if (p == a) return "draw";
    if ((p == 'batu' && a == 'gunting') ||
        (p == 'gunting' && a == 'kertas') ||
        (p == 'kertas' && a == 'batu')) {
      return "win";
    }
    return "lose";
  }

  // Akhiri Pertandingan
  void endMatch(String result) {
    setState(() {
      isMatchOver = true;
      isGameStarted = false;
      canSelect = false;
      matchResult = result;
    });
  }

  // === UI WIDGETS ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF800000), // Warna Merah Pekat
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                _buildScoreBoard(),
                _buildArena(),
                _buildControls(),
              ],
            ),
            // Tampilkan Overlay Notifikasi jika Match Over
            if (isMatchOver) _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  // Widget Papan Skor
  Widget _buildScoreBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skor Pemain
          Column(
            children: [
              const Text("PLAYER", style: TextStyle(color: Colors.white70, fontSize: 14)),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Text('$playerScore', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
              ),
              const Text("Target: 3", style: TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
          
          // VS Text
          const Text("VS", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          
          // Skor AI
          Column(
            children: [
              const Text("AI", style: TextStyle(color: Colors.white70, fontSize: 14)),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red[900],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text('$aiScore', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const Text("Target: 3", style: TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Arena Tengah
  Widget _buildArena() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status Text (Countdown atau Hasil)
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 32, 
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black38, blurRadius: 5)],
            ),
          ),
          
          const SizedBox(height: 30),

          // Tampilan Pilihan (Jika sudah memilih)
          if (showRoundResult || (isGameStarted && !canSelect && playerChoice.isNotEmpty))
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChoiceCard("Kamu", playerChoice),
                const Text("⚔️", style: TextStyle(fontSize: 30, color: Colors.white)),
                _buildChoiceCard("AI", aiChoice),
              ],
            ),
        ],
      ),
    );
  }

  // Widget Kartu Pilihan (Batu/Gunting/Kertas)
  Widget _buildChoiceCard(String label, String choice) {
    IconData icon;
    if (choice == 'batu') icon = Icons.panorama_fish_eye;
    else if (choice == 'gunting') icon = Icons.content_cut;
    else if (choice == 'kertas') icon = Icons.description;
    else icon = Icons.help_outline; // Placeholder

    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: label == "AI" ? Colors.redAccent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
            ],
          ),
          child: Icon(icon, size: 50, color: label == "AI" ? Colors.white : Colors.red[800]),
        ),
        const SizedBox(height: 5),
        Text(choice.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Widget Tombol Kontrol (Bawah)
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          // Jika Permainan Belum Mulai -> Tombol MULAI
          if (!isGameStarted && !isCountingDown && !isMatchOver)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red[800],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: startMatch,
                child: const Text("MULAI GAME", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),

          // Jika Sedang Bermain -> Tombol Pilihan
          if (canSelect)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: choices.map((choice) {
                return _buildSelectButton(choice);
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Widget Tombol Pilihan (Batu, Gunting, Kertas)
  Widget _buildSelectButton(String choice) {
    IconData icon;
    if (choice == 'batu') icon = Icons.panorama_fish_eye;
    else if (choice == 'gunting') icon = Icons.content_cut;
    else icon = Icons.description;

    return GestureDetector(
      onTap: () => onPlayerSelect(choice),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, size: 40, color: Colors.red[800]),
      ),
    );
  }

  // Widget Overlay Notifikasi Menang/Kalah
  Widget _buildGameOverOverlay() {
    bool isWin = matchResult == "WIN";
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.85),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Besar
          Icon(
            isWin ? Icons.emoji_events : Icons.close,
            size: 120,
            color: isWin ? Colors.yellow[400] : Colors.red[400],
          ),
          const SizedBox(height: 20),
          
          // Teks Hasil
          Text(
            isWin ? "YOU WIN 🏆" : "LOSE ❗",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isWin ? Colors.yellow[100] : Colors.red[300],
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 10),
          Text(
            "Skor Akhir: $playerScore - $aiScore",
            style: const TextStyle(fontSize: 20, color: Colors.white70),
          ),

          const SizedBox(height: 40),
          
          // Tombol Main Lagi
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[800],
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: startMatch,
            child: const Text("MAIN LAGI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}