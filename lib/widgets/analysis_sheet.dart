import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../services/portfolio_analyzer.dart';

class AnalysisSheet extends StatelessWidget {
  const AnalysisSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        // Collect prices map effectively
        final prices = <String, double>{};
        for (var h in provider.holdings) {
          prices[h.symbol] = provider.getCurrentPrice(h.symbol);
        }

        final result = PortfolioAnalyzer.analyze(provider.holdings, prices);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Portföy Analizi",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Score Gauge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: result.score / 100,
                      strokeWidth: 12,
                      backgroundColor: Theme.of(
                        context,
                      ).dividerColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColor(result.statusColor),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${result.score}",
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: _getColor(result.statusColor),
                        ),
                      ),
                      Text(
                        result.status,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recommendations List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: result.recommendations.length,
                  itemBuilder: (context, index) {
                    final rec = result.recommendations[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getTypeColor(rec.type).withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getTypeColor(rec.type).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getTypeIcon(rec.type),
                              color: _getTypeColor(rec.type),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rec.title,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rec.description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Color _getColor(AnalysisStatusColor c) {
    switch (c) {
      case AnalysisStatusColor.green:
        return Colors.green;
      case AnalysisStatusColor.yellow:
        return Colors.orange;
      case AnalysisStatusColor.orange:
        return Colors.deepOrange;
      case AnalysisStatusColor.red:
        return Colors.red;
    }
  }

  Color _getTypeColor(AnalysisType t) {
    switch (t) {
      case AnalysisType.success:
        return Colors.green;
      case AnalysisType.warning:
        return Colors.red;
      case AnalysisType.tip:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(AnalysisType t) {
    switch (t) {
      case AnalysisType.success:
        return Icons.check_circle_rounded;
      case AnalysisType.warning:
        return Icons.warning_rounded;
      case AnalysisType.tip:
        return Icons.lightbulb_rounded;
    }
  }
}
