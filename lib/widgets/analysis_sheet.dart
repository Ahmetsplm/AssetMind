import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../services/portfolio_analyzer.dart';
import '../screens/statistics_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'mesh_gradient_background.dart';

class AnalysisSheet extends StatefulWidget {
  const AnalysisSheet({super.key});

  @override
  State<AnalysisSheet> createState() => _AnalysisSheetState();
}

class _AnalysisSheetState extends State<AnalysisSheet> with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward().then((_) {
        if (mounted) {
          setState(() => _isScanning = false);
        }
      });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final prices = <String, double>{};
        for (var h in provider.holdings) {
          prices[h.symbol] = provider.getCurrentPrice(h.symbol);
        }

        final result = PortfolioAnalyzer.analyze(provider.holdings, prices);
        final scoreColor = _getColor(result.statusColor);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              if (_isScanning)
                _buildScanningState(context)
              else
                _buildResultState(context, result, scoreColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanningState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              Icon(Icons.psychology_rounded, size: 60, color: Theme.of(context).primaryColor),
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -60 + (120 * _scanController.value)),
                    child: Container(
                      width: 140,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Theme.of(context).primaryColor,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "PORTFÖY ANALİZ EDİLİYOR...",
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState(BuildContext context, PortfolioAnalysisResult result, Color scoreColor) {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Mood Aurora
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: MeshGradientBackground(
                    primaryColor: scoreColor.withValues(alpha: 0.1),
                    secondaryColor: Theme.of(context).scaffoldBackgroundColor,
                    child: const SizedBox(),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "PORTFÖY SKORU",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${result.score}",
                      style: GoogleFonts.outfit(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      result.status.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sector Breakdown
            if (result.sectorDistribution.isNotEmpty)
              _buildSectorBreakdown(context, result),

            const SizedBox(height: 32),

            // Recommendations
            _buildRecommendations(context, result),
            
            const SizedBox(height: 24),
            
            _buildStatisticsButton(context),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorBreakdown(BuildContext context, PortfolioAnalysisResult result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SEKTÖREL DAĞILIM",
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: result.sectorDistribution.entries.map((e) {
                      final double total = result.sectorDistribution.values.fold(0.0, (p, c) => p + c);
                      final double percentage = total > 0 ? (e.value / total) * 100 : 0.0;
                      return PieChartSectionData(
                        color: _getSectorColor(e.key),
                        value: percentage,
                        title: '',
                        radius: 12,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.sectorDistribution.entries.map((e) {
                    final double total = result.sectorDistribution.values.fold(0.0, (p, c) => p + c);
                    final double percentage = total > 0 ? (e.value / total) * 100 : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getSectorColor(e.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.key,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "%${percentage.toStringAsFixed(2)}",
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Asset details by sector
          Consumer<PortfolioProvider>(
            builder: (context, provider, _) {
              return Column(
                children: result.sectorDistribution.keys.map((sector) {
                  final sectorAssets = provider.holdings.where((h) {
                    if (h.quantity <= 0) return false;
                    return PortfolioAnalyzer.getMetadata(h.symbol, h.type).sector == sector;
                  }).toList();

                  if (sectorAssets.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getSectorColor(sector).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getSectorColor(sector).withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sector.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getSectorColor(sector),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: sectorAssets.map((h) => Text(
                            h.symbol,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          )).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, PortfolioAnalysisResult result) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: result.recommendations.length,
      itemBuilder: (context, index) {
        final rec = result.recommendations[index];
        final typeColor = _getTypeColor(rec.type);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: typeColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(_getTypeIcon(rec.type), color: typeColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.title,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec.description,
                      style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).disabledColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen()));
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Text(
            "DETAYLI İSTATİSTİKLER",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Color _getColor(AnalysisStatusColor c) {
    switch (c) {
      case AnalysisStatusColor.green: return Colors.greenAccent;
      case AnalysisStatusColor.yellow: return Colors.orangeAccent;
      case AnalysisStatusColor.orange: return Colors.deepOrangeAccent;
      case AnalysisStatusColor.red: return Colors.redAccent;
    }
  }

  Color _getTypeColor(AnalysisType t) {
    switch (t) {
      case AnalysisType.success: return Colors.greenAccent;
      case AnalysisType.warning: return Colors.redAccent;
      case AnalysisType.tip: return Colors.blueAccent;
    }
  }

  IconData _getTypeIcon(AnalysisType t) {
    switch (t) {
      case AnalysisType.success: return Icons.check_circle_outline_rounded;
      case AnalysisType.warning: return Icons.warning_amber_rounded;
      case AnalysisType.tip: return Icons.lightbulb_outline_rounded;
    }
  }

  Color _getSectorColor(String sector) {
    switch (sector) {
      case 'Kripto': return Colors.deepPurpleAccent;
      case 'Emtia': return Colors.amberAccent;
      case 'Döviz': return Colors.greenAccent;
      case 'Küresel Teknoloji': return Colors.blueAccent;
      default: return Colors.blueGrey;
    }
  }
}
