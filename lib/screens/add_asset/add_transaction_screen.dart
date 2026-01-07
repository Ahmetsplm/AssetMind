import 'package:flutter/material.dart';

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

  const AddTransactionScreen({
    super.key,
    required this.symbol,
    required this.name,
    required this.initialPrice,
    required this.type,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  TransactionType _transactionType = TransactionType.BUY; // Default
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.initialPrice.toString();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  double get _total =>
      (double.tryParse(_quantityController.text) ?? 0) *
      (double.tryParse(_priceController.text) ?? 0);

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final amount = double.parse(_quantityController.text);
        final price = double.parse(_priceController.text);

        // Create Transaction Model
        final transaction = TransactionModel(
          holdingId: 0, // Provider fixes this
          type: _transactionType,
          amount: amount,
          price: price,
          date: _selectedDate,
        );

        await Provider.of<PortfolioProvider>(
          context,
          listen: false,
        ).addTransaction(transaction, widget.symbol, widget.type);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.symbol} ${_transactionType == TransactionType.BUY ? "portföye eklendi" : "satışı yapıldı"}!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet for smooth bottom sheet behavior
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // Buy / Sell Toggle
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _transactionType = TransactionType.BUY,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _transactionType == TransactionType.BUY
                                        ? Colors.green
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow:
                                        _transactionType == TransactionType.BUY
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(20),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    "Alış",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _transactionType ==
                                              TransactionType.BUY
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _transactionType = TransactionType.SELL,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _transactionType == TransactionType.SELL
                                        ? Colors.red
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow:
                                        _transactionType == TransactionType.SELL
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(20),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    "Satış",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _transactionType ==
                                              TransactionType.SELL
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form
                      _buildForm(),

                      const SizedBox(height: 24),

                      // Summary and Button
                      _buildBottomSection(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.symbol.isNotEmpty ? widget.symbol.substring(0, 1) : "?",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF1A237E),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.symbol,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(widget.name, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Text(
          '₺${widget.initialPrice}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Fiyat (TL)',
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'İşlem Tarihi',
              suffixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  _dateController.text = DateFormat(
                    'dd/MM/yyyy',
                  ).format(picked);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam İşlem Tutarı',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(_total)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _transactionType == TransactionType.BUY
                  ? Colors.green
                  : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _submitForm,
            child: Consumer<PortfolioProvider>(
              builder: (context, provider, child) {
                return Text(
                  _transactionType == TransactionType.BUY
                      ? 'Portföye Ekle'
                      : 'Satış Yap',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
