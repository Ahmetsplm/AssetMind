import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/holding.dart';
import '../utils/trading_view_helper.dart';
import '../providers/market_provider.dart';
import '../widgets/alert_bottom_sheet.dart';

class TradingViewScreen extends StatefulWidget {
  final String symbol;
  final AssetType type;

  const TradingViewScreen({
    super.key,
    required this.symbol,
    required this.type,
  });

  @override
  State<TradingViewScreen> createState() => _TradingViewScreenState();
}

class _TradingViewScreenState extends State<TradingViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _tvSymbol;

  @override
  void initState() {
    super.initState();

    _tvSymbol = TradingViewHelper.getTradingViewSymbol(
      widget.symbol,
      widget.type,
    );

    if (_tvSymbol != null) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF131722)) // Dark BG default
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
          ),
        );
      // Content loading moved to build/didChangeDependencies to access Theme
    }
  }

  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && _tvSymbol != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      _controller.setBackgroundColor(
        isDark ? const Color(0xFF131722) : Colors.white,
      );

      if (widget.type == AssetType.STOCK || widget.type == AssetType.FUND) {
        // BIST and Fund: Embed widget doesn't support them, load full page url
        final pageUrl = TradingViewHelper.getTradingViewUrl(widget.symbol, widget.type);
        if (pageUrl != null) {
          _controller.loadRequest(Uri.parse(pageUrl));
        }
      } else {
        // Crypto & Global: Embed widget works perfectly
        final embedUrl = TradingViewHelper.getEmbedUrl(_tvSymbol!, isDark);
        _controller.loadRequest(Uri.parse(embedUrl));
      }
      _isInit = true;
    }
  }

  Future<void> _openInBrowser() async {
    final urlStr = TradingViewHelper.getTradingViewUrl(widget.symbol, widget.type);
    if (urlStr != null) {
      final uri = Uri.parse(urlStr);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Link açılamadı")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tvSymbol == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hata")),
        body: const Center(
          child: Text("Bu varlık için grafik desteklenmiyor."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.symbol,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.type == AssetType.FUND ? "Fon Analizi (TEFAS)" : "Teknik Analiz (TradingView)",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Tarayıcıda Aç (F/K, PD/DD gibi temel veriler için)
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: widget.type == AssetType.FUND ? "Tarayıcıda Aç (TEFAS)" : "Tarayıcıda Aç (F/K, PD/DD)",
            onPressed: _openInBrowser,
          ),
          // Alarm Kur
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {
              final marketProvider = Provider.of<MarketProvider>(context, listen: false);
              final currentPrice = marketProvider.getPrice(widget.symbol);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AlertBottomSheet(
                  symbol: widget.symbol,
                  currentPrice: currentPrice,
                  type: widget.type,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

