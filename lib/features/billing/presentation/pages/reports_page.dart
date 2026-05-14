import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/repositories/bill_repository.dart';
import '../../domain/entities/bill.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../customer/domain/repositories/customer_repository.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _reportDataFuture;
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // Filters
  String _transactionFilter = 'All';
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  String _productSearchQuery = '';
  String _customerSearchQuery = '';
  String _productCategoryFilter = 'All';
  String _paymentMethodFilter = 'All';
  RangeValues _priceRange = const RangeValues(0, 10000);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _productSearchController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _reportDataFuture = _fetchReportData();
    });
  }

  Future<Map<String, dynamic>> _fetchReportData() async {
    final results = await Future.wait([
      sl<BillRepository>().getAllBills(),
      sl<BillRepository>().getDetailedAnalytics(),
      sl<CustomerRepository>().getCustomers(),
      sl<BillRepository>().getRevenueStats(_dateRange!.start, _dateRange!.end),
      sl<BillRepository>().getProductPerformance(),
      sl<BillRepository>().getCategoryPerformance(),
      sl<BillRepository>().getPaymentMethodDistribution(),
      sl<BillRepository>().getAverageOrderValueTrend(),
      sl<BillRepository>().getCustomerRetentionStats(),
      sl<BillRepository>().getInventoryHealth(),
    ]);
    return {
      'bills': results[0],
      'analytics': results[1],
      'customers': results[2],
      'revenueStats': results[3],
      'productPerformance': results[4],
      'categoryPerformance': results[5],
      'paymentDistribution': results[6],
      'aovTrend': results[7],
      'retentionStats': results[8],
      'inventoryHealth': results[9],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Business Insights',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1E293B)),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
            onPressed: _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'Products'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(data),
              _buildTransactionsTab(data),
              _buildProductsTab(data),
              _buildCustomersTab(data),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _refreshData();
    }
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab(Map<String, dynamic> data) {
    final analytics = data['analytics'] as Map<String, dynamic>;
    final revenueStats = data['revenueStats'] as List<Map<String, dynamic>>;
    final paymentDist = data['paymentDistribution'] as List<Map<String, dynamic>>;
    final categoryPerf = data['categoryPerformance'] as List<Map<String, dynamic>>;
    final aovTrend = data['aovTrend'] as List<Map<String, dynamic>>;
    final retention = data['retentionStats'] as Map<String, dynamic>;
    final invHealth = data['inventoryHealth'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(analytics, invHealth),
          const SizedBox(height: 24),
          _buildRevenueChart(revenueStats),
          const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildPaymentMethodPie(paymentDist)),
                const SizedBox(width: 16),
                Expanded(child: _buildHealthScoreCard(analytics, retention)),
              ],
            ),
          const SizedBox(height: 24),
          _buildCategoryPerformanceChart(categoryPerf),
          const SizedBox(height: 24),
          _buildCategoryPieChart(categoryPerf),
          const SizedBox(height: 24),
          _buildAovTrendChart(aovTrend),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildHourlyActivityChart(analytics['hourlyStats'] as List<Map<String, dynamic>>)),
              const SizedBox(width: 16),
              Expanded(child: _buildCustomerSegments(data['customers'] as List<Customer>)),
            ],
          ),
          const SizedBox(height: 24),
          _buildTopProductsSection(analytics['topProducts'] as List<Map<String, dynamic>>),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodPie(List<Map<String, dynamic>> data) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payments', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: data.map((e) {
                  final method = e['paymentMethod'] as String;
                  final color = method == 'UPI' ? Colors.purple : Colors.green;
                  return PieChartSectionData(
                    value: (e['count'] as num).toDouble(),
                    color: color,
                    radius: 15,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: data.map((e) {
              final method = e['paymentMethod'] as String;
              final color = method == 'UPI' ? Colors.purple : Colors.green;
              return _buildSegmentDot(method, color);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(Map<String, dynamic> analytics, Map<String, dynamic> retention) {
    // Mock health score calculation
    final total = (retention['newCustomers'] as int) + (retention['repeatCustomers'] as int);
    final repeatRate = total > 0 ? (retention['repeatCustomers'] as int) / total * 100 : 0.0;
    final unpaidRatio = (analytics['unpaidAmount'] as num) / ((analytics['totalRevenue'] as num) + 0.1);
    
    final healthScore = (repeatRate * 0.6 + (1 - unpaidRatio) * 40).clamp(0.0, 100.0);
    
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Health Index', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: healthScore / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      color: healthScore > 70 ? Colors.greenAccent : (healthScore > 40 ? Colors.amberAccent : Colors.redAccent),
                    ),
                  ),
                  Column(
                    children: [
                      Text(healthScore.toStringAsFixed(0), style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('/100', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMiniMetric('Loyalty', '${repeatRate.toStringAsFixed(1)}%', Colors.blueAccent),
                    const SizedBox(height: 8),
                    _buildMiniMetric('Payment', '${((1 - unpaidRatio) * 100).toStringAsFixed(1)}%', Colors.greenAccent),
                    const SizedBox(height: 8),
                    _buildMiniMetric('Retention', '${(retention['repeatCustomers'] as int)} active', Colors.orangeAccent),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(healthScore > 70 ? 'Business is booming!' : (healthScore > 40 ? 'Stable growth' : 'Needs attention'), 
              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 9)),
        Row(
          children: [
            Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildRetentionCard(Map<String, dynamic> data) {
    final total = (data['newCustomers'] as int) + (data['repeatCustomers'] as int);
    final repeatRate = total > 0 ? (data['repeatCustomers'] as int) / total * 100 : 0.0;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Retention', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: repeatRate / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                  ),
                ),
                Text('${repeatRate.toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Repeat Rate', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRetentionStat('New', data['newCustomers'].toString()),
              _buildRetentionStat('Repeat', data['repeatCustomers'].toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCategoryPerformanceChart(List<Map<String, dynamic>> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Performance', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          ...stats.take(5).map((e) {
            final revenue = (e['totalRevenue'] as num).toDouble();
            final maxRev = stats.isNotEmpty ? (stats[0]['totalRevenue'] as num).toDouble() : 0.0;
            final percentage = maxRev > 0 ? revenue / maxRev : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e['category'] ?? 'Uncategorized', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13)),
                      Text('₹${revenue.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 6,
                      backgroundColor: Colors.grey[100],
                      color: Colors.blue[400],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(List<Map<String, dynamic>> stats) {
    if (stats.isEmpty) return const SizedBox.shrink();
    
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Distribution', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: stats.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        return PieChartSectionData(
                          value: (e['totalRevenue'] as num).toDouble(),
                          color: colors[i % colors.length],
                          radius: 20,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: stats.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildCategoryLegend(
                            e['category'] ?? 'Uncategorized',
                            colors[i % colors.length],
                            (e['totalRevenue'] as num).toDouble(),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(String label, Color color, double revenue) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
        Text('₹${revenue.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAovTrendChart(List<Map<String, dynamic>> stats) {
    if (stats.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avg. Order Value (AOV) Trend', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['avgAOV'] as num).toDouble())).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> analytics, Map<String, dynamic> invHealth) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildKpiCard('Total Revenue', '₹${(analytics['totalRevenue'] as num).toStringAsFixed(0)}', Icons.payments_rounded, Colors.blue, '+12%'),
            _buildKpiCard('Est. Profit', '₹${(analytics['profitEstimate'] as num).toStringAsFixed(0)}', Icons.trending_up_rounded, Colors.purple, '+15%'),
            _buildKpiCard('Avg. Order', '₹${(analytics['avgOrderValue'] as num).toStringAsFixed(0)}', Icons.shopping_basket_rounded, Colors.orange, '+5%'),
            _buildKpiCard('Unpaid Bills', '₹${(analytics['unpaidAmount'] as num).toStringAsFixed(0)}', Icons.pending_actions_rounded, Colors.red, '-2%'),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inventory Value', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
                    Text('₹${(invHealth['totalStockValue'] as num).toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('${invHealth['lowStockCount']} Low Stock', style: GoogleFonts.inter(color: Colors.red[300], fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, String trend) {
    final isPositive = trend.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(trend, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: isPositive ? Colors.green[700] : Colors.red[700])),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildCustomerSegments(List<Customer> customers) {
    final highValue = customers.where((c) => c.points > 500).length;
    final regular = customers.where((c) => c.points <= 500 && c.points > 100).length;
    final newCust = customers.where((c) => c.points <= 100).length;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Segments', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(value: highValue.toDouble(), color: Colors.amber, radius: 15, showTitle: false),
                  PieChartSectionData(value: regular.toDouble(), color: Colors.blue, radius: 15, showTitle: false),
                  PieChartSectionData(value: newCust.toDouble(), color: Colors.grey[300], radius: 15, showTitle: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSegmentDot('VIP', Colors.amber),
              _buildSegmentDot('Reg', Colors.blue),
              _buildSegmentDot('New', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRevenueChart(List<Map<String, dynamic>> stats) {
    if (stats.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Trend', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['dailyRevenue'] as num).toDouble())).toList(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyActivityChart(List<Map<String, dynamic>> stats) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Peak Hours', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: stats.map((e) => BarChartGroupData(
                  x: int.parse(e['hour']),
                  barRods: [BarChartRodData(toY: (e['orderCount'] as num).toDouble(), color: Colors.blue[300], width: 12, borderRadius: BorderRadius.circular(4))],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(List<Map<String, dynamic>> topProducts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Selling Products', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...topProducts.take(5).map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['productName'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${p['totalQty']} units sold', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text('₹${(p['totalRevenue'] as num).toStringAsFixed(0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
        )),
      ],
    );
  }

  // --- TRANSACTIONS TAB ---
  Widget _buildTransactionsTab(Map<String, dynamic> data) {
    final allBills = data['bills'] as List<Bill>;
    final customers = data['customers'] as List<Customer>;

    final filteredBills = allBills.where((bill) {
      final matchesFilter = _transactionFilter == 'All' || 
          (_transactionFilter == 'Paid' && bill.isPaid) || 
          (_transactionFilter == 'Unpaid' && !bill.isPaid);
      
      final matchesPayment = _paymentMethodFilter == 'All' || bill.paymentMethod == _paymentMethodFilter;
      
      final matchesPrice = bill.totalAmount >= _priceRange.start && bill.totalAmount <= _priceRange.end;

      final customer = bill.customerId != null 
          ? customers.cast<Customer?>().firstWhere((c) => c?.id == bill.customerId, orElse: () => null)
          : null;
      
      final matchesSearch = bill.billNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (customer?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      return matchesFilter && matchesPayment && matchesPrice && matchesSearch;
    }).toList();

    final totalFilteredRevenue = filteredBills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
    final unpaidFiltered = filteredBills.where((b) => !b.isPaid).length;

    return Column(
      children: [
        _buildTransactionFilters(filteredBills),
        _buildTransactionsSummary(filteredBills),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredBills.length,
            itemBuilder: (context, index) {
              final bill = filteredBills[index];
              final customer = bill.customerId != null 
                  ? customers.cast<Customer?>().firstWhere((c) => c?.id == bill.customerId, orElse: () => null)
                  : null;
              return _buildBillCard(bill, customer);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filtered Total', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                  Text('₹${totalFilteredRevenue.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${filteredBills.length} Bills', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$unpaidFiltered Unpaid', style: GoogleFonts.inter(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSummary(List<Bill> bills) {
    if (bills.isEmpty) return const SizedBox.shrink();

    final total = bills.fold(0.0, (sum, b) => sum + b.totalAmount);
    final avg = total / bills.length;
    final upiCount = bills.where((b) => b.paymentMethod == 'UPI').length;
    final cashCount = bills.length - upiCount;

    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSummaryItem('Total Volume', '₹${total.toStringAsFixed(0)}', Icons.analytics_rounded, Colors.blue),
          const SizedBox(width: 12),
          _buildSummaryItem('Avg. Ticket', '₹${avg.toStringAsFixed(0)}', Icons.confirmation_number_rounded, Colors.orange),
          const SizedBox(width: 12),
          _buildSummaryItem('Payment Split', '$upiCount UPI / $cashCount Cash', Icons.pie_chart_rounded, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionFilters(List<Bill> filteredBills) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search bill # or customer...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['All', 'Paid', 'Unpaid'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f),
                selected: _transactionFilter == f,
                onSelected: (s) => setState(() => _transactionFilter = f),
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(color: _transactionFilter == f ? AppTheme.primaryColor : Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Payment:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              const SizedBox(width: 12),
              ...['All', 'UPI', 'Cash'].map((m) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(m, style: const TextStyle(fontSize: 11)),
                  selected: _paymentMethodFilter == m,
                  onSelected: (s) => setState(() => _paymentMethodFilter = m),
                  selectedColor: Colors.blue[100],
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              )).toList(),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _exportTransactionsToCSV(filteredBills),
                icon: const Icon(Icons.file_download_rounded, size: 18),
                label: const Text('Export', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportTransactionsToCSV(List<Bill> bills) async {
    final buffer = StringBuffer();
    buffer.writeln('Bill Number,Date,Customer,Amount,Status,Payment Method');
    
    for (final bill in bills) {
      buffer.writeln('${bill.billNumber},${bill.dateTime},${bill.customerId ?? "Guest"},${bill.totalAmount},${bill.isPaid ? "Paid" : "Unpaid"},${bill.paymentMethod}');
    }

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/transactions_report.csv';
    final file = File(path);
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(path)], text: 'Transactions Report');
  }

  // --- PRODUCTS TAB ---
  Widget _buildProductsTab(Map<String, dynamic> data) {
    final performance = data['productPerformance'] as List<Map<String, dynamic>>;
    final categories = (data['categoryPerformance'] as List).map((e) => e['category'] as String).toList();
    if (!categories.contains('Uncategorized')) categories.add('Uncategorized');
    
    final filteredProducts = performance.where((p) {
      final matchesSearch = p['productName'].toString().toLowerCase().contains(_productSearchQuery.toLowerCase());
      final matchesCategory = _productCategoryFilter == 'All' || 
          (p['category'] ?? 'Uncategorized') == _productCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
    
    return Column(
      children: [
        _buildProductFilters(categories),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final p = filteredProducts[index];
              final lowStock = (p['currentStock'] ?? 0) < 10;
              return GestureDetector(
                onTap: () => _showProductDetails(p['productName']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['productName'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('${p['unitsSold']} sold', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                                const SizedBox(width: 12),
                                Text('Stock: ${p['currentStock'] ?? 'N/A'}', 
                                  style: GoogleFonts.inter(fontSize: 12, color: lowStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${(p['revenue'] as num).toStringAsFixed(0)}', 
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                            child: Text('${((p['revenue'] as num) / (data['analytics']['totalRevenue'] as num) * 100).toStringAsFixed(1)}%', 
                              style: TextStyle(fontSize: 9, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductFilters(List<String> categories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _productSearchController,
            onChanged: (v) => setState(() => _productSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', ...categories].map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _productCategoryFilter == c,
                  onSelected: (s) => setState(() => _productCategoryFilter = c),
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: _productCategoryFilter == c ? AppTheme.primaryColor : Colors.grey[600],
                    fontWeight: FontWeight.bold
                  ),
                  padding: EdgeInsets.zero,
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- CUSTOMERS TAB ---
  Widget _buildCustomersTab(Map<String, dynamic> data) {
    final customers = data['customers'] as List<Customer>;
    final filteredCustomers = customers.where((c) => 
      c.name.toLowerCase().contains(_customerSearchQuery.toLowerCase()) || 
      c.phone.contains(_customerSearchQuery)).toList();
      
    final sortedCustomers = List<Customer>.from(filteredCustomers)
      ..sort((a, b) => b.points.compareTo(a.points));

    return Column(
      children: [
        _buildCustomerHeader(customers),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _customerSearchController,
            onChanged: (v) => setState(() => _customerSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search by name or phone...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildCustomerStats(customers),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedCustomers.length,
            itemBuilder: (context, index) {
              final c = sortedCustomers[index];
              return _buildCustomerListItem(c);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerListItem(Customer c) {
    return GestureDetector(
      onTap: () => _showCustomerDetails(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(c.name[0], style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(c.phone, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildLoyaltyBadge(c.points),
                const SizedBox(height: 4),
                Text('${c.points.toStringAsFixed(2)} Pts', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerStats(List<Customer> customers) {
    final highValue = customers.where((c) => c.points > 1000).length;
    final regular = customers.where((c) => c.points <= 1000 && c.points > 300).length;
    final newCust = customers.length - highValue - regular;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatIndicator('VIP', highValue, Colors.amber),
          const SizedBox(width: 12),
          _buildStatIndicator('Regular', regular, Colors.blue),
          const SizedBox(width: 12),
          _buildStatIndicator('New', newCust, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text('$count', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader(List<Customer> customers) {
    if (customers.isEmpty) return const SizedBox.shrink();
    final topSpender = (List<Customer>.from(customers)..sort((a, b) => b.points.compareTo(a.points))).first;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Text('Top Customer', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(topSpender.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${topSpender.points.toStringAsFixed(2)} Loyalty Points', style: GoogleFonts.inter(color: Colors.blue[300], fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Text('${customers.length}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  Text('Total', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyBadge(double points) {
    Color color;
    String label;
    if (points > 1000) {
      color = Colors.amber;
      label = 'GOLD';
    } else if (points > 500) {
      color = Colors.blueGrey;
      label = 'SILVER';
    } else {
      color = Colors.brown[300]!;
      label = 'BRONZE';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 8)),
    );
  }

  void _showProductDetails(String productName) async {
    final analytics = await sl<BillRepository>().getProductDetailedAnalytics(productName);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(productName, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Product Insights', style: GoogleFonts.inter(color: Colors.grey[600])),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildMiniStat('Peak Hour', '${analytics['peakHour'] ?? 'N/A'}:00', Icons.access_time_filled_rounded, Colors.purple),
                const SizedBox(width: 12),
                _buildMiniStat('Trend', 'Last 30d', Icons.trending_up_rounded, Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            Text('Sales Trend (Units)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: analytics['trend'].isEmpty 
                ? const Center(child: Text('No recent sales data'))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: (analytics['trend'] as List).asMap().entries.map((e) => 
                            FlSpot(e.key.toDouble(), (e.value['qty'] as num).toDouble())).toList(),
                          isCurved: true,
                          color: AppTheme.primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withOpacity(0.1)),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDetails(Customer customer) async {
    final analytics = await sl<BillRepository>().getCustomerDetailedAnalytics(customer.id);
    final trend = await sl<BillRepository>().getCustomerSpendingTrend(customer.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(customer.name[0], style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(customer.phone, style: GoogleFonts.inter(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildMiniStat('Total Spend', '₹${(analytics['totalSpend'] as num).toStringAsFixed(0)}', Icons.payments_rounded, Colors.blue),
                _buildMiniStat('Avg Visit', '₹${(analytics['avgSpend'] as num).toStringAsFixed(0)}', Icons.shopping_bag_rounded, Colors.orange),
                _buildMiniStat('Visits', '${analytics['totalVisits']}', Icons.event_available_rounded, Colors.green),
                _buildMiniStat('Points', customer.points.toStringAsFixed(2), Icons.stars_rounded, Colors.amber),
              ],
            ),
            const SizedBox(height: 32),
            Text('Spending Trend', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: trend.isEmpty 
                ? const Center(child: Text('No trend data'))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['spend'] as num).toDouble())).toList(),
                          isCurved: true,
                          color: AppTheme.primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withOpacity(0.1)),
                        ),
                      ],
                    ),
                  ),
            ),
            const SizedBox(height: 32),
            Text('Most Purchased Items', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ...(analytics['favorites'] as List).map((f) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text(f['productName'], style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
                        Text('${f['totalQty']} units', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(Bill bill, Customer? customer) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.receipt_rounded, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(customer?.name ?? bill.billNumber, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(dateFormat.format(bill.dateTime), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${bill.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: bill.isPaid ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(bill.isPaid ? 'PAID' : 'UNPAID', style: TextStyle(color: bill.isPaid ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold, fontSize: 8)),
            ),
          ],
        ),
        children: [
          ...bill.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item.quantity} x ${item.product.name}', style: GoogleFonts.inter(fontSize: 13)),
                Text('₹${item.total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _updateBillStatus(bill),
                icon: Icon(bill.isPaid ? Icons.close_rounded : Icons.check_circle_rounded, size: 18, color: bill.isPaid ? Colors.red : Colors.green),
                label: Text(bill.isPaid ? 'Mark Unpaid' : 'Mark Paid', style: TextStyle(color: bill.isPaid ? Colors.red : Colors.green)),
              ),
              ElevatedButton(
                onPressed: () => _showBillDetails(bill, customer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF1E293B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBillDetails(Bill bill, Customer? customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('RECEIPT', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text(bill.billNumber, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                            Text(customer?.name ?? 'Guest Customer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Date', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                            Text(DateFormat('dd/MM/yyyy HH:mm').format(bill.dateTime), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1),
                    ...bill.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('${item.quantity} x ₹${item.product.price}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Text('₹${item.total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                    const Divider(height: 32, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('₹${bill.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: bill.isPaid ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        bill.isPaid ? 'PAID' : 'PENDING PAYMENT',
                        style: TextStyle(color: bill.isPaid ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Thank you for shopping with us!', style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareReceipt(bill),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareReceipt(Bill bill) async {
    final image = await _screenshotController.capture();
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/receipt_${bill.billNumber}.png').create();
      await imagePath.writeAsBytes(image);
      
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Receipt for ${bill.billNumber} from Retail Billing App',
      );
    }
  }

  Future<void> _updateBillStatus(Bill bill) async {
    await sl<BillRepository>().updateBillStatus(bill.id, !bill.isPaid);
    _refreshData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill status updated')),
      );
    }
  }
}
