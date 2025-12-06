import 'package:intl/intl.dart';

/// Currency formatting utilities for LAK and other currencies
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _lakFormatter = NumberFormat('#,##0', 'en_US');

  /// Format amount in LAK without symbol
  static String formatLAK(double amount) {
    return _lakFormatter.format(amount.round());
  }

  /// Format amount in LAK with symbol
  static String formatLAKWithSymbol(double amount) {
    return '${_lakFormatter.format(amount.round())} ₭';
  }

  /// Format amount with custom currency
  static String format(double amount, {String currency = 'LAK'}) {
    switch (currency.toUpperCase()) {
      case 'LAK':
        return formatLAKWithSymbol(amount);
      case 'USD':
        return NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 2,
        ).format(amount);
      case 'THB':
        return NumberFormat.currency(
          symbol: '฿',
          decimalDigits: 0,
        ).format(amount);
      default:
        return '$currency ${_lakFormatter.format(amount)}';
    }
  }

  /// Format compact amount (e.g., 1.5M, 500K)
  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₭';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K ₭';
    }
    return formatLAKWithSymbol(amount);
  }

  /// Parse currency string to double
  static double parse(String value) {
    // Remove currency symbols and spaces
    final cleaned =
        value
            .replaceAll('₭', '')
            .replaceAll(',', '')
            .replaceAll(' ', '')
            .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  /// Format for receipt (right-aligned)
  static String formatForReceipt(double amount, {int width = 15}) {
    final formatted = formatLAKWithSymbol(amount);
    return formatted.padLeft(width);
  }

  /// Format change amount
  static String formatChange(double change) {
    if (change <= 0) return '0 ₭';
    return formatLAKWithSymbol(change);
  }

  /// Common LAK denominations
  static const List<int> lakDenominations = [
    100000,
    50000,
    20000,
    10000,
    5000,
    2000,
    1000,
    500,
  ];

  /// Calculate optimal change breakdown
  static Map<int, int> calculateChangeBreakdown(double changeAmount) {
    int remaining = changeAmount.round();
    final breakdown = <int, int>{};

    for (final denomination in lakDenominations) {
      if (remaining >= denomination) {
        final count = remaining ~/ denomination;
        breakdown[denomination] = count;
        remaining -= denomination * count;
      }
    }

    return breakdown;
  }

  /// Format denomination for display
  static String formatDenomination(int denomination) {
    return '${_lakFormatter.format(denomination)} ₭';
  }
}
