import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5B5FEF);
  static const primaryDark = Color(0xFF4347D9);
  static const primaryLight = Color(0xFFEEEFFF);
  static const background = Color(0xFFF5F6FA);
  static const cardWhite = Colors.white;
  static const textDark = Color(0xFF1A1D3B);
  static const textGrey = Color(0xFF8F92A1);
  static const textLight = Color(0xFFCBD5E1);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
}

class AppCategories {
  static const List<String> list = [
    'Food',
    'Transport',
    'Shopping',
    'Health',
    'Utilities',
    'Entertainment',
    'Education',
    'Other',
  ];

  static const Map<String, Color> colors = {
    'Food': Color(0xFFEF4444),
    'Transport': Color(0xFF3B82F6),
    'Shopping': Color(0xFF8B5CF6),
    'Health': Color(0xFF10B981),
    'Utilities': Color(0xFFF59E0B),
    'Entertainment': Color(0xFFEC4899),
    'Education': Color(0xFF06B6D4),
    'Other': Color(0xFF6B7280),
  };

  static const Map<String, IconData> icons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Health': Icons.local_hospital_rounded,
    'Utilities': Icons.bolt_rounded,
    'Entertainment': Icons.movie_rounded,
    'Education': Icons.school_rounded,
    'Other': Icons.category_rounded,
  };

  static Color getColor(String category) =>
      colors[category] ?? const Color(0xFF6B7280);

  static IconData getIcon(String category) =>
      icons[category] ?? Icons.category_rounded;
}

// OCR-based keyword categorization
class OcrCategorizer {
  static const Map<String, List<String>> _keywords = {
    'Food': [
      'restaurant', 'cafe', 'coffee', 'pizza', 'burger', 'food', 'eat',
      'lunch', 'dinner', 'breakfast', 'mcdonalds', 'kfc', 'subway',
      'starbucks', 'biryani', 'karahi', 'bakery', 'sweets', 'chai',
      'dhaba', 'hotel', 'kitchen', 'grill', 'bbq', 'shawarma', 'roll',
      'juice', 'milk', 'bread', 'grocery', 'vegetables', 'fruit',
    ],
    'Transport': [
      'uber', 'careem', 'taxi', 'fuel', 'petrol', 'diesel', 'gas',
      'transport', 'bus', 'train', 'rickshaw', 'parking', 'toll',
      'metro', 'ride', 'fare', 'ticket', 'vehicle', 'car', 'bike',
    ],
    'Shopping': [
      'amazon', 'daraz', 'shop', 'store', 'mall', 'market', 'purchase',
      'buy', 'cloth', 'shirt', 'shoes', 'fashion', 'brand', 'outlet',
      'sale', 'discount', 'retail', 'superstore', 'hyperstar', 'imtiaz',
    ],
    'Health': [
      'pharmacy', 'medicine', 'doctor', 'hospital', 'clinic', 'medical',
      'health', 'drug', 'tablet', 'injection', 'lab', 'test', 'checkup',
      'dentist', 'eye', 'prescription', 'dawakhana', 'shifa',
    ],
    'Utilities': [
      'electricity', 'water', 'gas', 'bill', 'utility', 'internet',
      'wifi', 'phone', 'mobile', 'recharge', 'wapda', 'sui', 'ptcl',
      'jazz', 'zong', 'telenor', 'ufone', 'netflix', 'spotify',
    ],
    'Entertainment': [
      'netflix', 'cinema', 'movie', 'game', 'play', 'entertainment',
      'spotify', 'youtube', 'ticket', 'event', 'concert', 'show',
      'subscription', 'streaming', 'disney', 'hbo',
    ],
    'Education': [
      'school', 'college', 'university', 'fee', 'tuition', 'book',
      'stationery', 'course', 'exam', 'education', 'academy', 'institute',
      'pen', 'notebook', 'copy', 'bag',
    ],
  };

  static String categorize(String text) {
    final lower = text.toLowerCase();
    int maxMatches = 0;
    String bestCategory = 'Other';

    _keywords.forEach((category, keywords) {
      int matches = keywords.where((kw) => lower.contains(kw)).length;
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = category;
      }
    });

    return bestCategory;
  }

  // Extract amount from OCR text
  static double? extractAmount(String text) {
    // Look for patterns like: Rs. 250, PKR 1500, 250.00, Total: 500
    final patterns = [
      RegExp(r'(?:total|amount|rs\.?|pkr|rupees?)[:\s]*(\d+(?:[,\d]*)?(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(\d{1,6}(?:,\d{3})*(?:\.\d{1,2})?)(?:\s*(?:rs|pkr|/-|rupees?))', caseSensitive: false),
      RegExp(r'(?:grand\s*total|net\s*total|sub\s*total)[:\s]*(\d+(?:[,\d]*)?(?:\.\d{1,2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) return amount;
      }
    }
    return null;
  }

  // Extract merchant name (first meaningful line)
  static String extractTitle(String text) {
    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 3 && l.length < 50)
        .toList();
    return lines.isNotEmpty ? lines.first : 'Scanned Receipt';
  }
}

// AI Prediction Engine
class AIPredictionEngine {
  /// Predicts next month spending per category based on last 3 months data
  /// Uses weighted moving average: recent months have more weight
  static Map<String, double> predictNextMonth(List<Map<String, dynamic>> monthlyData) {
    // monthlyData: list of {category: amount} maps, index 0 = oldest, 2 = most recent
    if (monthlyData.isEmpty) return {};

    final categories = AppCategories.list;
    final Map<String, double> predictions = {};

    for (final category in categories) {
      final values = monthlyData
          .map((m) => (m[category] ?? 0.0) as double)
          .toList();

      if (values.every((v) => v == 0)) continue;

      double predicted;
      if (values.length == 1) {
        predicted = values[0];
      } else if (values.length == 2) {
        // Simple average with slight upward trend detection
        predicted = (values[0] * 0.4 + values[1] * 0.6);
      } else {
        // Weighted moving average: weights 0.2, 0.3, 0.5
        predicted = values[0] * 0.2 + values[1] * 0.3 + values[2] * 0.5;
      }

      // Apply trend factor
      if (values.length >= 2) {
        final last = values.last;
        final prev = values[values.length - 2];
        if (prev > 0) {
          final trendFactor = (last - prev) / prev;
          // Cap trend at ±20%
          final cappedTrend = trendFactor.clamp(-0.2, 0.2);
          predicted = predicted * (1 + cappedTrend * 0.3);
        }
      }

      predictions[category] = predicted.clamp(0, double.infinity);
    }

    return predictions;
  }

  /// Generate AI insight messages
  static List<String> generateInsights({
    required Map<String, double> currentMonth,
    required Map<String, double> predictions,
    required Map<String, double> averages,
    required double budget,
  }) {
    final insights = <String>[];
    final totalCurrent = currentMonth.values.fold(0.0, (a, b) => a + b);
    final totalPredicted = predictions.values.fold(0.0, (a, b) => a + b);

    // Budget insight
    if (budget > 0) {
      final remaining = budget - totalCurrent;
      if (remaining < 0) {
        insights.add('⚠️ You have exceeded your monthly budget by PKR ${(-remaining).toStringAsFixed(0)}');
      } else if (remaining < budget * 0.2) {
        insights.add('🔔 Only PKR ${remaining.toStringAsFixed(0)} left in your budget this month');
      }
    }

    // Prediction insight
    if (totalPredicted > 0) {
      insights.add('🤖 AI predicts next month spending: PKR ${totalPredicted.toStringAsFixed(0)}');
    }

    // Category overspending
    averages.forEach((category, avg) {
      final current = currentMonth[category] ?? 0;
      if (avg > 0 && current > avg * 1.3) {
        insights.add('📈 ${category} spending is ${((current / avg - 1) * 100).toStringAsFixed(0)}% above your average');
      }
    });

    // Top spending category
    if (currentMonth.isNotEmpty) {
      final top = currentMonth.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add('💡 Your highest spending is on ${top.key}: PKR ${top.value.toStringAsFixed(0)}');
    }

    // Saving tip
    if (currentMonth.containsKey('Entertainment') && (currentMonth['Entertainment'] ?? 0) > 2000) {
      insights.add('💰 Consider reducing Entertainment expenses to save more');
    }
    if (currentMonth.containsKey('Food') && (currentMonth['Food'] ?? 0) > 15000) {
      insights.add('🍽️ Food expenses are high. Try cooking at home more often');
    }

    return insights.take(4).toList();
  }
}
