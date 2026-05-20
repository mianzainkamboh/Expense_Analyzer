import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../utils/app_constants.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _expensesRef =>
      _db.collection('users').doc(_uid).collection('expenses');

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addExpense(Expense expense) async {
    await _expensesRef.doc(expense.id).set(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _expensesRef.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _expensesRef.doc(id).delete();
  }

  // ── STREAMS ───────────────────────────────────────────────────────────────

  Stream<List<Expense>> getExpenses() {
    return _expensesRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  // ── QUERIES ───────────────────────────────────────────────────────────────

  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final snapshot = await _expensesRef
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .get();
    return snapshot.docs
        .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Expense>> getThisMonthExpenses() async {
    final now = DateTime.now();
    return getExpensesForMonth(now.year, now.month);
  }

  // ── AI ENGINE ─────────────────────────────────────────────────────────────

  /// Returns per-category totals for a given month
  Map<String, double> _categoryTotals(List<Expense> expenses) {
    final Map<String, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  /// Returns last 3 months category averages
  Future<Map<String, double>> getLast3MonthsAverage() async {
    final now = DateTime.now();
    final monthlyData = <Map<String, double>>[];

    for (int i = 3; i >= 1; i--) {
      int month = now.month - i;
      int year = now.year;
      while (month <= 0) {
        month += 12;
        year -= 1;
      }
      final expenses = await getExpensesForMonth(year, month);
      monthlyData.add(_categoryTotals(expenses));
    }

    // Average across 3 months
    final Map<String, double> averages = {};
    for (final month in monthlyData) {
      month.forEach((cat, val) {
        averages[cat] = (averages[cat] ?? 0) + val;
      });
    }
    averages.updateAll((key, value) => value / 3);
    return averages;
  }

  /// Returns AI prediction for next month using weighted moving average
  Future<Map<String, double>> getNextMonthPrediction() async {
    final now = DateTime.now();
    final monthlyData = <Map<String, dynamic>>[];

    for (int i = 3; i >= 1; i--) {
      int month = now.month - i;
      int year = now.year;
      while (month <= 0) {
        month += 12;
        year -= 1;
      }
      final expenses = await getExpensesForMonth(year, month);
      final totals = _categoryTotals(expenses);
      monthlyData.add(totals.map((k, v) => MapEntry(k, v)));
    }

    return AIPredictionEngine.predictNextMonth(monthlyData);
  }

  // ── BUDGET ────────────────────────────────────────────────────────────────

  Future<void> saveBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_${_uid}', amount);
  }

  Future<double> getBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('budget_${_uid}') ?? 0.0;
  }
}
