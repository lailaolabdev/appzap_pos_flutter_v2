import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';

/// API service for managing printers on the backend
class PrinterApiService {
  final ApiClient _apiClient;

  PrinterApiService(this._apiClient);

  /// Fetch all printers for a branch
  Future<List<Map<String, dynamic>>> getPrinters(String branchId) async {
    final response = await _apiClient.get(
      ApiConstants.branchPrinters(branchId),
      queryParameters: {'limit': 50},
    );
    final data = response['data'];
    if (data is Map && data['printers'] is List) {
      return List<Map<String, dynamic>>.from(data['printers']);
    }
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// Get a single printer
  Future<Map<String, dynamic>> getPrinter(
    String branchId,
    String printerId,
  ) async {
    final response = await _apiClient.get(
      ApiConstants.branchPrinter(branchId, printerId),
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  /// Create a new printer on the backend
  Future<Map<String, dynamic>> createPrinter(
    String branchId,
    Map<String, dynamic> printerData,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.branchPrinters(branchId),
      data: printerData,
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  /// Update an existing printer
  Future<Map<String, dynamic>> updatePrinter(
    String branchId,
    String printerId,
    Map<String, dynamic> printerData,
  ) async {
    final response = await _apiClient.put(
      ApiConstants.branchPrinter(branchId, printerId),
      data: printerData,
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  /// Delete a printer
  Future<void> deletePrinter(String branchId, String printerId) async {
    await _apiClient.delete(
      ApiConstants.branchPrinter(branchId, printerId),
    );
  }

  /// Test printer connection on the backend
  Future<Map<String, dynamic>> testPrinter(
    String branchId,
    String printerId, {
    String testType = 'connection',
  }) async {
    final response = await _apiClient.post(
      ApiConstants.testPrinter(branchId, printerId),
      data: {'testType': testType},
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  /// Get printer presets
  Future<Map<String, dynamic>> getPresets() async {
    final response = await _apiClient.get(ApiConstants.printerPresets);
    return response['data'] as Map<String, dynamic>? ?? {};
  }
}

/// Provider for PrinterApiService
final printerApiServiceProvider = Provider<PrinterApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PrinterApiService(apiClient);
});
