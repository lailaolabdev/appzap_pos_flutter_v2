import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/modifier.dart';
import '../../features/auth/providers/auth_provider.dart';

final modifierServiceProvider = Provider<ModifierService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final restaurantId = ref.watch(currentRestaurantIdProvider);
  return ModifierService(apiClient, restaurantId);
});

class ModifierService {
  final ApiClient _apiClient;
  final String? _restaurantId;

  ModifierService(this._apiClient, this._restaurantId);

  /// List all modifier groups
  Future<List<Modifier>> getModifiers() async {
    final response = await _apiClient.get(
      ApiConstants.customizations,
      queryParameters: {
        if (_restaurantId != null) 'restaurantId': _restaurantId,
        'isActive': 'true',
        'limit': 200,
      },
    );

    // Response could be: { success, data: { results: [...] } }
    // or: { success, data: [...] } depending on endpoint
    final rawData = response['data'];
    List<dynamic> results = [];

    if (rawData is Map<String, dynamic>) {
      results = rawData['results'] as List<dynamic>? ?? [];
    } else if (rawData is List<dynamic>) {
      results = rawData;
    }

    return results
        .map((e) => Modifier.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a modifier group with inline options
  Future<Modifier> createModifier({
    required String name,
    String? description,
    bool required = false,
    bool multiSelect = false,
    int minSelections = 0,
    int maxSelections = 1,
    required List<Map<String, dynamic>> options,
  }) async {
    // First create options, then create customization referencing them
    final optionIds = <Map<String, dynamic>>[];

    for (final opt in options) {
      final optResponse = await _apiClient.post(
        ApiConstants.options,
        data: {
          'name': opt['name'],
          'basePrice': opt['price'] ?? 0,
          if (_restaurantId != null) 'restaurantId': _restaurantId,
        },
      );
      final optData = optResponse['data'] as Map<String, dynamic>? ?? optResponse;
      final optId = optData['_id'] as String? ?? '';
      if (optId.isNotEmpty) {
        optionIds.add({
          'optionId': optId,
          'priceOverride': opt['price'] ?? 0,
          'displayOrder': optionIds.length,
        });
      }
    }

    final response = await _apiClient.post(
      ApiConstants.customizations,
      data: {
        'name': name,
        if (description != null) 'description': description,
        'required': required,
        'multiSelect': multiSelect,
        'minSelections': minSelections,
        'maxSelections': maxSelections,
        if (_restaurantId != null) 'restaurantId': _restaurantId,
        'options': optionIds,
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    return Modifier.fromJson(data);
  }

  /// Update a modifier group
  Future<Modifier> updateModifier({
    required String id,
    String? name,
    String? description,
    bool? required,
    bool? multiSelect,
    int? minSelections,
    int? maxSelections,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (required != null) body['required'] = required;
    if (multiSelect != null) body['multiSelect'] = multiSelect;
    if (minSelections != null) body['minSelections'] = minSelections;
    if (maxSelections != null) body['maxSelections'] = maxSelections;

    final response = await _apiClient.patch(
      '${ApiConstants.customizations}/$id',
      data: body,
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    return Modifier.fromJson(data);
  }

  /// Delete a modifier group
  Future<void> deleteModifier(String id) async {
    await _apiClient.delete('${ApiConstants.customizations}/$id');
  }
}
