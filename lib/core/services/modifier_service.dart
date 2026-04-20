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

  /// List all modifier groups (customizations)
  Future<List<Modifier>> getModifiers() async {
    final response = await _apiClient.get(
      ApiConstants.customizations,
      queryParameters: {
        if (_restaurantId != null) 'restaurantId': _restaurantId,
        'isActive': 'true',
        'limit': 200,
      },
    );

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
  /// 1. Creates each Option via POST /options
  /// 2. Creates the Customization referencing those option IDs
  Future<Modifier> createModifier({
    required String name,
    String? description,
    bool required = false,
    bool multiSelect = false,
    int minSelections = 0,
    int maxSelections = 1,
    required List<Map<String, dynamic>> options,
  }) async {
    // Step 1: Create each option
    final optionRefs = <Map<String, dynamic>>[];

    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      final optName = (opt['name'] as String?)?.trim() ?? '';
      if (optName.isEmpty) continue;

      final optResponse = await _apiClient.post(
        ApiConstants.options,
        data: {
          'name': optName,
          'basePrice': opt['price'] ?? 0,
          if (_restaurantId != null) 'restaurantId': _restaurantId,
        },
      );
      final optData =
          optResponse['data'] as Map<String, dynamic>? ?? optResponse;
      final optId = optData['_id'] as String? ?? '';
      if (optId.isNotEmpty) {
        optionRefs.add({
          'optionId': optId,
          'priceOverride': opt['price'] ?? 0,
          'displayOrder': i,
        });
      }
    }

    // Step 2: Create the customization group
    final response = await _apiClient.post(
      ApiConstants.customizations,
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        'required': required,
        'multiSelect': multiSelect,
        'minSelections': minSelections,
        'maxSelections': multiSelect ? maxSelections : 1,
        if (_restaurantId != null) 'restaurantId': _restaurantId,
        'options': optionRefs,
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    return Modifier.fromJson(data);
  }

  /// Update a modifier group and its options
  /// - Updates existing options via PATCH /options/:id
  /// - Creates new options via POST /options
  /// - Rebuilds the options list on the customization
  Future<Modifier> updateModifier({
    required String id,
    String? name,
    String? description,
    bool? required,
    bool? multiSelect,
    int? minSelections,
    int? maxSelections,
    List<Map<String, dynamic>>? options,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (required != null) body['required'] = required;
    if (multiSelect != null) body['multiSelect'] = multiSelect;
    if (minSelections != null) body['minSelections'] = minSelections;
    if (maxSelections != null) {
      body['maxSelections'] = (multiSelect ?? false) ? maxSelections : 1;
    }

    // If options provided, update/create them and rebuild the list
    if (options != null) {
      final optionRefs = <Map<String, dynamic>>[];

      for (int i = 0; i < options.length; i++) {
        final opt = options[i];
        final optName = (opt['name'] as String?)?.trim() ?? '';
        if (optName.isEmpty) continue;

        final existingId = opt['id'] as String?;
        final price = opt['price'] ?? 0;

        if (existingId != null && existingId.isNotEmpty) {
          // Update existing option
          try {
            await _apiClient.patch(
              '${ApiConstants.options}/$existingId',
              data: {
                'name': optName,
                'basePrice': price,
              },
            );
          } catch (_) {
            // If update fails, still reference it
          }
          optionRefs.add({
            'optionId': existingId,
            'priceOverride': price,
            'displayOrder': i,
          });
        } else {
          // Create new option
          final optResponse = await _apiClient.post(
            ApiConstants.options,
            data: {
              'name': optName,
              'basePrice': price,
              if (_restaurantId != null) 'restaurantId': _restaurantId,
            },
          );
          final optData =
              optResponse['data'] as Map<String, dynamic>? ?? optResponse;
          final optId = optData['_id'] as String? ?? '';
          if (optId.isNotEmpty) {
            optionRefs.add({
              'optionId': optId,
              'priceOverride': price,
              'displayOrder': i,
            });
          }
        }
      }

      body['options'] = optionRefs;
    }

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

  /// Delete a single option
  Future<void> deleteOption(String optionId) async {
    await _apiClient.delete('${ApiConstants.options}/$optionId');
  }
}
