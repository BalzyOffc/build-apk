import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HadisPage extends StatefulWidget {
  const HadisPage({super.key});

  @override
  State<HadisPage> createState() => _HadisPageState();
}

class _HadisPageState extends State<HadisPage> with SingleTickerProviderStateMixin {
  List<dynamic> haditsList = [];
  bool isLoading = true;
  String? errorMessage;
  int selectedCategory = 0;
  late TabController tabController;
  
  final List<String> categories = [
    "Semua Hadis",
    "Keutamaan Sholat",
    "Kejujuran",
    "Sedekah",
    "Sabar",
    "Tawakal",
    "Akhlak",
    "Ilmu",
    "Pernikahan",
    "Puasa",
    "Zakat",
    "Haji",
  ];

  // --- MODERN DARK THEME ---
  static const Color bgPrimary = Color(0xFF0A0E27);
  static const Color bgSecondary = Color(0xFF141A3A);
  static const Color cardColor = Color(0xFF1A2150);
  static const Color accentPurple = Color(0xFF9B59B6);
  static const Color accentPink = Color(0xFFE74C3C);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color accentTeal = Color(0xFF1ABC9C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B7D6);
  static const Color goldShine = Color(0xFFF1C40F);

  LinearGradient get headerGradient => const LinearGradient(
    colors: [accentPurple, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get cardGradient => LinearGradient(
    colors: [cardColor, cardColor.withOpacity(0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: categories.length, vsync: this);
    tabController.addListener(() {
      setState(() {
        selectedCategory = tabController.index;
      });
    });
    fetchHadits();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> fetchHadits() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("https://api.hadith.gading.dev/books/bukhari?range=1-100"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            haditsList = data['data']['hadiths'] ?? [];
            isLoading = false;
          });
        } else {
          loadLocalHadits();
        }
      } else {
        loadLocalHadits();
      }
    } catch (e) {
      loadLocalHadits();
    }
  }

  void loadLocalHadits() {
    setState(() {
      haditsList = getLocalHadits();
      isLoading = false;
    });
  }

  List<dynamic> getLocalHadits() {
    return [
      // Hadis Sholat (5 hadis)
      {
        "arab": "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ",
        "latin": "Innamal a'malu binniyat",
        "artinya": "Sesungguhnya amal itu tergantung pada niatnya",
        "perawi": "HR. Bukhari No. 1",
        "category": "Keutamaan Sholat",
        "penjelasan": "Hadis ini menjadi dasar pentingnya niat dalam setiap amal ibadah.",
      },
      {
        "arab": "الصَّلَاةُ عِمَادُ الدِّينِ",
        "latin": "Ash-sholatu 'imaduddin",
        "artinya": "Sholat adalah tiang agama",
        "perawi": "HR. Baihaqi",
        "category": "Keutamaan Sholat",
        "penjelasan": "Sholat merupakan pondasi utama dalam agama Islam.",
      },
      {
        "arab": "مَنْ صَلَّى الصُّبْحَ فَهُوَ فِي ذِمَّةِ اللَّهِ",
        "latin": "Man shollash shubha fahuwa fi dzimmatillah",
        "artinya": "Barangsiapa sholat subuh maka ia dalam jaminan Allah",
        "perawi": "HR. Muslim No. 657",
        "category": "Keutamaan Sholat",
        "penjelasan": "Allah memberikan jaminan khusus bagi yang sholat subuh.",
      },
      {
        "arab": "أَوَّلُ مَا يُحَاسَبُ بِهِ الْعَبْدُ صَلَاتُهُ",
        "latin": "Awwalu ma yuhasabu bihil 'abdu sholatuhu",
        "artinya": "Amal pertama yang dihisab dari seorang hamba adalah sholatnya",
        "perawi": "HR. Tirmidzi No. 413",
        "category": "Keutamaan Sholat",
        "penjelasan": "Sholat akan menjadi amal pertama yang dihisab di hari kiamat.",
      },
      {
        "arab": "صَلَاةُ الْجَمَاعَةِ تَفْضُلُ صَلَاةَ الْفَذِّ بِسَبْعٍ وَعِشْرِينَ دَرَجَةً",
        "latin": "Sholatul jama'ati tafdulu sholatal fadzi bisab'in wa 'isyirina darojatan",
        "artinya": "Sholat berjamaah lebih utama 27 derajat dari sholat sendirian",
        "perawi": "HR. Bukhari No. 645",
        "category": "Keutamaan Sholat",
        "penjelasan": "Keutamaan besar bagi yang mengerjakan sholat berjamaah.",
      },
      
      // Hadis Kejujuran (5 hadis)
      {
        "arab": "الصِّدْقُ يَهْدِي إِلَى الْبِرِّ",
        "latin": "Ash-shidqu yahdi ilal birri",
        "artinya": "Kejujuran itu membawa kepada kebaikan",
        "perawi": "HR. Bukhari No. 6094",
        "category": "Kejujuran",
        "penjelasan": "Kejujuran mengantarkan pada kebaikan dan surga.",
      },
      {
        "arab": "عَلَيْكُمْ بِالصِّدْقِ",
        "latin": "'Alaikum bish shidqi",
        "artinya": "Hendaklah kalian bersikap jujur",
        "perawi": "HR. Muslim No. 2607",
        "category": "Kejujuran",
        "penjelasan": "Perintah untuk selalu berkata jujur dalam segala situasi.",
      },
      {
        "arab": "إِيَّاكُمْ وَالْكَذِبَ",
        "latin": "Iyyakum wal kadziba",
        "artinya": "Jauhilah oleh kalian dusta",
        "perawi": "HR. Tirmidzi No. 1971",
        "category": "Kejujuran",
        "penjelasan": "Peringatan keras untuk menjauhi sifat dusta.",
      },
      {
        "arab": "الصَّادِقُ أَمِينٌ",
        "latin": "Ash shodiqu aminun",
        "artinya": "Orang yang jujur adalah orang yang terpercaya",
        "perawi": "HR. Ibnu Majah No. 3845",
        "category": "Kejujuran",
        "penjelasan": "Kejujuran membangun kepercayaan orang lain.",
      },
      {
        "arab": "الْكَذِبُ يُنْفِقُ الْإِيمَانَ",
        "latin": "Al kadzibu yunfiqul imana",
        "artinya": "Dusta itu menghilangkan iman",
        "perawi": "HR. Ahmad No. 13124",
        "category": "Kejujuran",
        "penjelasan": "Dusta dapat merusak dan menghilangkan iman seseorang.",
      },
      
      // Hadis Sedekah (5 hadis)
      {
        "arab": "الصَّدَقَةُ تُطْفِئُ الْخَطِيئَةَ",
        "latin": "Ash shodaqotu tuthfi'ul khothi'ah",
        "artinya": "Sedekah itu memadamkan dosa",
        "perawi": "HR. Tirmidzi No. 2616",
        "category": "Sedekah",
        "penjelasan": "Sedekah dapat menghapus dosa-dosa.",
      },
      {
        "arab": "أَفْضَلُ الصَّدَقَةِ صَدَقَةٌ عَنْ ظَهْرِ غِنًى",
        "latin": "Afdlolush shodaqoti shodaqotun 'an dzohri ghinan",
        "artinya": "Sedekah paling utama adalah dari orang yang masih berkecukupan",
        "perawi": "HR. Bukhari No. 1426",
        "category": "Sedekah",
        "penjelasan": "Bersedekah ketika kita masih memiliki kebutuhan.",
      },
      {
        "arab": "صَدَقَةُ السِّرِّ تُطْفِئُ غَضَبَ الرَّبِّ",
        "latin": "Shodaqotus sirri tuthfi'u ghodhobarrobbi",
        "artinya": "Sedekah rahasia memadamkan murka Allah",
        "perawi": "HR. Thabrani",
        "category": "Sedekah",
        "penjelasan": "Keutamaan bersedekah secara sembunyi-sembunyi.",
      },
      {
        "arab": "مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ",
        "latin": "Ma naqoshot shodaqotun min malin",
        "artinya": "Sedekah tidak akan mengurangi harta",
        "perawi": "HR. Muslim No. 2588",
        "category": "Sedekah",
        "penjelasan": "Harta justru akan bertambah dengan bersedekah.",
      },
      {
        "arab": "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ صَدَقَةٌ",
        "latin": "Tabassumuka fi wajhi akhika shodaqotun",
        "artinya": "Senyummu di hadapan saudaramu adalah sedekah",
        "perawi": "HR. Tirmidzi No. 1956",
        "category": "Sedekah",
        "penjelasan": "Sedekah tidak harus dengan harta, senyum pun sedekah.",
      },
      
      // Hadis Sabar (5 hadis)
      {
        "arab": "وَالصَّبْرُ ضِيَاءٌ",
        "latin": "Wash shobru dhiya'un",
        "artinya": "Dan kesabaran itu cahaya",
        "perawi": "HR. Muslim No. 223",
        "category": "Sabar",
        "penjelasan": "Sabar menerangi jalan seorang mukmin.",
      },
      {
        "arab": "إِنَّمَا يُوَفَّى الصَّابِرُونَ أَجْرَهُمْ بِغَيْرِ حِسَابٍ",
        "latin": "Innama yuwaffash shobiruna ajrohum bighoiri hisab",
        "artinya": "Sesungguhnya orang-orang yang sabar akan disempurnakan pahalanya tanpa batas",
        "perawi": "QS. Az-Zumar: 10",
        "category": "Sabar",
        "penjelasan": "Pahala orang sabar tidak terbatas.",
      },
      {
        "arab": "عَجَبًا لِأَمْرِ الْمُؤْمِنِ",
        "latin": "'Ajaban li amril mu'mini",
        "artinya": "Sungguh menakjubkan urusan orang mukmin",
        "perawi": "HR. Muslim No. 2999",
        "category": "Sabar",
        "penjelasan": "Setiap keadaan mukmin adalah baik jika bersabar.",
      },
      {
        "arab": "الصَّبْرُ مِفْتَاحُ الْفَرَجِ",
        "latin": "Ash shobru miftahul faroji",
        "artinya": "Sabar adalah kunci datangnya kelapangan",
        "perawi": "HR. Ahmad",
        "category": "Sabar",
        "penjelasan": "Kesabaran membuka jalan keluar dari kesulitan.",
      },
      {
        "arab": "وَمَنْ يَتَصَبَّرْ يُصَبِّرْهُ اللَّهُ",
        "latin": "Wa man yatashabbar yushabbirhulloh",
        "artinya": "Barangsiapa berusaha sabar, Allah akan menjadikannya sabar",
        "perawi": "HR. Bukhari No. 1469",
        "category": "Sabar",
        "penjelasan": "Allah akan memberikan kesabaran bagi yang berusaha.",
      },
      
      // Hadis Tawakal (5 hadis)
      {
        "arab": "وَتَوَكَّلْ عَلَى اللَّهِ",
        "latin": "Wa tawakkal 'alallah",
        "artinya": "Dan bertawakkallah kepada Allah",
        "perawi": "QS. Al-Ahzab: 3",
        "category": "Tawakal",
        "penjelasan": "Serahkan segala urusan kepada Allah setelah berusaha.",
      },
      {
        "arab": "لَوْ أَنَّكُمْ تَتَوَكَّلُونَ عَلَى اللَّهِ حَقَّ تَوَكُّلِهِ",
        "latin": "Law annakum tatawakkaluna 'alallahi haqqa tawakkulihi",
        "artinya": "Jika kalian benar-benar bertawakkal kepada Allah",
        "perawi": "HR. Tirmidzi No. 2344",
        "category": "Tawakal",
        "penjelasan": "Allah akan mencukupi kebutuhan orang yang bertawakkal.",
      },
      {
        "arab": "فَإِذَا عَزَمْتَ فَتَوَكَّلْ عَلَى اللَّهِ",
        "latin": "Fa idza 'azamta fatawakkal 'alallah",
        "artinya": "Apabila engkau telah membulatkan tekad, maka bertawakkallah kepada Allah",
        "perawi": "QS. Ali Imran: 159",
        "category": "Tawakal",
        "penjelasan": "Tawakal dilakukan setelah usaha dan tekad bulat.",
      },
      {
        "arab": "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ",
        "latin": "Hasbiyallahu la ilaha illa huwa",
        "artinya": "Cukuplah Allah bagiku, tidak ada Tuhan selain Dia",
        "perawi": "QS. At-Taubah: 129",
        "category": "Tawakal",
        "penjelasan": "Dzikir tawakkal yang diajarkan Al-Qur'an.",
      },
      {
        "arab": "وَمَنْ يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ",
        "latin": "Wa man yatawakkal 'alallahi fahuwa hasbuh",
        "artinya": "Barangsiapa bertawakkal kepada Allah, niscaya Allah mencukupkannya",
        "perawi": "QS. Ath-Thalaq: 3",
        "category": "Tawakal",
        "penjelasan": "Janji Allah bagi orang yang bertawakkal.",
      },
      
      // Hadis Akhlak (5 hadis)
      {
        "arab": "إِنَّمَا بُعِثْتُ لِأُتَمِّمَ مَكَارِمَ الْأَخْلَاقِ",
        "latin": "Innama bu'itstu li utammina makarimal akhlaq",
        "artinya": "Sesungguhnya aku diutus untuk menyempurnakan akhlak yang mulia",
        "perawi": "HR. Ahmad No. 8952",
        "category": "Akhlak",
        "penjelasan": "Misi utama Rasulullah adalah perbaikan akhlak.",
      },
      {
        "arab": "خَيْرُكُمْ أَحْسَنُكُمْ أَخْلَاقًا",
        "latin": "Khoirukum ahsanukum akhlaqon",
        "artinya": "Sebaik-baik kalian adalah yang paling baik akhlaknya",
        "perawi": "HR. Bukhari No. 3559",
        "category": "Akhlak",
        "penjelasan": "Akhlak mulia menjadi ukuran kebaikan seseorang.",
      },
      {
        "arab": "أَكْمَلُ الْمُؤْمِنِينَ إِيمَانًا أَحْسَنُهُمْ خُلُقًا",
        "latin": "Akmadul mu'minina imanan ahsanuhum khuluqon",
        "artinya": "Mukmin paling sempurna imannya adalah yang paling baik akhlaknya",
        "perawi": "HR. Tirmidzi No. 1162",
        "category": "Akhlak",
        "penjelasan": "Kesempurnaan iman berkaitan dengan akhlak.",
      },
      {
        "arab": "لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ",
        "latin": "Laisasy syadidu bish shuro'ah",
        "artinya": "Orang kuat bukanlah yang pandai bergulat",
        "perawi": "HR. Bukhari No. 6114",
        "category": "Akhlak",
        "penjelasan": "Orang kuat sebenarnya adalah yang bisa menahan amarah.",
      },
      {
        "arab": "اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ",
        "latin": "It taqillaha haitsuma kunta",
        "artinya": "Bertakwalah kepada Allah di manapun engkau berada",
        "perawi": "HR. Tirmidzi No. 1987",
        "category": "Akhlak",
        "penjelasan": "Selalu menjaga ketakwaan dalam setiap kondisi.",
      },
      
      // Hadis Ilmu (5 hadis)
      {
        "arab": "طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ",
        "latin": "Tholabul 'ilmi faridhotun 'ala kulli muslim",
        "artinya": "Menuntut ilmu itu wajib bagi setiap muslim",
        "perawi": "HR. Ibnu Majah No. 224",
        "category": "Ilmu",
        "penjelasan": "Kewajiban menuntut ilmu sepanjang hayat.",
      },
      {
        "arab": "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا",
        "latin": "Man salaka thoriqon yaltamisu fihi 'ilman",
        "artinya": "Barangsiapa menempuh jalan untuk mencari ilmu",
        "perawi": "HR. Muslim No. 2699",
        "category": "Ilmu",
        "penjelasan": "Allah mudahkan jalan surga bagi penuntut ilmu.",
      },
      {
        "arab": "خَيْرُ النَّاسِ أَنْفَعُهُمْ لِلنَّاسِ",
        "latin": "Khoirunnasi anfa'uhum linnasi",
        "artinya": "Sebaik-baik manusia adalah yang paling bermanfaat bagi orang lain",
        "perawi": "HR. Thabrani",
        "category": "Ilmu",
        "penjelasan": "Ilmu yang bermanfaat adalah yang diamalkan.",
      },
      {
        "arab": "الْعِلْمُ بِلاَ عَمَلٍ كَالشَّجَرِ بِلاَ ثَمَرٍ",
        "latin": "Al 'ilmu bila 'amalin kasy syajari bila tsamarin",
        "artinya": "Ilmu tanpa amal bagaikan pohon tak berbuah",
        "perawi": "HR. Ad-Dailami",
        "category": "Ilmu",
        "penjelasan": "Ilmu harus diamalkan agar bermanfaat.",
      },
      {
        "arab": "إِذَا مَاتَ الإِنْسَانُ انْقَطَعَ عَمَلُهُ إِلاَّ مِنْ ثَلاَثٍ: عِلْمٌ يُنْتَفَعُ بِهِ",
        "latin": "Idza matal insanu inqotho'a 'amaluhu illa min tsalatsin: 'ilmun yuntafa'u bihi",
        "artinya": "Jika manusia mati terputus amalnya kecuali tiga: ilmu yang bermanfaat",
        "perawi": "HR. Muslim No. 1631",
        "category": "Ilmu",
        "penjelasan": "Ilmu bermanfaat menjadi amal jariyah.",
      },
      
      // Hadis lainnya (akhlak, puasa, zakat, haji)
      {
        "arab": "لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ",
        "latin": "La yu'minu ahadukum hatta yuhibba li akhihi ma yuhibbu linafsihi",
        "artinya": "Tidak sempurna iman seseorang hingga ia mencintai saudaranya",
        "perawi": "HR. Bukhari No. 13",
        "category": "Akhlak",
        "penjelasan": "Mencintai sesama muslim seperti mencintai diri sendiri.",
      },
      {
        "arab": "الصِّيَامُ جُنَّةٌ",
        "latin": "Ash shiyamu junnah",
        "artinya": "Puasa adalah perisai",
        "perawi": "HR. Bukhari No. 1894",
        "category": "Puasa",
        "penjelasan": "Puasa melindungi dari api neraka.",
      },
      {
        "arab": "مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا",
        "latin": "Man shoma romadlona imanan wahtisaban",
        "artinya": "Barangsiapa puasa Ramadhan karena iman dan mengharap pahala",
        "perawi": "HR. Bukhari No. 38",
        "category": "Puasa",
        "penjelasan": "Puasa Ramadhan dengan iman akan diampuni dosanya.",
      },
      {
        "arab": "بُنِيَ الإِسْلاَمُ عَلَى خَمْسٍ: شَهَادَةِ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ، وَإِقَامِ الصَّلاَةِ، وَإِيتَاءِ الزَّكَاةِ، وَصَوْمِ رَمَضَانَ، وَحَجِّ الْبَيْتِ",
        "latin": "Buniyal islamu 'ala khomsin: syahadati alla ilaha illallah, wa iqomish sholati, wa i'ta'iz zakati, wa shoumi romadlona, wa hajjil baiti",
        "artinya": "Islam dibangun atas lima perkara: syahadat, sholat, zakat, puasa Ramadhan, dan haji",
        "perawi": "HR. Bukhari No. 8",
        "category": "Zakat",
        "penjelasan": "Lima rukun Islam sebagai fondasi agama.",
      },
      {
        "arab": "مَنْ حَجَّ فَلَمْ يَرْفُثْ وَلَمْ يَفْسُقْ",
        "latin": "Man hajja falam yarfuts wa lam yafsuq",
        "artinya": "Barangsiapa haji dan tidak berkata kotor serta tidak berbuat maksiat",
        "perawi": "HR. Bukhari No. 1521",
        "category": "Haji",
        "penjelasan": "Haji mabrur membersihkan dosa seperti bayi baru lahir.",
      },
    ];
  }

  List<dynamic> getFilteredHadits() {
    if (selectedCategory == 0) {
      return haditsList;
    }
    return haditsList.where((hadis) {
      return hadis['category'] == categories[selectedCategory];
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredHadits = getFilteredHadits();

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: accentPurple, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: headerGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: accentPurple.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Text(
            "📖 Kumpulan Hadis Shahih",
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            height: 45,
            decoration: BoxDecoration(
              color: bgSecondary,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: accentPurple.withOpacity(0.2)),
            ),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                gradient: headerGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: textPrimary,
              unselectedLabelColor: textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              tabs: categories.map((category) {
                return Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(category),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: headerGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentPurple.withOpacity(0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: textPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Memuat Hadis-Hadis Shahih...",
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          : filteredHadits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: headerGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: textPrimary,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Belum Ada Hadis",
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Hadis untuk kategori ini akan segera ditambahkan",
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredHadits.length,
                  itemBuilder: (context, index) {
                    final hadis = filteredHadits[index];
                    return buildHadisCard(hadis, index);
                  },
                ),
    );
  }

  Widget buildHadisCard(dynamic hadis, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentPurple.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgSecondary.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    gradient: headerGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hadis['perawi'] ?? "Hadis Shahih",
                    style: const TextStyle(
                      color: accentTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentOrange, accentOrange.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    hadis['category'] ?? "Umum",
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arabic Text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bgSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentPurple.withOpacity(0.2)),
                  ),
                  child: Text(
                    hadis['arab'] ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'serif',
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Latin Text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: accentPurple.withOpacity(0.2)),
                  ),
                  child: Text(
                    hadis['latin'] ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accentOrange,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Indonesian Translation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.translate, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            "Artinya:",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hadis['artinya'] ?? "",
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Explanation
                if (hadis['penjelasan'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: goldShine.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: goldShine.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: goldShine, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hadis['penjelasan'] ?? "",
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: bgSecondary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        "Shahih",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
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
                    color: accentPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: goldShine, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        "Muttafaq 'Alaih",
                        style: TextStyle(
                          color: goldShine,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}