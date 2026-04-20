import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';
import '../../../core/models/report.dart';
import '../../../core/providers/localization_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';
import 'report_date_filter.dart';

/// Sales by Payment Type Report — Loyverse style
class PaymentsReportScreen extends ConsumerStatefulWidget {
  const PaymentsReportScreen({super.key});

  @override
  ConsumerState<PaymentsReportScreen> createState() =>
      _PaymentsReportScreenState();
}

class _PaymentsReportScreenState extends ConsumerState<PaymentsReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadToday();
    });
  }

  IconData _methodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'card':
        return Icons.credit_card;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        if (method.contains('qr') || method.contains('bank')) {
          return Icons.qr_code_2;
        }
        return Icons.payment;
    }
  }

  Color _methodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'transfer':
        return Colors.orange;
      default:
        if (method.contains('qr') || method.contains('bank')) {
          return Colors.indigo;
        }
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final lang = ref.watch(localizationProvider).languageCode;
    final payments = state.paymentBreakdown;

    final totalAmount = payments.fold<double>(0, (s, p) => s + p.totalAmount);
    final totalTxns = payments.fold<int>(0, (s, p) => s + p.transactionCount);

    // Calculate percentages if not provided by API
    final withPercent =
        payments.map((p) {
          final pct =
              totalAmount > 0 ? (p.totalAmount / totalAmount * 100) : 0.0;
          return SalesByPaymentItem(
            method: p.method,
            transactionCount: p.transactionCount,
            totalAmount: p.totalAmount,
            percentage: p.percentage > 0 ? p.percentage : pct,
          );
        }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          Translations.get('sales_by_payment', lang),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          ReportDateFilter(
            startDate: state.startDate,
            endDate: state.endDate,
            lang: lang,
            onChanged: (range) {
              ref
                  .read(reportsProvider.notifier)
                  .setDateRange(range.start, range.end);
            },
          ),
          const Divider(height: 1),
          // Total card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  Translations.get('total', lang),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.formatLAKWithSymbol(totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalTxns ${Translations.get('transactions', lang)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Payment list
          Expanded(
            child:
                state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : withPercent.isEmpty
                    ? Center(
                      child: Text(
                        Translations.get('no_data', lang),
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh:
                          () => ref.read(reportsProvider.notifier).refresh(),
                      child: ListView.separated(
                        itemCount: withPercent.length,
                        separatorBuilder:
                            (_, __) => Divider(
                              height: 1,
                              indent: 72,
                              color: Colors.grey.shade100,
                            ),
                        itemBuilder: (_, i) {
                          final p = withPercent[i];
                          final color = _methodColor(p.method);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _methodIcon(p.method),
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Name + count
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.displayName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.transactionCount} ${Translations.get('transactions', lang)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount + percentage
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatLAKWithSymbol(
                                        p.totalAmount,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
