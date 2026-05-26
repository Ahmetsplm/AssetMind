import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class LiveTicker extends StatefulWidget {
  const LiveTicker({super.key});

  @override
  State<LiveTicker> createState() => _LiveTickerState();
}

class _LiveTickerState extends State<LiveTicker> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    const duration = Duration(seconds: 30);
    
    while (_scrollController.hasClients) {
      await _scrollController.animateTo(
        maxScroll,
        duration: duration,
        curve: Curves.linear,
      );
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryData = ApiService().getMarketSummarySync();
    
    if (summaryData.isEmpty) {
      return const SizedBox(height: 32);
    }
    
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 20, // Repeat items for loop effect
        itemBuilder: (context, index) {
          final item = summaryData[index % summaryData.length];
          final bool isUp = item['is_rising'];
          final color = isUp ? Colors.greenAccent : Colors.redAccent;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              children: [
                Text(
                  item['symbol'].toString().toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "%${item['change_rate']}",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                  color: color,
                  size: 14,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
