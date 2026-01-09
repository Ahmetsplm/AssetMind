import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ayarlar",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Genel"),
              _buildAboutCard(),
              const SizedBox(height: 24),
              _buildSectionHeader("Destek"),
              _buildContactButton(),
              const SizedBox(height: 48),
              _buildVersionInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF1A237E),
                size: 28,
              ),
            ),
            title: Text(
              "Hakkında",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "AssetMind, tüm yatırımlarınızı tek bir yerden takip etmenizi sağlayan kapsamlı bir portföy yönetim aracıdır. Türk Hisse Senetleri, Döviz, Altın ve Kripto paralarınızı anlık verilerle izleyin.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap: null, // Inactive as requested
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mail_outline_rounded,
            color: Colors.orange,
            size: 24,
          ),
        ),
        title: Text(
          "İletişim",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          "Geri bildirim gönder",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "Yakında",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          // App Logo could go here
          Icon(Icons.pie_chart_rounded, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "AssetMind",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          Text(
            "v1.0.0",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
