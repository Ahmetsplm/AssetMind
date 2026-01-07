enum AssetType { STOCK, CRYPTO, GOLD, FOREX }

class Holding {
  final int? id;
  final int portfolioId;
  final String symbol;
  final AssetType type;
  final double quantity;
  final double averageCost;
  final double totalRealizedProfit;
  final DateTime lastUpdate;

  Holding({
    this.id,
    required this.portfolioId,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.averageCost,
    required this.totalRealizedProfit,
    required this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'portfolio_id': portfolioId,
      'symbol': symbol,
      'type': type.name,
      'quantity': quantity,
      'average_cost': averageCost,
      'total_realized_profit': totalRealizedProfit,
      'last_update': lastUpdate.toIso8601String(),
    };
  }

  factory Holding.fromMap(Map<String, dynamic> map) {
    return Holding(
      id: map['id'],
      portfolioId: map['portfolio_id'],
      symbol: map['symbol'],
      type: AssetType.values.firstWhere((e) => e.name == map['type']),
      quantity: map['quantity'],
      averageCost: map['average_cost'],
      totalRealizedProfit: map['total_realized_profit'],
      lastUpdate: DateTime.parse(map['last_update']),
    );
  }
}
