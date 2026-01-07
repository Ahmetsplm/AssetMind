import 'holding.dart';

class Favorite {
  final String symbol;
  final AssetType type;

  Favorite({required this.symbol, required this.type});

  Map<String, dynamic> toMap() {
    return {'symbol': symbol, 'type': type.name};
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      symbol: map['symbol'],
      type: AssetType.values.firstWhere((e) => e.name == map['type']),
    );
  }
}
