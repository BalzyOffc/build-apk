import 'package:flutter/material.dart';

// ================= 1. FUNGSI MAIN (PALING ATAS) =================
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: QuizPage(), // Langsung memanggil QuizPage
  ));
}

// ================= 2. CLASS WIDGET UTAMA =================
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Variabel State
  String? selectedCategory;
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;
  bool isAnswered = false;
  
  // State untuk menentukan tampilan: 'menu' atau 'play'
  String gameState = 'menu'; 

  // ================= DATA BANK SOAL =================
  // Ditaruh di dalam class atau luar class, bebas. Disini saya taruh data map sederhana.
  
  final Map<String, List<Map<String, dynamic>>> quizData = {
    "Matematika": [
      {
        "question": "Berapa hasil dari 15 x 4?",
        "options": ["50", "60", "70", "45"],
        "answer": 1,
      },
      {
        "question": "Akar kuadrat dari 81 adalah...",
        "options": ["7", "8", "9", "10"],
        "answer": 2,
      },
      {
        "question": "Jika x + 5 = 12, berapa nilai x?",
        "options": ["5", "6", "7", "8"],
        "answer": 2,
      },
    ],
    "IPA": [
      {
        "question": "H2O adalah rumus kimia dari?",
        "options": ["Garam", "Gula", "Air", "Minyak"],
        "answer": 2,
      },
      {
        "question": "Planet terdekat dengan Matahari adalah?",
        "options": ["Venus", "Merkurius", "Mars", "Bumi"],
        "answer": 1,
      },
    ],
    "Agama": [
      {
        "question": "Rukun Islam yang pertama adalah?",
        "options": ["Sholat", "Puasa", "Syahadat", "Zakat"],
        "answer": 2,
      },
      {
        "question": "Kitab suci umat Islam adalah?",
        "options": ["Injil", "Zabur", "Taurat", "Al-Quran"],
        "answer": 3,
      },
    ],
    "Umum": [
      {
        "question": "Ibu kota Indonesia adalah?",
        "options": ["Bandung", "Surabaya", "Jakarta", "Medan"],
        "answer": 2,
      },
      {
        "question": "Gunung tertinggi di dunia?",
        "options": ["Kilimanjaro", "Everest", "Fuji", "Kerinci"],
        "answer": 1,
      },
    ],
  };

  // ================= LOGIKA =================

  void startQuiz(String category) {
    setState(() {
      selectedCategory = category;
      currentQuestionIndex = 0;
      score = 0;
      selectedAnswerIndex = null;
      isAnswered = false;
      gameState = 'play';
    });
  }

  void checkAnswer(int selectedIndex) {
    if (isAnswered) return;

    final currentQuestions = quizData[selectedCategory]!;
    final correctIndex = currentQuestions[currentQuestionIndex]['answer'];

    setState(() {
      selectedAnswerIndex = selectedIndex;
      isAnswered = true;
    });

    if (selectedIndex == correctIndex) {
      score++;
    }

    Future.delayed(const Duration(seconds: 1), () {
      nextQuestion();
    });
  }

  void nextQuestion() {
    final totalQuestions = quizData[selectedCategory]!.length;
    if (currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
        isAnswered = false;
      });
    } else {
      // Pindah ke state hasil
      setState(() {
        gameState = 'result';
      });
    }
  }

  void goToMenu() {
    setState(() {
      gameState = 'menu';
      selectedCategory = null;
    });
  }

  // ================= BUILD UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("QUIZ MASTER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // Hilangkan back button di menu utama
      ),
      body: _buildBody(),
    );
  }

  // Mengatur tampilan berdasarkan state
  Widget _buildBody() {
    if (gameState == 'menu') {
      return _buildMenuView();
    } else if (gameState == 'play') {
      return _buildPlayView();
    } else {
      return _buildResultView();
    }
  }

  // ================= TAMPILAN MENU =================
  Widget _buildMenuView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pilih Kategori:",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
              children: quizData.keys.map((category) {
                return _buildCategoryCard(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category) {
    // Mapping ikon sederhana
    IconData icon = Icons.quiz;
    if (category == "Matematika") icon = Icons.calculate;
    if (category == "IPA") icon = Icons.science;
    if (category == "Agama") icon = Icons.menu_book;
    if (category == "Umum") icon = Icons.public;

    return InkWell(
      onTap: () => startQuiz(category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF8B0000), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              category,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "${quizData[category]!.length} Soal",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAMPILAN PLAY =================
  Widget _buildPlayView() {
    final questions = quizData[selectedCategory]!;
    final currentQ = questions[currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / questions.length,
            backgroundColor: Colors.grey[800],
            color: const Color(0xFF8B0000),
          ),
          const SizedBox(height: 30),
          Text(
            "Soal ${currentQuestionIndex + 1} dari ${questions.length}",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              currentQ['question'],
              style: const TextStyle(fontSize: 20, color: Colors.white, height: 1.4),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: 4, // Pilihan selalu 4
              itemBuilder: (context, index) {
                return _buildOptionButton(index, currentQ['options'][index], currentQ['answer']);
              },
            ),
          ),
          Center(
            child: Text("Skor Sementara: $score", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, String text, int correctIndex) {
    Color bgColor = Colors.grey[850]!;
    Color textColor = Colors.white;
    IconData? iconData;

    if (isAnswered) {
      if (index == correctIndex) {
        bgColor = const Color(0xFF8B0000); // Warna Merah Pekat untuk Benar
        textColor = Colors.white;
        iconData = Icons.check_circle;
      } else if (index == selectedAnswerIndex) {
        bgColor = Colors.grey[700]!;
        textColor = Colors.white54;
        iconData = Icons.cancel;
      }
    } else {
      bgColor = Colors.grey[850]!;
    }

    return GestureDetector(
      onTap: () => checkAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          children: [
            if (iconData != null) ...[
              Icon(iconData, color: textColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 16, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAMPILAN HASIL =================
  Widget _buildResultView() {
    double percentage = (score / quizData[selectedCategory]!.length) * 100;
    String message;

    if (percentage >= 80) {
      message = "Luar Biasa! 🏆";
    } else if (percentage >= 50) {
      message = "Bagus! 👍";
    } else {
      message = "Coba Lagi! 💪";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text("Skor Akhir Anda:", style: TextStyle(color: Colors.grey, fontSize: 18)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8B0000), width: 3),
                shape: BoxShape.circle,
              ),
              child: Text(
                "$score/${quizData[selectedCategory]!.length}",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: goToMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Kembali ke Menu", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}