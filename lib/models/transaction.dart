enum TransactionType { BUY, SELL }

class TransactionModel {
  final int? id;
  final int holdingId;
  final TransactionType type;
  final double amount;
  final double price;
  final DateTime date;

  TransactionModel({
    this.id,
    required this.holdingId,
    required this.type,
    required this.amount,
    required this.price,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'holding_id': holdingId,
      'type': type.name,
      'amount': amount,
      'price': price,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      holdingId: map['holding_id'],
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      amount: map['amount'],
      price: map['price'],
      date: DateTime.parse(map['date']),
    );
  }
}
