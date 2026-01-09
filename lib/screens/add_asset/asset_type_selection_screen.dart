import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/holding.dart'; // For AssetType
import 'asset_list_screen.dart';

class AssetTypeSelectionScreen extends StatelessWidget {
  const AssetTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure portfolios are loaded when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      if (provider.portfolios.isEmpty) {
        provider.loadPortfolios();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Varlık Ekle',
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Portföyünüze hangi türde varlık eklemek istersiniz?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),

          // Portfolio Selector
          _buildPortfolioSelector(context),

          const SizedBox(height: 24),

          // Grid Menu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2, // 2 Columns
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85, // Taller cards to fill screen
                children: [
                  _buildCategoryCard(
                    context,
                    title: 'Borsa İstanbul',
                    subtitle: 'BIST 100/30 Hisse Senetleri',
                    icon: Icons.show_chart_rounded,
                    color: const Color(0xFF4285F4),
                    type: AssetType.STOCK,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Değerli Madenler',
                    subtitle: 'Altın, Gümüş, Platin',
                    icon: Icons.diamond_outlined,
                    color: const Color(0xFFEA4335),
                    type: AssetType.GOLD,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Kripto Para',
                    subtitle: 'Bitcoin, Ethereum, Altcoinler',
                    icon: Icons.currency_bitcoin_rounded,
                    color: const Color(0xFFFBBC05),
                    type: AssetType.CRYPTO,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Döviz',
                    subtitle: 'Dolar, Euro, Sterlin',
                    icon: Icons.currency_exchange_rounded,
                    color: const Color(0xFF34A853),
                    type: AssetType.FOREX,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSelector(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        if (provider.portfolios.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: provider.selectedPortfolio?.id,
                    dropdownColor: Theme.of(context).cardColor,
                    hint: const Text('Portföy Seçin'),
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    items: [
                      ...provider.portfolios.map((p) {
                        return DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(
                            p.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        );
                      }),
                      DropdownMenuItem<int>(
                        value: -1,
                        child: Text(
                          '+ Yeni Portföy Oluştur',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == -1) {
                        _showAddPortfolioDialog(context, provider);
                      } else {
                        final selected = provider.portfolios.firstWhere(
                          (p) => p.id == value,
                        );
                        provider.selectPortfolio(selected);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required AssetType type,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AssetListScreen(type: type)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center Horizontally
          mainAxisAlignment: MainAxisAlignment.center, // Center Vertically
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPortfolioDialog(
    BuildContext context,
    PortfolioProvider provider,
  ) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Yeni Portföy',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: TextField(
          controller: controller,
          cursorColor: Theme.of(context).primaryColor,
          decoration: InputDecoration(
            hintText: 'Portföy Adı (Örn: Emeklilik)',
            hintStyle: GoogleFonts.poppins(
              color: Theme.of(context).disabledColor,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addPortfolio(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Oluştur',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
