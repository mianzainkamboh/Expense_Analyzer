import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../utils/app_constants.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseService _svc = ExpenseService();
  String _filter = 'All';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await _svc.deleteExpense(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Expenses', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Search bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search expenses...',
                      hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textGrey, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', ...AppCategories.list].map((f) {
                      final sel = f == _filter;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(f, style: TextStyle(color: sel ? Colors.white : AppColors.textGrey, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _svc.getExpenses(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                var list = snap.data ?? [];
                if (_filter != 'All') list = list.where((e) => e.category == _filter).toList();
                if (_search.isNotEmpty) list = list.where((e) => e.title.toLowerCase().contains(_search) || e.category.toLowerCase().contains(_search)).toList();

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
                          child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 36),
                        ),
                        const SizedBox(height: 14),
                        const Text('No expenses found', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('Try a different filter or add new expense', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                // Group by date
                final grouped = <String, List<Expense>>{};
                for (final e in list) {
                  final key = _dateKey(e.date);
                  grouped.putIfAbsent(key, () => []).add(e);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: grouped.length,
                  itemBuilder: (_, i) {
                    final key = grouped.keys.elementAt(i);
                    final items = grouped[key]!;
                    final dayTotal = items.fold(0.0, (s, e) => s + e.amount);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(key, style: const TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('PKR ${NumberFormat('#,##0').format(dayTotal)}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        ...items.map((e) => _ExpenseCard(expense: e, onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: e))), onDelete: () => _delete(e.id))),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  String _dateKey(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) return 'Today';
    if (d.day == now.day - 1 && d.month == now.month && d.year == now.year) return 'Yesterday';
    return DateFormat('dd MMMM yyyy').format(d);
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit, onDelete;
  const _ExpenseCard({required this.expense, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = AppCategories.getColor(expense.category);
    final icon = AppCategories.getIcon(expense.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(expense.category, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('-PKR ${NumberFormat('#,##0').format(expense.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 14)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textGrey, size: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) { if (v == 'edit') onEdit(); else onDelete(); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
