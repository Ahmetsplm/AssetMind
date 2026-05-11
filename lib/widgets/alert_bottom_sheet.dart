import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../services/asset_service.dart';
import '../providers/theme_provider.dart';

class AlertBottomSheet extends StatefulWidget {
  final String symbol;
  final double currentPrice;

  const AlertBottomSheet({
    super.key,
    required this.symbol,
    required this.currentPrice,
  });

  @override
  State<AlertBottomSheet> createState() => _AlertBottomSheetState();
}

class _AlertBottomSheetState extends State<AlertBottomSheet> {
  late TextEditingController _priceController;
  String _selectedCondition = 'above';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.currentPrice.toStringAsFixed(2));
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
            'Güncel Fiyat: ${widget.currentPrice.toStringAsFixed(2)}',
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
              labelText: 'Hedef Fiyat',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Koşul',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
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
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
