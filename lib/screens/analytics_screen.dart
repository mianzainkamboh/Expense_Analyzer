import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../utils/app_constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  final ExpenseService _svc = ExpenseService();
  List<Expense> _thisMonth = [];
  Map<String, double> _averages = {};
  Map<String, double> _predictions = {};
  List<String> _insights = [];
  double _budget = 0;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final expenses = await _svc.getThisMonthExpenses();
    final averages = await _svc.getLast3MonthsAverage();
    final predictions = await _svc.getNextMonthPrediction();
    final budget = await _svc.getBudget();

    final totals = _totals(expenses);
    final insights = AIPredictionEngine.generateInsights(
      currentMonth: totals,
      predictions: predictions,
      averages: averages,
      budget: budget,
    );

    setState(() {
      _thisMonth = expenses;
      _averages = averages;
      _predictions = predictions;
      _insights = insights;
      _budget = budget;
      _loading = false;
    });
  }

  Map<String, double> _totals(List<Expense> list) {
    final Map<String, double> t = {};
    for (final e in list) t[e.category] = (t[e.category] ?? 0) + e.amount;
    return t;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final totals = _totals(_thisMonth);
    final totalSpent = totals.values.fold(0.0, (a, b) => a + b);
    final totalPredicted = _predictions.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Analytics', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textGrey),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [Tab(text: 'This Month'), Tab(text: 'AI Prediction')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: THIS MONTH ──────────────────────────────────────────
          RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  _SummaryCard(total: totalSpent, count: _thisMonth.length, budget: _budget),
                  const SizedBox(height: 20),

                  if (totals.isNotEmpty) ...[
                    // Pie chart
                    _SectionTitle('Spending by Category'),
                    const SizedBox(height: 12),
                    _PieCard(totals: totals, total: totalSpent),
                    const SizedBox(height: 20),

                    // Category bars
                    _SectionTitle('Category Breakdown'),
                    const SizedBox(height: 12),
                    ...totals.entries.map((e) => _CategoryBar(
                      category: e.key,
                      amount: e.value,
                      total: totalSpent,
                      avg: _averages[e.key],
                    )),
                  ] else
                    _EmptyAnalytics(),

                  // AI Insights
                  if (_insights.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionTitle('AI Insights'),
                    const SizedBox(height: 12),
                    ..._insights.map((msg) => _InsightCard(message: msg)),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── TAB 2: AI PREDICTION ───────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prediction header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B5FEF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('AI Prediction', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PKR ${NumberFormat('#,##0').format(totalPredicted)}',
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('Estimated next month spending', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Text(
                          '🤖 Based on weighted moving average of your last 3 months data. Recent months have higher weight.',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_predictions.isNotEmpty) ...[
                  _SectionTitle('Predicted by Category'),
                  const SizedBox(height: 12),
                  ..._predictions.entries.map((e) => _PredictionRow(
                    category: e.key,
                    predicted: e.value,
                    current: totals[e.key] ?? 0,
                    avg: _averages[e.key] ?? 0,
                  )),
                ] else
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 48, color: AppColors.textLight),
                          SizedBox(height: 12),
                          Text('Not enough data yet', style: TextStyle(color: AppColors.textGrey, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Add expenses for 1+ months to see predictions', style: TextStyle(color: AppColors.textLight, fontSize: 12), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WIDGETS ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark));
}

class _SummaryCard extends StatelessWidget {
  final double total, budget;
  final int count;
  const _SummaryCard({required this.total, required this.count, required this.budget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This Month', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('PKR ${NumberFormat('#,##0').format(total)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('$count transactions', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          if (budget > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Budget Used', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${((total / budget) * 100).clamp(0, 999).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('of PKR ${NumberFormat('#,##0').format(budget)}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
        ],
      ),
    );
  }
}

class _PieCard extends StatelessWidget {
  final Map<String, double> totals;
  final double total;
  const _PieCard({required this.totals, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: totals.entries.map((e) {
                final color = AppCategories.getColor(e.key);
                final pct = total > 0 ? e.value / total * 100 : 0.0;
                return PieChartSectionData(
                  color: color, value: e.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 72,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            )),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14, runSpacing: 8,
            children: totals.keys.map((cat) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: AppCategories.getColor(cat), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(cat, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String category;
  final double amount, total;
  final double? avg;
  const _CategoryBar({required this.category, required this.amount, required this.total, this.avg});

  @override
  Widget build(BuildContext context) {
    final color = AppCategories.getColor(category);
    final pct = total > 0 ? amount / total : 0.0;
    final isOver = avg != null && avg! > 0 && amount > avg! * 1.2;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(AppCategories.getIcon(category), color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(category, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14))),
              if (isOver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('↑ High', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(width: 8),
              Text('PKR ${NumberFormat('#,##0').format(amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(color)),
            ),
          ),
          if (avg != null && avg! > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('3-month avg: PKR ${NumberFormat('#,##0').format(avg)}', style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  final String category;
  final double predicted, current, avg;
  const _PredictionRow({required this.category, required this.predicted, required this.current, required this.avg});

  @override
  Widget build(BuildContext context) {
    final color = AppCategories.getColor(category);
    final trend = avg > 0 ? ((predicted - avg) / avg * 100) : 0.0;
    final isUp = trend > 5;
    final isDown = trend < -5;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(AppCategories.getIcon(category), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14)),
                Text('Current: PKR ${NumberFormat('#,##0').format(current)}', style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('PKR ${NumberFormat('#,##0').format(predicted)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isUp ? Icons.trending_up_rounded : isDown ? Icons.trending_down_rounded : Icons.trending_flat_rounded,
                      size: 14, color: isUp ? AppColors.danger : isDown ? AppColors.success : AppColors.textGrey),
                  const SizedBox(width: 2),
                  Text('${trend.abs().toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: isUp ? AppColors.danger : isDown ? AppColors.success : AppColors.textGrey, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String message;
  const _InsightCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 56, color: AppColors.textLight),
          SizedBox(height: 12),
          Text('No data this month', style: TextStyle(color: AppColors.textGrey, fontSize: 15, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Add expenses to see analytics', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
        ],
      ),
    );
  }
}
