class Alert {
  final String id;
  final String userId;
  final String symbol;
  final double targetPrice;
  final String condition; // 'above' or 'below'
  final bool isActive;
  final DateTime createdAt;

  Alert({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.targetPrice,
    required this.condition,
    this.isActive = true,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      userId: json['user_id'],
      symbol: json['symbol'],
      targetPrice: (json['target_price'] as num).toDouble(),
      condition: json['condition'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'target_price': targetPrice,
      'condition': condition,
      'is_active': isActive,
    };
  }
}
