import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/inventory.dart';
import '../../../core/services/inventory_api_service.dart' as api;
import '../providers/inventory_provider.dart';

class StockMovementTracker extends ConsumerStatefulWidget {
  const StockMovementTracker({super.key});

  @override
  ConsumerState<StockMovementTracker> createState() =>
      _StockMovementTrackerState();
}

class _StockMovementTrackerState extends ConsumerState<StockMovementTracker> {
  List<api.StockTransaction> _movements = [];
  bool _isLoading = false;
  String? _selectedItemId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get API client from provider instead of casting inventory service
      final apiService = ref.read(api.inventoryApiServiceProvider);

      final movements = await apiService.getStockHistory(
        itemId: _selectedItemId,
      );

      setState(() {
        _movements = movements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Check if it's a 400 error for missing endpoint
        final errorMessage = e.toString();
        if (errorMessage.contains('400')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Stock transaction history is not available. This feature may not be implemented on the backend yet.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading movements: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movement Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMovements,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing movements from ${_formatDate(_startDate)} to ${_formatDate(_endDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_selectedItemId != null)
                  Chip(
                    label: Text(
                      _getItemName(_selectedItemId!, inventoryState.items),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedItemId = null;
                      });
                      _loadMovements();
                    },
                  ),
              ],
            ),
          ),

          // Movement Statistics
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Movements',
                    _movements.length.toString(),
                    Icons.swap_horiz,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Stock Added',
                    _movements
                        .where((m) => m.operation.toUpperCase() == 'ADD')
                        .fold<int>(0, (sum, m) => sum + m.quantityChanged)
                        .toString(),
                    Icons.add,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Stock Removed',
                    _movements
                        .where((m) => m.operation.toUpperCase() == 'REMOVE')
                        .fold<int>(0, (sum, m) => sum + m.quantityChanged)
                        .toString(),
                    Icons.remove,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Movement List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _movements.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Stock Movements Available',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Stock transaction history will appear here when available.\n'
                            'This feature may require backend API support.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            onPressed: _loadMovements,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _movements.length,
                      itemBuilder: (context, index) {
                        final movement = _movements[index];
                        return _buildMovementCard(
                          movement,
                          inventoryState.items,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementCard(
    api.StockTransaction movement,
    List<InventoryItem> items,
  ) {
    final item = items.firstWhere(
      (item) => item.id == movement.inventoryItemId,
      orElse:
          () => InventoryItem(
            id: movement.inventoryItemId,
            name: 'Unknown Item',
            category: 'Unknown',
            unitOfMeasure: const UnitOfMeasure(
              name: 'Unit',
              abbreviation: 'unit',
              category: 'count',
            ),
            currentStock: 0,
            availableStock: 0,
            minStockLevel: 0,
            maxStockLevel: 0,
            costPerUnit: 0.0,
            restaurantId: '',
            branchId: '',
          ),
    );

    Color operationColor;
    IconData operationIcon;
    String operationText;

    final operationType = movement.operation.toLowerCase();
    switch (operationType) {
      case 'add':
        operationColor = Colors.green;
        operationIcon = Icons.add_circle;
        operationText = 'Added';
        break;
      case 'remove':
        operationColor = Colors.red;
        operationIcon = Icons.remove_circle;
        operationText = 'Removed';
        break;
      case 'set':
        operationColor = Colors.blue;
        operationIcon = Icons.edit;
        operationText = 'Set to';
        break;
      default:
        operationColor = Colors.grey;
        operationIcon = Icons.help;
        operationText = 'Unknown';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: operationColor.withOpacity(0.1),
          child: Icon(operationIcon, color: operationColor),
        ),
        title: Text(
          movement.inventoryItemName.isNotEmpty
              ? movement.inventoryItemName
              : item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$operationText ${movement.quantityChanged} ${item.unit}'),
            const SizedBox(height: 4),
            Text(
              movement.reason.isNotEmpty
                  ? movement.reason
                  : 'No reason provided',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  movement.userName.isNotEmpty ? movement.userName : 'System',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(movement.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${movement.quantityBefore} → ${movement.quantityAfter}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              movement.operation.toUpperCase(),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Filter Movements'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Item Selection
                        DropdownButtonFormField<String>(
                          value: _selectedItemId,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Item',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Items'),
                            ),
                            ...ref
                                .read(inventoryProvider)
                                .items
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item.id,
                                    child: Text(item.name),
                                  ),
                                ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedItemId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date Range
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                controller: TextEditingController(
                                  text: _formatDate(_startDate),
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      _startDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                controller: TextEditingController(
                                  text: _formatDate(_endDate),
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      _endDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _loadMovements();
                      },
                      child: const Text('Apply Filter'),
                    ),
                  ],
                ),
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getItemName(String itemId, List<InventoryItem> items) {
    final item = items.firstWhere(
      (item) => item.id == itemId,
      orElse:
          () => InventoryItem(
            id: itemId,
            name: 'Unknown Item',
            category: 'Unknown',
            unitOfMeasure: const UnitOfMeasure(
              name: 'Unit',
              abbreviation: 'unit',
              category: 'count',
            ),
            currentStock: 0,
            availableStock: 0,
            minStockLevel: 0,
            maxStockLevel: 0,
            costPerUnit: 0.0,
            restaurantId: '',
            branchId: '',
          ),
    );
    return item.name;
  }
}
