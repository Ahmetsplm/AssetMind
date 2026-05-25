import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/alert.dart';
import '../../services/asset_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/market_provider.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AssetService _assetService = AssetService();
  bool _isLoading = true;
  List<Alert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _assetService.getAllAlerts();
      setState(() {
        _alerts = alerts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alarmlar yüklenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAlert(String id) async {
    try {
      await _assetService.deleteAlert(id);
      if (!mounted) return;
      setState(() {
        _alerts.removeWhere((a) => a.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fiyat Alarmları',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState(context)
              : Consumer<MarketProvider>(
                  builder: (context, marketProvider, child) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        return _buildAlertCard(context, alert, isDark, marketProvider);
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz bir alarm kurmadınız.',
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Varlık detay sayfasından yeni alarm ekleyebilirsiniz.',
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String symbol) {
    if (symbol.endsWith('USDT') || symbol.toLowerCase().contains('ons')) {
      return '\$';
    }
    final globals = [
      'AAPL', 'MSFT', 'TSLA', 'AMZN', 'GOOGL', 'NVDA', 'META', 'NFLX',
      'AMD', 'INTC', 'JPM', 'V', 'DIS', 'SPY', 'QQQ',
    ];
    if (globals.contains(symbol)) return '\$';
    return '₺';
  }

  Widget _buildAlertCard(BuildContext context, Alert alert, bool isDark, MarketProvider marketProvider) {
    final isAbove = alert.condition == 'above';
    final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm');

    final assetData = marketProvider.getAsset(alert.symbol) ?? marketProvider.getAsset('${alert.symbol}.IS');
    final double currentPrice = assetData?.price ?? 0.0;
    
    double diffPercent = 0.0;
    if (currentPrice > 0) {
      diffPercent = ((alert.targetPrice - currentPrice) / currentPrice) * 100;
    }
    
    // +% veya -% formatı
    String diffText = "";
    Color diffColor = Colors.grey;
    if (currentPrice > 0) {
      if (diffPercent >= 0) {
        diffText = "(+100)";
        diffText = "(+%${diffPercent.abs().toStringAsFixed(2)})";
        diffColor = Colors.green;
      } else {
        diffText = "(-%${diffPercent.abs().toStringAsFixed(2)})";
        diffColor = Colors.red;
      }
    }

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isAbove ? Colors.green : Colors.red).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAbove ? Icons.trending_up : Icons.trending_down,
            color: isAbove ? Colors.green : Colors.red,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              alert.symbol,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (!alert.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tetiklendi',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Hedef: ',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${_getCurrencySymbol(alert.symbol)}${alert.targetPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                if (currentPrice > 0)
                  Text(
                    diffText,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: diffColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Güncel: ',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                Text(
                  currentPrice > 0 
                      ? '${_getCurrencySymbol(alert.symbol)}${currentPrice.toStringAsFixed(2)}'
                      : 'Bekleniyor...',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatter.format(alert.createdAt),
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _deleteAlert(alert.id),
        ),
      ),
    );
  }
}
