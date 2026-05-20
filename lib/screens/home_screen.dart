import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../utils/app_constants.dart';
import 'add_expense_screen.dart';
import 'expenses_screen.dart';
import 'analytics_screen.dart';
import 'scan_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeOut);
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = const [
    _DashboardTab(),
    ExpensesScreen(),
    ScanScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: _screens[_currentIndex]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.receipt_long_rounded, label: 'Expenses', index: 1, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                // Center FAB
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 2),
                    child: Center(
                      child: ScaleTransition(
                        scale: _fabAnimation,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Icon(
                            _currentIndex == 2 ? Icons.document_scanner_rounded : Icons.document_scanner_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics', index: 3, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 4, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: selected ? AppColors.primary : AppColors.textGrey, size: selected ? 26 : 22),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: selected ? AppColors.primary : AppColors.textGrey, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ─── DASHBOARD TAB ────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> with SingleTickerProviderStateMixin {
  final ExpenseService _expenseService = ExpenseService();
  double _budget = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadBudget();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadBudget() async {
    final b = await _expenseService.getBudget();
    if (mounted) setState(() => _budget = b);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.getExpenses(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          final thisMonth = all.where((e) => e.date.month == now.month && e.date.year == now.year).toList();
          final total = thisMonth.fold(0.0, (s, e) => s + e.amount);
          final budgetLeft = _budget > 0 ? (_budget - total).clamp(0, _budget) : 0.0;
          final budgetProgress = _budget > 0 ? (total / _budget).clamp(0.0, 1.0) : 0.0;
          final recent = all.take(5).toList();

          return FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_greeting(), style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                              Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final state = context.findAncestorStateOfType<_HomeScreenState>();
                            state?.setState(() => state._currentIndex = 4);
                          },
                          child: Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── TOTAL CARD ──────────────────────────────────────
                      _TotalCard(
                        total: total,
                        budget: _budget,
                        budgetLeft: budgetLeft.toDouble(),
                        month: DateFormat('MMMM yyyy').format(now),
                      ),
                      const SizedBox(height: 24),

                      // ── QUICK ACTIONS ───────────────────────────────────
                      const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ActionCard(
                            icon: Icons.document_scanner_rounded,
                            label: 'Scan Receipt',
                            color: AppColors.primary,
                            onTap: () {
                              final state = context.findAncestorStateOfType<_HomeScreenState>();
                              state?.setState(() => state._currentIndex = 2);
                            },
                          ),
                          const SizedBox(width: 10),
                          _ActionCard(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Scan QR',
                            color: const Color(0xFF10B981),
                            onTap: () {
                              final state = context.findAncestorStateOfType<_HomeScreenState>();
                              state?.setState(() => state._currentIndex = 2);
                            },
                          ),
                          const SizedBox(width: 10),
                          _ActionCard(
                            icon: Icons.add_rounded,
                            label: 'Add Manual',
                            color: const Color(0xFFF59E0B),
                            onTap: () => Navigator.push(context, _slide(const AddExpenseScreen())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── MONTHLY BUDGET ──────────────────────────────────
                      if (_budget > 0) ...[
                        _BudgetCard(total: total, budget: _budget, progress: budgetProgress),
                        const SizedBox(height: 24),
                      ],

                      // ── RECENT EXPENSES ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          GestureDetector(
                            onTap: () {
                              final state = context.findAncestorStateOfType<_HomeScreenState>();
                              state?.setState(() => state._currentIndex = 1);
                            },
                            child: const Text('See All', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      else if (recent.isEmpty)
                        _EmptyState()
                      else
                        ...recent.asMap().entries.map((entry) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 300 + entry.key * 80),
                            builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
                            child: _ExpenseItem(expense: entry.value),
                          );
                        }),

                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Route _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
      child: child,
    ),
  );
}

// ─── TOTAL CARD ───────────────────────────────────────────────────────────────
class _TotalCard extends StatelessWidget {
  final double total, budget, budgetLeft;
  final String month;
  const _TotalCard({required this.total, required this.budget, required this.budgetLeft, required this.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B5FEF), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Spent This Month', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(month, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'PKR ${NumberFormat('#,##0').format(total)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (budget > 0) ...[
                _CardStat(icon: Icons.account_balance_wallet_rounded, label: 'Budget', value: 'PKR ${NumberFormat('#,##0').format(budget)}'),
                const SizedBox(width: 20),
                _CardStat(icon: Icons.trending_down_rounded, label: 'Budget Left', value: 'PKR ${NumberFormat('#,##0').format(budgetLeft)}', isGreen: true),
              ] else
                const Text('Set a budget in Profile →', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isGreen;
  const _CardStat({required this.icon, required this.label, required this.value, this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isGreen ? const Color(0xFF10B981).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isGreen ? const Color(0xFF6EE7B7) : Colors.white70, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// ─── BUDGET CARD ──────────────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  final double total, budget, progress;
  const _BudgetCard({required this.total, required this.budget, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toStringAsFixed(0);
    final isOver = progress >= 1.0;
    final barColor = isOver ? AppColors.danger : progress > 0.8 ? AppColors.warning : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: barColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$pct% used', style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PKR ${NumberFormat('#,##0').format(total)} spent', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              Text('PKR ${NumberFormat('#,##0').format(budget)} budget', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ACTION CARD ──────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── EXPENSE ITEM ─────────────────────────────────────────────────────────────
class _ExpenseItem extends StatelessWidget {
  final Expense expense;
  const _ExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    final color = AppCategories.getColor(expense.category);
    final icon = AppCategories.getIcon(expense.category);
    final isToday = expense.date.day == DateTime.now().day && expense.date.month == DateTime.now().month;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(expense.category, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('-PKR ${NumberFormat('#,##0').format(expense.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 14)),
              const SizedBox(height: 2),
              Text(isToday ? 'Today' : DateFormat('dd MMM').format(expense.date), style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 12),
          const Text('No expenses yet', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Add your first expense to get started', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
