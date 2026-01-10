import '../models/holding.dart';

class PortfolioAnalysisResult {
  final int score;
  final String status;
  final AnalysisStatusColor statusColor;
  final List<AnalysisRecommendation> recommendations;

  PortfolioAnalysisResult({
    required this.score,
    required this.status,
    required this.statusColor,
    required this.recommendations,
  });
}

class AnalysisRecommendation {
  final String title;
  final String description;
  final AnalysisType type;

  AnalysisRecommendation({
    required this.title,
    required this.description,
    required this.type,
  });
}

enum AnalysisType { warning, tip, success }

// Use simple names mapping to colors
enum AnalysisStatusColor { red, orange, yellow, green }

class PortfolioAnalyzer {
  static PortfolioAnalysisResult analyze(
    List<Holding> holdings,
    Map<String, double> prices,
  ) {
    if (holdings.isEmpty) {
      return PortfolioAnalysisResult(
        score: 0,
        status: "Veri Yok",
        statusColor: AnalysisStatusColor.red,
        recommendations: [
          AnalysisRecommendation(
            title: "Portföy Boş",
            description: "Analiz yapabilmek için varlık eklemelisiniz.",
            type: AnalysisType.warning,
          ),
        ],
      );
    }

    double totalValue = 0;
    Map<AssetType, double> typeValues = {};

    for (var h in holdings) {
      if (h.quantity <= 0) continue;
      double price = prices[h.symbol] ?? h.averageCost;
      double val = h.quantity * price;
      totalValue += val;
      typeValues[h.type] = (typeValues[h.type] ?? 0) + val;
    }

    if (totalValue == 0) {
      return PortfolioAnalysisResult(
        score: 0,
        status: "Yetersiz Bakiye",
        statusColor: AnalysisStatusColor.red,
        recommendations: [],
      );
    }

    // --- Scoring Logic ---
    int score = 0;
    List<AnalysisRecommendation> recs = [];

    // 1. Diversity (Max 40)
    int typesCount = typeValues.keys.length;
    if (typesCount >= 4) {
      score += 40;
      recs.add(
        AnalysisRecommendation(
          title: "Mükemmel Çeşitlilik",
          description: "Portföyünüz farklı varlık sınıflarına dağılmış.",
          type: AnalysisType.success,
        ),
      );
    } else if (typesCount >= 2) {
      score += 20;
    } else {
      recs.add(
        AnalysisRecommendation(
          title: "Çeşitlilik Zayıf",
          description:
              "Risk azaltmak için farklı varlık sınıfları (Altın, Döviz vb.) ekleyin.",
          type: AnalysisType.warning,
        ),
      );
    }

    // 2. Crypto Risk (Max 30)
    double cryptoRatio = (typeValues[AssetType.CRYPTO] ?? 0) / totalValue;
    if (cryptoRatio > 0.60) {
      recs.add(
        AnalysisRecommendation(
          title: "Yüksek Kripto Riski",
          description:
              "Portföyün %${(cryptoRatio * 100).toInt()}'ı kripto para. Bu yüksek volatilite riskidir.",
          type: AnalysisType.warning,
        ),
      );
    } else if (cryptoRatio > 0.0) {
      score += 30; // Managed risk with some exposure or small
    } else {
      score += 30; // No crypto risk (Safe)
      // Suggestion
      recs.add(
        AnalysisRecommendation(
          title: "Kripto Fırsatı",
          description:
              "Küçük bir miktar kripto para potansiyel büyüme sağlayabilir.",
          type: AnalysisType.tip,
        ),
      );
    }

    // 3. Stability (Gold/Forex) (Max 30)
    double stabilityVal =
        (typeValues[AssetType.GOLD] ?? 0) + (typeValues[AssetType.FOREX] ?? 0);
    double stabilityRatio = stabilityVal / totalValue;

    if (stabilityRatio >= 0.20) {
      score += 30;
      recs.add(
        AnalysisRecommendation(
          title: "Güvenli Liman",
          description: "Altın/Döviz oranınız krizlere karşı koruyucu seviyede.",
          type: AnalysisType.success,
        ),
      );
    } else {
      score += (stabilityRatio * 100).toInt(); // Partial points
      recs.add(
        AnalysisRecommendation(
          title: "Savunma Zayıf",
          description:
              "Enflasyona veya düşüşlere karşı Altın veya majör Döviz oranını artırabilirsiniz.",
          type: AnalysisType.tip,
        ),
      );
    }

    // Normalize Score Score
    if (score > 100) score = 100;

    String status = "Zayıf";
    AnalysisStatusColor color = AnalysisStatusColor.red;
    if (score >= 80) {
      status = "Mükemmel";
      color = AnalysisStatusColor.green;
    } else if (score >= 50) {
      status = "İyi";
      color = AnalysisStatusColor.yellow;
    } else {
      status = "Riskli";
      color = AnalysisStatusColor.red;
    }

    return PortfolioAnalysisResult(
      score: score,
      status: status,
      statusColor: color,
      recommendations: recs,
    );
  }
}
