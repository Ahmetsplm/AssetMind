import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../providers/theme_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/favorite_provider.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/asset_service.dart';
import '../providers/auth_provider.dart';
import 'settings/alerts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  final DataService _dataService = DataService(); // New instance
  bool _isLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadLockState();
  }

  Future<void> _loadLockState() async {
    final enabled = await _auth.isLockEnabled();
    if (mounted) setState(() => _isLockEnabled = enabled);
  }

  Future<void> _toggleLock(bool value) async {
    // Check hardware support first
    if (value) {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cihazınızda biyometrik doğrulama desteklenmiyor."),
            ),
          );
        }
        return;
      }
    }

    // Verify identity before changing setting
    final authenticated = await _auth.authenticate();
    if (authenticated) {
      await _auth.setLockEnabled(value);
      if (mounted) setState(() => _isLockEnabled = value);
    }
  }

  Future<void> _exportDataToCSV() async {
    try {
      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      final holdings = provider.holdings;
      final txs = provider.allTransactions;

      final holdingMap = {for (var h in holdings) h.id: h.symbol};

      StringBuffer csv = StringBuffer();
      // Section 1: Portfolio Status
      csv.writeln("--- MEVCUT PORTFOY DURUMU ---");
      csv.writeln("Sembol;Miktar;Ortalama Maliyet;Toplam Maliyet");
      for (var h in holdings) {
        if (h.quantity > 0) {
          csv.writeln("${h.symbol};${h.quantity};${h.averageCost.toStringAsFixed(2)};${(h.quantity * h.averageCost).toStringAsFixed(2)}");
        }
      }
      csv.writeln("");

      // Section 2: Transactions
      csv.writeln("--- ISLEM GECMISI ---");
      csv.writeln("Tarih;Sembol;Islem Tipi;Miktar;Fiyat;Toplam Tutar");
      for (var t in txs) {
        final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(t.date);
        final symbol = holdingMap[t.holdingId] ?? "Bilinmiyor";
        final typeStr = t.type.name == 'BUY' ? 'ALIM' : 'SATIM';
        final total = (t.amount * t.price).toStringAsFixed(2);
        csv.writeln("$dateStr;$symbol;$typeStr;${t.amount};${t.price.toStringAsFixed(2)};$total");
      }

      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/assetmind_rapor_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv";
      final file = File(path);
      await file.writeAsString(csv.toString());

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(path)],
          text: 'AssetMind Portföy Raporu',
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dışa aktarma başarısız: $e')),
        );
      }
    }
  }

  Future<void> _resetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sıfırla'),
        content: const Text(
          'DİKKAT: Bu işlem buluttaki (Supabase) ve cihazınızdaki tüm portföy, işlem ve favori verilerinizi KALICI olarak silecektir. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Evet, Her Şeyi Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_isLockEnabled) {
        final authenticated = await _auth.authenticate();
        if (!authenticated) return;
      }

      final assetService = AssetService();
      await assetService.wipeAllUserData(); // Supabase Clear
      await _dataService.clearAllData();    // Local SQLite Clear

      if (mounted) {
        await Provider.of<PortfolioProvider>(
          context,
          listen: false,
        ).loadPortfolios();
        await Provider.of<FavoriteProvider>(
          context,
          listen: false,
        ).clearFavorites();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm verileriniz başarıyla sıfırlandı.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Güvenlik"),
              _buildSecurityCard(context),
              const SizedBox(height: 24), // New Section
              _buildSectionHeader(context, "Veri Yönetimi"),
              _buildDataManagementCard(context),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Genel"),
              _buildAboutCard(context),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Görünüm"),
              _buildAppearanceCard(context),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Destek"),
              _buildAlertsButton(context),
              const SizedBox(height: 12),
              _buildContactButton(context),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Hesap"),
              _buildAccountCard(context),
              const SizedBox(height: 48),
              _buildVersionInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataManagementCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.file_download_outlined,
                color: Colors.green,
                size: 24,
              ),
            ),
            title: Text(
              "Dışa Aktar (CSV/Excel)",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              "İşlem geçmişinizi ve portföy durumunu indirin",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            onTap: _exportDataToCSV,
          ),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            height: 1,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            title: Text(
              "Tüm Verileri Sıfırla",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            subtitle: Text(
              "Bulut ve cihazınızdaki tüm kayıtları silin",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            onTap: _resetData,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            title: Text(
              "Uygulama Kilidi",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Giriş için biyometrik doğrulama iste",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
            trailing: Switch.adaptive(
              value: _isLockEnabled,
              onChanged: _toggleLock,
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            title: Text(
              "Hakkında",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "AssetMind; Türk Hisse Senetleri, Döviz, Altın ve Kripto paralarınızı tek bir yerden takip etmenizi sağlar.\n\n⚠️ Veri Politikası:\n• Kripto paralar anlık (canlı) verilerdir.\n• Borsa İstanbul, Altın ve Döviz verileri 15 dakika gecikmelidir.\n\nUygulama içerisindeki veriler bilgilendirme amaçlıdır, yatırım tavsiyesi değildir.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              "Tema",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              underline: const SizedBox(),
              dropdownColor: Theme.of(context).cardColor,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: Theme.of(context).primaryColor,
              ),
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(
                    "Sistem",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(
                    "Aydınlık",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(
                    "Karanlık",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
              onChanged: (ThemeMode? mode) {
                if (mode != null) {
                  themeProvider.setThemeMode(mode);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AlertsScreen()),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          "Fiyat Alarmları",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          "Kurduğunuz alarmları yönetin",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Theme.of(context).disabledColor,
        ),
      ),
    );
  }

  Widget _buildContactButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
            color: Colors.orange.withValues(alpha: 0.1),
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
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          "Geri bildirim gönder",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "Yakında",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // App Logo could go here
          Icon(
            Icons.pie_chart_rounded,
            size: 40,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 12),
          Text(
            "AssetMind",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).disabledColor,
            ),
          ),
          Text(
            "v1.0.0",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name = auth.displayName ?? 'Yatırımcı';
        final email = auth.currentUser?.email ?? '';
        final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'Y';
        
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              Divider(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                height: 1,
              ),
              ListTile(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Çıkış Yap'),
                      content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await Provider.of<AuthProvider>(context, listen: false).signOut();
                    // AuthWrapper will automatically handle the routing!
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                title: Text(
                  "Çıkış Yap",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
