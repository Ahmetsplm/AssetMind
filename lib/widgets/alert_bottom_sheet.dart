import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../services/api_service.dart';
import '../services/asset_service.dart';
import '../services/permission_service.dart';
import '../providers/theme_provider.dart';
import '../models/holding.dart';

import '../providers/market_provider.dart';

class AlertBottomSheet extends StatefulWidget {
  final String symbol;
  final double currentPrice;
  final AssetType type;

  const AlertBottomSheet({
    super.key,
    required this.symbol,
    required this.currentPrice,
    required this.type,
  });

  @override
  State<AlertBottomSheet> createState() => _AlertBottomSheetState();
}

class _AlertBottomSheetState extends State<AlertBottomSheet> {
  late TextEditingController _priceController;
  String _selectedCondition = 'above';
  bool _isLoading = false;
  late double _currentPrice;

  @override
  void initState() {
    super.initState();
    _currentPrice = widget.currentPrice;
    _priceController = TextEditingController(
        text: _currentPrice > 0 ? _currentPrice.toStringAsFixed(2) : '');
        
    if (_currentPrice == 0.0) {
      _fetchInitialPrice();
    }
  }

  Future<void> _fetchInitialPrice() async {
    setState(() => _isLoading = true);
    try {
      final market = Provider.of<MarketProvider>(context, listen: false);
      await market.fetchSingleAndNotify(widget.symbol);
      
      final asset = market.getAsset(widget.symbol);
      if (asset != null && asset.price > 0 && mounted) {
        setState(() {
          _currentPrice = asset.price;
          _priceController.text = _currentPrice.toStringAsFixed(2);
        });
      }
    } catch (e) {
      debugPrint("AlertBottomSheet fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveAlert() async {
    final priceStr = _priceController.text.replaceAll(',', '.');
    final targetPrice = double.tryParse(priceStr);
    
    if (targetPrice == null || targetPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir fiyat girin')),
      );
      return;
    }

    // Contextual Permission Check
    final hasNotification = await PermissionService.isNotificationGranted();
    if (!hasNotification) {
      if (!mounted) return;
      final requestNotif = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Bildirim İzni Gerekli'),
          content: const Text('Alarmların çalabilmesi için bildirimlere izin vermelisin.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('İzin Ver')),
          ],
        ),
      );
      if (requestNotif == true) {
        final granted = await PermissionService.requestNotificationPermission();
        if (!granted) return; // İzin vermediyse devam etme
      } else {
        return; // İptal ettiyse devam etme
      }
    }

    final isBypassed = await PermissionService.isBatteryOptimizationBypassed();
    if (!isBypassed) {
      if (!mounted) return;
      final requestBattery = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pil Optimizasyonu'),
          content: const Text('Arka planda fiyatları takip edebilmemiz için pil kısıtlamalarını kapatmalısın.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Belki Sonra')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ayarlara Git')),
          ],
        ),
      );
      if (requestBattery == true) {
        await PermissionService.requestBatteryOptimizationBypass();
      }
    }

    setState(() => _isLoading = true);

    try {
      final alert = Alert(
        id: '', // Will be assigned by Supabase
        userId: '', // Handled in AssetService
        symbol: widget.symbol,
        targetPrice: targetPrice,
        condition: _selectedCondition,
        createdAt: DateTime.now(),
      );

      await AssetService().addAlert(alert);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm başarıyla kuruldu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarm kurulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.symbol} için Alarm Kur',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Güncel Fiyat: ${widget.type.getCurrencySymbol(widget.symbol)}${_currentPrice.toStringAsFixed(2)}',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Hedef Fiyat (${widget.type.getCurrencySymbol(widget.symbol)})',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixText: widget.type.getCurrencySymbol(widget.symbol),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Koşul',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildConditionButton(
                  'above',
                  'Üstüne Çıkarsa',
                  Icons.trending_up,
                  Colors.green,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConditionButton(
                  'below',
                  'Altına Düşerse',
                  Icons.trending_down,
                  Colors.red,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAlert,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Alarmı Kaydet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionButton(
    String value,
    String text,
    IconData icon,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _selectedCondition == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCondition = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
