import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import 'statistics/stats_general_tab.dart';
import 'statistics/stats_performance_tab.dart';
import 'statistics/stats_distribution_tab.dart';
import 'statistics/stats_transactions_tab.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 8),
              child: Row(
                children: [
                  const BackButton(),
                  Text(
                    "İSTATİSTİKLER",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: "Paylaş",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'İstatistik paylaşım özelliği yakında eklenecek.',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: "Rapor İndir",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'PDF Rapor indirme sistemi yakında aktif olacak.',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Custom TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                indicator: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: "GENEL"),
                  Tab(icon: Icon(Icons.trending_up_rounded, size: 20), text: "PERF."),
                  Tab(icon: Icon(Icons.pie_chart_rounded, size: 20), text: "DAĞILIM"),
                  Tab(icon: Icon(Icons.history_rounded, size: 20), text: "İŞLEM"),
                ],
              ),
            ),
            
            // TabBarView
            Expanded(
              child: Consumer<PortfolioProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: const [
                      StatsGeneralTab(),
                      StatsPerformanceTab(),
                      StatsDistributionTab(),
                      StatsTransactionsTab(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
