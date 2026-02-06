import 'package:appzap_pos/core/constants/translations.dart';
import 'package:appzap_pos/core/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../providers/transaction_provider.dart';

class TransactionFilterDialog extends ConsumerStatefulWidget {
  final TransactionFilters currentFilters;

  const TransactionFilterDialog({super.key, required this.currentFilters});

  @override
  ConsumerState<TransactionFilterDialog> createState() =>
      _TransactionFilterDialogState();
}

class _TransactionFilterDialogState
    extends ConsumerState<TransactionFilterDialog> {
  String? _selectedStatus;
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentFilters.status;
    _selectedMethod = widget.currentFilters.method;
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localizationProvider).languageCode;

    return AlertDialog(
      title: Text(Translations.get('filter_transactions', languageCode)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status filter
            Text(
              Translations.get('status', languageCode),
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: Translations.get('all', languageCode),
                  isSelected: _selectedStatus == null,
                  onTap: () => setState(() => _selectedStatus = null),
                ),
                _buildFilterChip(
                  label: Translations.get('completed', languageCode),
                  isSelected: _selectedStatus == 'completed',
                  onTap: () => setState(() => _selectedStatus = 'completed'),
                ),
                _buildFilterChip(
                  label: Translations.get('pending', languageCode),
                  isSelected: _selectedStatus == 'pending',
                  onTap: () => setState(() => _selectedStatus = 'pending'),
                ),
                _buildFilterChip(
                  label: Translations.get('voided', languageCode),
                  isSelected: _selectedStatus == 'voided',
                  onTap: () => setState(() => _selectedStatus = 'voided'),
                ),
                _buildFilterChip(
                  label: Translations.get('refunded', languageCode),
                  isSelected: _selectedStatus == 'refunded',
                  onTap: () => setState(() => _selectedStatus = 'refunded'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Payment method filter
            Text(
              Translations.get('payment_methods', languageCode),
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: Translations.get('all', languageCode),
                  isSelected: _selectedMethod == null,
                  onTap: () => setState(() => _selectedMethod = null),
                ),
                _buildFilterChip(
                  label: Translations.get('cash', languageCode),
                  isSelected: _selectedMethod == 'cash',
                  onTap: () => setState(() => _selectedMethod = 'cash'),
                ),
                _buildFilterChip(
                  label: Translations.get('card', languageCode),
                  isSelected: _selectedMethod == 'card',
                  onTap: () => setState(() => _selectedMethod = 'card'),
                ),
                _buildFilterChip(
                  label: 'JDB QR',
                  isSelected: _selectedMethod == 'bank_qr_jdb',
                  onTap: () => setState(() => _selectedMethod = 'bank_qr_jdb'),
                ),
                _buildFilterChip(
                  label: 'BCEL QR',
                  isSelected: _selectedMethod == 'bank_qr_bcel',
                  onTap: () => setState(() => _selectedMethod = 'bank_qr_bcel'),
                ),
                _buildFilterChip(
                  label: 'LDB QR',
                  isSelected: _selectedMethod == 'bank_qr_ldb',
                  onTap: () => setState(() => _selectedMethod = 'bank_qr_ldb'),
                ),
                _buildFilterChip(
                  label: 'IB QR',
                  isSelected: _selectedMethod == 'bank_qr_ib',
                  onTap: () => setState(() => _selectedMethod = 'bank_qr_ib'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedStatus = null;
              _selectedMethod = null;
            });
          },
          child: Text(Translations.get('clear_all', languageCode)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(Translations.get('cancel', languageCode)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              widget.currentFilters.copyWith(
                status: _selectedStatus,
                method: _selectedMethod,
                clearStatus: _selectedStatus == null,
                clearMethod: _selectedMethod == null,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
          ),
          child: Text(Translations.get('apply', languageCode)),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : AppTheme.neutral300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.neutral700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
