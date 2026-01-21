import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/holding.dart';
import '../utils/trading_view_helper.dart';

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
      // Also update BG color of controller
      _controller.setBackgroundColor(
        isDark ? const Color(0xFF131722) : Colors.white,
      );

      final html = TradingViewHelper.getHtmlContent(_tvSymbol!, isDark);
      _controller.loadHtmlString(html);
      _isInit = true;
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
              "Teknik Analiz (TradingView)",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: true,
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
