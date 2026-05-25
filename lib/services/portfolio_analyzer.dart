import '../models/holding.dart';
import '../services/api_service.dart';

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
    Map<AssetType, double> typeValues = {};
    double highRiskValue = 0;

    for (var h in holdings) {
      if (h.quantity <= 0) continue;
      double price = prices[h.symbol] ?? h.averageCost;
      double val = h.quantity * price;
      
      if (h.type == AssetType.CRYPTO || h.type == AssetType.GLOBAL) {
        val *= ApiService().usdTryRate;
      }
      
      totalValue += val;
      typeValues[h.type] = (typeValues[h.type] ?? 0) + val;

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
      }
    }

    // --- 1. Coğrafi Çeşitlendirme (Geographical Diversification) ---
    double bistRatio = ((sectorValues['Banka'] ?? 0) + (sectorValues['Havacılık/Ulaşım'] ?? 0) + (sectorValues['Teknoloji'] ?? 0) + (sectorValues['Enerji'] ?? 0) + (sectorValues['Genel BIST/Hisse'] ?? 0) + (sectorValues['Holding'] ?? 0) + (sectorValues['Otomotiv'] ?? 0) + (sectorValues['Perakende/Gıda'] ?? 0) + (sectorValues['İletişim'] ?? 0)) / totalValue;
    double globalRatio = ((typeValues[AssetType.GLOBAL] ?? 0) + (typeValues[AssetType.FOREX] ?? 0)) / totalValue;
    
    if (bistRatio > 0.10 && globalRatio > 0.10) {
      score += 15;
      recs.add(
        AnalysisRecommendation(
          title: "Coğrafi Çeşitlendirme",
          description: "Yatırımlarını farklı ülkelere ve piyasalara bölerek lokal krizlere karşı harika bir kalkan oluşturdun.",
          type: AnalysisType.success,
        ),
      );
    } else if (bistRatio > 0.80) {
      score -= 10;
      recs.add(
        AnalysisRecommendation(
          title: "Lokal Piyasaya Aşırı Bağımlılık",
          description: "Portföyünün neredeyse tamamı Türk varlıklarında. Global varlıklar ekleyerek yerel riskleri azaltabilirsin.",
          type: AnalysisType.tip,
        ),
      );
    }

    // --- 2. Profesyonel Yönetim Bonusu (Smart Money) ---
    double fundRatio = (typeValues[AssetType.FUND] ?? 0) / totalValue;
    if (fundRatio >= 0.20) {
      score += 10;
      recs.add(
        AnalysisRecommendation(
          title: "Profesyonel Dokunuş",
          description: "Portföyünün önemli bir kısmı uzman yöneticiler (Fonlar) tarafından yönetiliyor. Bu, hataları azaltıp stabil büyüme sağlar.",
          type: AnalysisType.success,
        ),
      );
    }

    // --- 3. Kur Şoku / Enflasyon Riski Uyarısı (Inflation Hedge) ---
    double fxIndexedRatio = ((typeValues[AssetType.GLOBAL] ?? 0) + (typeValues[AssetType.FOREX] ?? 0) + (typeValues[AssetType.CRYPTO] ?? 0) + (typeValues[AssetType.GOLD] ?? 0)) / totalValue;
    if (fxIndexedRatio < 0.25) {
      score -= 15;
      recs.add(
        AnalysisRecommendation(
          title: "Yüksek Kur/Enflasyon Riski",
          description: "Portföyünün büyük kısmı TL cinsinden varlıklara dayalı. Olası bir kur şokuna karşı döviz bazlı varlıklarla hedge etmeyi düşünmelisin.",
          type: AnalysisType.warning,
        ),
      );
    }

    // --- 4. All-Weather (Dört Mevsim) Portföy Modeli ---
    double stockRatio = bistRatio + (typeValues[AssetType.GLOBAL] ?? 0) / totalValue;
    double commodityRatio = (typeValues[AssetType.GOLD] ?? 0) / totalValue;
    double cashRatio = ((sectorValues['Nakit/Para Piyasası'] ?? 0) + (typeValues[AssetType.FOREX] ?? 0) + fundRatio);
    
    if (stockRatio >= 0.25 && stockRatio <= 0.55 && commodityRatio >= 0.05 && cashRatio >= 0.15) {
      score += 20;
      recs.add(
        AnalysisRecommendation(
          title: "Dört Mevsim (All-Weather) Portföy",
          description: "Ray Dalio'nun meşhur stratejisine çok yakınsın! Portföyün enflasyona, deflasyona ve krizlere karşı kusursuz dengelenmiş.",
          type: AnalysisType.success,
        ),
      );
    } else if (commodityRatio > 0.10) {
      score += 10; // Güvenli liman bonusu
      recs.add(
        AnalysisRecommendation(
          title: "Güvenli Liman",
          description: "Altın ve emtia ağırlığın krizlere ve enflasyona karşı iyi bir kalkan oluşturuyor.",
          type: AnalysisType.success,
        ),
      );
    } else if (commodityRatio < 0.05 && cashRatio < 0.10) {
      score -= 5;
      recs.add(
        AnalysisRecommendation(
          title: "Savunma Zayıf",
          description: "Kriz anlarında portföyü koruyacak savunma araçları (Altın, Nakit) yetersiz görünüyor.",
          type: AnalysisType.tip,
        ),
      );
    }

    // --- 5. Spekülatif Yığılma Cezası Güncellemesi ---
    double cryptoRatio = (typeValues[AssetType.CRYPTO] ?? 0) / totalValue;
    double highRiskRatio = highRiskValue / totalValue;

    if (cryptoRatio > 0.50 || highRiskRatio > 0.60) {
      score -= 25;
      recs.add(
        AnalysisRecommendation(
          title: "Aşırı Spekülatif Yığılma",
          description: "Agresif büyüme ararken sermayeni büyük bir riske atıyorsun. Düşüş trendlerinde portföyün ciddi eriyebilir.",
          type: AnalysisType.warning,
        ),
      );
    } else if (cryptoRatio > 0.25) {
      score -= 10;
      recs.add(
        AnalysisRecommendation(
          title: "Kripto Volatilitesi",
          description: "Kripto oranın dikkat çekici boyutta. Kriptodaki sert düzeltmeler tüm portföy performansını sarsabilir.",
          type: AnalysisType.warning,
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
