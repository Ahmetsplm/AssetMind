import '../models/holding.dart';

class AssetMetadata {
  final String sector;
  final int riskScore;

  AssetMetadata({required this.sector, required this.riskScore});
}

class PortfolioAnalysisResult {
  final int score;
  final String status;
  final AnalysisStatusColor statusColor;
  final List<AnalysisRecommendation> recommendations;
  final Map<String, double> sectorDistribution;

  PortfolioAnalysisResult({
    required this.score,
    required this.status,
    required this.statusColor,
    required this.recommendations,
    required this.sectorDistribution,
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

enum AnalysisStatusColor { red, orange, yellow, green }

class PortfolioAnalyzer {
  static AssetMetadata getMetadata(String symbol, AssetType type) {
    if (type == AssetType.CRYPTO) {
      return AssetMetadata(sector: 'Kripto', riskScore: 10);
    }
    if (type == AssetType.GOLD) {
      return AssetMetadata(sector: 'Emtia', riskScore: 2);
    }
    if (type == AssetType.FOREX) {
      return AssetMetadata(sector: 'Döviz', riskScore: 3);
    }

    final cleanSymbol = symbol.replaceAll('.IS', '');

    // Küresel Teknoloji
    if (['AAPL', 'MSFT', 'NVDA', 'TSLA', 'GOOGL', 'META', 'AMZN'].contains(cleanSymbol)) {
      return AssetMetadata(sector: 'Küresel Teknoloji', riskScore: 8);
    }

    // BIST ve Fonlar
    switch (cleanSymbol) {
      // Bankalar
      case 'AKBNK':
      case 'YKBNK':
      case 'GARAN':
      case 'ISCTR':
        return AssetMetadata(sector: 'Banka', riskScore: 5);
      // Havacılık
      case 'THYAO':
      case 'PGSUS':
      case 'DOAS': // gerçi otomotiv ama
        return AssetMetadata(sector: 'Havacılık/Ulaşım', riskScore: 6);
      // Teknoloji (BIST)
      case 'ASELS':
      case 'MIAK':
      case 'ARDYZ':
        return AssetMetadata(sector: 'Teknoloji', riskScore: 7);
      // Enerji
      case 'TUPRS':
      case 'ASTOR':
      case 'ENJSA':
      case 'GWIND':
      case 'SMRTG':
        return AssetMetadata(sector: 'Enerji', riskScore: 5);
      // Otomotiv
      case 'FROTO':
      case 'TOASO':
      case 'TTRAK':
      case 'DOAS':
        return AssetMetadata(sector: 'Otomotiv', riskScore: 5);
      // Perakende / Gıda
      case 'BIMAS':
      case 'SOKM':
      case 'MGROS':
      case 'ULKER':
        return AssetMetadata(sector: 'Perakende/Gıda', riskScore: 4);
      // İletişim
      case 'TCELL':
      case 'TTKOM':
        return AssetMetadata(sector: 'İletişim', riskScore: 4);
      // Holding
      case 'KCHOL':
      case 'SAHOL':
      case 'ENKAI':
      case 'SISE':
        return AssetMetadata(sector: 'Holding', riskScore: 4);
      // Nakit & Para Piyasası Fonları
      case 'GTZ':
      case 'ZTLRK':
      case 'GL1':
      case 'GTL':
        return AssetMetadata(sector: 'Nakit/Para Piyasası', riskScore: 1);
      // Emtia Fonları
      case 'ZGOLD':
      case 'GLDTR':
      case 'GMSTR':
        return AssetMetadata(sector: 'Emtia', riskScore: 2);
      // Büyük Endeksler / BYF
      case 'Z30EA':
      case 'ZPT10':
      case 'Z30KE':
        return AssetMetadata(sector: 'Ulusal Endeksler', riskScore: 4);
    }

    if (type == AssetType.FUND) {
      return AssetMetadata(sector: 'Yatırım Fonu (Genel)', riskScore: 4);
    }

    return AssetMetadata(sector: 'Genel BIST/Hisse', riskScore: 6);
  }

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
        sectorDistribution: {},
      );
    }

    double totalValue = 0;
    Map<String, double> sectorValues = {};
    double highRiskValue = 0; // Risk skoru >= 8 olanlar

    for (var h in holdings) {
      if (h.quantity <= 0) continue;
      double price = prices[h.symbol] ?? h.averageCost;
      double val = h.quantity * price;
      totalValue += val;

      final meta = getMetadata(h.symbol, h.type);
      sectorValues[meta.sector] = (sectorValues[meta.sector] ?? 0) + val;

      if (meta.riskScore >= 8) {
        highRiskValue += val;
      }
    }

    if (totalValue == 0) {
      return PortfolioAnalysisResult(
        score: 0,
        status: "Yetersiz Bakiye",
        statusColor: AnalysisStatusColor.red,
        recommendations: [],
        sectorDistribution: {},
      );
    }

    int score = 60; // Taban puan 60'tan başlar (Dengeli bir başlangıç)
    List<AnalysisRecommendation> recs = [];

    // --- Sektörel Dağılım Puanlaması ---
    bool hasDominantSector = false;
    for (var sector in sectorValues.keys) {
      double ratio = sectorValues[sector]! / totalValue;
      if (ratio > 0.70) {
        score -= 20; // %70'ten fazla tek sektör cezası
        hasDominantSector = true;
        recs.add(
          AnalysisRecommendation(
            title: "Yüksek Sektör Konsantrasyonu",
            description: "Portföyünüzün %${(ratio * 100).toInt()}'i '$sector' sektöründe. Bu büyük bir risktir, çeşitliliği artırmalısınız.",
            type: AnalysisType.warning,
          ),
        );
      } else if (ratio > 0.50) {
        score -= 10; // %50'den fazla ise hafif ceza
      }
    }

    // Çeşitlilik Bonusu
    int sectorCount = sectorValues.keys.length;
    if (!hasDominantSector) {
      if (sectorCount >= 5) {
        score += 25;
        recs.add(
          AnalysisRecommendation(
            title: "Mükemmel Çeşitlilik",
            description: "Portföyünüz çok iyi çeşitlendirilmiş ($sectorCount sektör), şoklara karşı oldukça dayanıklı.",
            type: AnalysisType.success,
          ),
        );
      } else if (sectorCount >= 3) {
        score += 15;
      }
    }

    // --- Yüksek Risk Konsantrasyonu ---
    double highRiskRatio = highRiskValue / totalValue;
    if (highRiskRatio > 0.60) {
      score -= 20;
      recs.add(
        AnalysisRecommendation(
          title: "Aşırı Risk İştahı",
          description: "Yüksek riskli varlıklar portföyün %${(highRiskRatio * 100).toInt()}'ini oluşturuyor. Bu çok agresif bir stratejidir.",
          type: AnalysisType.warning,
        ),
      );
    } else if (highRiskRatio > 0.40) {
      score -= 10;
    } else if (highRiskRatio < 0.20 && highRiskRatio > 0) {
      score += 5; // Risk dengeli
    }

    // --- Smart Advisor (Özel Senaryolar) ---
    
    // Teknoloji Yoğunluğu
    double techRatio = ((sectorValues['Küresel Teknoloji'] ?? 0) + (sectorValues['Teknoloji'] ?? 0)) / totalValue;
    if (techRatio > 0.40) {
      recs.add(
        AnalysisRecommendation(
          title: "Teknoloji Ağırlıklı Portföy",
          description: "Aga portföyün teknoloji ağırlıklı (%${(techRatio * 100).toInt()}). Olası bir faiz artışında teknoloji hisseleri baskılanabilir, biraz Emtia (Altın/Gümüş) ekleyerek defansif kalabilirsin.",
          type: AnalysisType.tip,
        ),
      );
    }

    // Kripto Yoğunluğu
    double cryptoRatio = (sectorValues['Kripto'] ?? 0) / totalValue;
    if (cryptoRatio > 0.40 && highRiskRatio <= 0.50) { // If highRisk already warned, avoid duplicate panic, but just remind volatility
      recs.add(
        AnalysisRecommendation(
          title: "Kripto Volatilitesi",
          description: "Portföyündeki kripto oranı yüksek. Kriptodaki sert düzeltmeler tüm portföy performansını derinden etkileyebilir.",
          type: AnalysisType.warning,
        ),
      );
    }

    // Yerel Oyuncular Eksik (BIST Devleri)
    double bistGiantsRatio = ((sectorValues['Banka'] ?? 0) + (sectorValues['Havacılık/Ulaşım'] ?? 0) + (sectorValues['Enerji'] ?? 0) + (sectorValues['Ulusal Endeksler'] ?? 0)) / totalValue;
    if (bistGiantsRatio < 0.10 && totalValue > 1000) {
      recs.add(
        AnalysisRecommendation(
          title: "Yerel Oyuncular Eksik",
          description: "BIST 30 ağırlığın veya büyük Türk şirketleri portföyünde çok düşük. Yerel piyasadaki devleri ekleyerek portföyü stabilize edebilirsin.",
          type: AnalysisType.tip,
        ),
      );
    }

    // Nakit/Kurşun (Dry Powder) Kuralı
    double cashRatio = ((sectorValues['Nakit/Para Piyasası'] ?? 0) + (sectorValues['Döviz'] ?? 0)) / totalValue;
    if (cashRatio > 0.10) {
      score += 10; // Nakit tutma bonusu
      recs.add(
        AnalysisRecommendation(
          title: "Nakit (Kurşun) Gücü",
          description: "Kenarda nakit (kurşun) bulundurman çok zekice. Piyasadaki olası sert düşüşlerde bu nakitle dipten alım fırsatlarını değerlendirebilirsin.",
          type: AnalysisType.success,
        ),
      );
    }

    // Emtia (Güvenli Liman) Kuralı
    double commodityRatio = (sectorValues['Emtia'] ?? 0) / totalValue;
    if (commodityRatio > 0.10) {
      score += 10; // Güvenli liman bonusu
      recs.add(
        AnalysisRecommendation(
          title: "Güvenli Liman",
          description: "Altın ve emtia ağırlığın krizlere ve enflasyona karşı iyi bir kalkan oluşturuyor.",
          type: AnalysisType.success,
        ),
      );
    } else if (commodityRatio < 0.05 && cashRatio < 0.10) {
      score -= 5; // Savunma çok düşük cezası
      recs.add(
        AnalysisRecommendation(
          title: "Savunma Zayıf",
          description: "Kriz anlarında portföyü koruyacak (Altın vb.) savunma araçları yetersiz görünüyor.",
          type: AnalysisType.tip,
        ),
      );
    }

    // Normalize Score
    if (score > 100) score = 100;
    if (score < 0) score = 0;

    String status = "Zayıf";
    AnalysisStatusColor color = AnalysisStatusColor.red;
    if (score >= 80) {
      status = "Mükemmel";
      color = AnalysisStatusColor.green;
    } else if (score >= 60) {
      status = "İyi";
      color = AnalysisStatusColor.yellow;
    } else if (score >= 40) {
      status = "Riskli";
      color = AnalysisStatusColor.orange;
    }

    return PortfolioAnalysisResult(
      score: score,
      status: status,
      statusColor: color,
      recommendations: recs,
      sectorDistribution: sectorValues,
    );
  }
}
