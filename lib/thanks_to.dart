import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ThanksToPage extends StatelessWidget {
  const ThanksToPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0E),
      appBar: AppBar(
        title: const Text(
          "Thanks To",
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
            decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFF000000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Header dengan animasi
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.1),
                    const Color(0xFF0D47A1).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      FontAwesomeIcons.heart,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Terima Kasih Kepada",
                    style: TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Semua Pihak yang Telah Mendukung",
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 80,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Daftar Thanks To
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildThanksCard(
                  icon: FontAwesomeIcons.github,
                  title: "Open Source Community",
                  description: "Terima kasih kepada semua kontributor open source yang telah menyediakan library dan tools yang digunakan dalam aplikasi ini.",
                  color: const Color(0xFF6e5494),
                ),
                const SizedBox(height: 12),
                _buildThanksCard(
                  icon: FontAwesomeIcons.peopleGroup,
                  title: "Tim Developer",
                  description: "Tim pengembang yang telah bekerja keras untuk menciptakan aplikasi ini dengan penuh dedikasi.",
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(height: 12),
                _buildThanksCard(
                  icon: FontAwesomeIcons.users,
                  title: "LIGHT",
                  description: "Para petinggi yang telah membantu menemukan bug dan memberikan saran berharga.",
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 12),
                _buildThanksCard(
                  icon: FontAwesomeIcons.telegram,
                  title: "Komunitas Telegram",
                  description: "Seluruh member komunitas Telegram yang selalu memberikan dukungan dan motivasi.",
                  color: const Color(0xFF0088cc),
                ),
                const SizedBox(height: 12),
                _buildThanksCard(
                  icon: FontAwesomeIcons.userAstronaut,
                  title: "AMEL",
                  description: "Creator dan penggagas proyek Xora yang telah menciptakan platform ini.",
                  color: const Color(0xFFFF9800),
                ),
                const SizedBox(height: 12),
                _buildThanksCard(
                  icon: FontAwesomeIcons.handHoldingHeart,
                  title: "Seluruh Pengguna",
                  description: "Terima kasih kepada semua pengguna yang telah mempercayai dan menggunakan aplikasi ini.",
                  color: const Color(0xFFE91E63),
                ),
              ]),
            ),
          ),

          // Footer Quote
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.05),
                    const Color(0xFF0D47A1).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: Color(0xFF2196F3),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '"Kesuksesan bukanlah milik mereka yang menyerah, tetapi milik mereka yang terus berusaha dan berdoa."',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "LIGHT",
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildThanksCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 12,
                    height: 1.4,
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