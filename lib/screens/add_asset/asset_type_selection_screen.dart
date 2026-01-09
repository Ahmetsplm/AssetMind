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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Varlık Kategorisi Seçin',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Portföyünüze eklemek istediğiniz varlık türünü seçin',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
            ),
          ),

          // Portfolio Selector
          _buildPortfolioSelector(context),

          const SizedBox(height: 20),

          // Grid Menu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2, // 2 Columns
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, // Taller cards to fill screen
                children: [
                  _buildCategoryCard(
                    context,
                    title: 'Türk Hisse Senetleri',
                    subtitle: 'Borsa İstanbul\'da işlem gören hisse senetleri',
                    icon: Icons.show_chart,
                    color: Colors.blueAccent,
                    type: AssetType.STOCK,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Değerli Madenler',
                    subtitle: 'Altın,Gümüş ve diğer değerli madenler',
                    icon: Icons.hexagon_outlined,
                    color: Colors.redAccent,
                    type: AssetType.GOLD,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Kripto Para',
                    subtitle:
                        'Bitcoin, Ethereum ve diğer kripto para birimleri',
                    icon: Icons.currency_bitcoin,
                    color: Colors.orange,
                    type: AssetType.CRYPTO,
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'Döviz',
                    subtitle: 'Farklı para birimlerinde nakit pozisyonları',
                    icon: Icons.attach_money,
                    color: Colors.green,
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
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: Color(0xFF1A237E)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: provider.selectedPortfolio?.id,
                    hint: const Text('Portföy Seçin'),
                    isExpanded: true,
                    items: [
                      ...provider.portfolios.map((p) {
                        return DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(
                            p.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }),
                      const DropdownMenuItem<int>(
                        value: -1,
                        child: Text(
                          '+ Yeni Portföy Oluştur',
                          style: TextStyle(
                            color: Color(0xFF1A237E),
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
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF1A237E)),
                onPressed: () => _showAddPortfolioDialog(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  // ... (Portfolio Selector remains same)

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
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
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
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
        title: const Text('Yeni Portföy'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Portföy Adı (Örn: Emeklilik)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addPortfolio(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}
