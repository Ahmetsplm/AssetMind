import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/holding.dart'; // AssetType
import '../../models/transaction.dart';
import '../../providers/portfolio_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final String symbol;
  final String name;
  final double initialPrice;
  final AssetType type;
  final ScrollController scrollController;

  const AddTransactionScreen({
    super.key,
    required this.symbol,
    required this.name,
    required this.initialPrice,
    required this.type,
    required this.scrollController,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController(
      text: widget.initialPrice.toString(),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Header Bar (Drag handle)
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              controller: widget.scrollController,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildPortfolioBadge(),
                const SizedBox(height: 30),
                _buildForm(),
                const SizedBox(height: 20),
                _buildSummaryCard(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.show_chart,
            color: Color(0xFF1A237E),
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            Text(
              widget.name,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₺${widget.initialPrice}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioBadge() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final portfolioName =
            provider.selectedPortfolio?.name ?? "Seçili Portföy Yok";
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder, size: 20, color: Color(0xFF1A237E)),
              const SizedBox(width: 8),
              Text(
                'Eklenecek Portföy: $portfolioName',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yatırım Detayları',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Quantity
          TextFormField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.type == AssetType.FOREX
                  ? 'Miktar (Birim)'
                  : 'Adet (Lot)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (val) => setState(() {}), // Refresh summary
            validator: (val) {
              if (val == null || val.isEmpty) return 'Gerekli';
              if (double.tryParse(val) == null) return 'Geçersiz sayı';
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Price
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Fiyat',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (val) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Gerekli';
                    if (double.tryParse(val) == null) return 'Geçersiz sayı';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Date
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Satın Alma Tarihi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today, size: 20),
                    ),
                    child: Text(
                      DateFormat('dd.MM.yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    double qty = double.tryParse(_quantityController.text) ?? 0;
    double price = double.tryParse(_priceController.text) ?? 0;
    double total = qty * price;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1A237E,
        ).withAlpha(200), // ~0.8 opacity -> 204/255 -> 0.8
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Toplam Yatırım Değeri',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '₺${NumberFormat('#,##0.00', 'tr_TR').format(total)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _submitForm,
        child: Consumer<PortfolioProvider>(
          builder: (context, provider, child) {
            return Text(
              '${provider.selectedPortfolio?.name ?? "..."} Portföyüne Ekle',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    if (provider.selectedPortfolio == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir portföy seçin')));
      return;
    }

    double qty = double.parse(_quantityController.text);
    double price = double.parse(_priceController.text);

    final transaction = TransactionModel(
      holdingId: 0, // Placeholder, provider will calculate
      type: TransactionType.BUY,
      amount: qty,
      price: price,
      date: _selectedDate,
    );

    await provider.addTransaction(transaction, widget.symbol, widget.type);

    if (mounted) {
      Navigator.pop(context); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.symbol} portföye eklendi!')),
      );
    }
  }
}
