import 'package:equatable/equatable.dart';

/// Modifier group (e.g. "Size", "Toppings")
class Modifier extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool required;
  final bool multiSelect;
  final int minSelections;
  final int maxSelections;
  final int displayOrder;
  final bool isActive;
  final List<ModifierOption> options;

  const Modifier({
    required this.id,
    required this.name,
    this.description,
    this.required = false,
    this.multiSelect = false,
    this.minSelections = 0,
    this.maxSelections = 1,
    this.displayOrder = 0,
    this.isActive = true,
    this.options = const [],
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      required: json['required'] as bool? ?? false,
      multiSelect: json['multiSelect'] as bool? ?? false,
      minSelections: json['minSelections'] as int? ?? 0,
      maxSelections: json['maxSelections'] as int? ?? 1,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Display subtitle: option names joined
  String get optionsSummary {
    if (options.isEmpty) return '';
    return options.map((o) => o.name).join(', ');
  }

  @override
  List<Object?> get props => [id, name, options];
}

/// Single option within a modifier group
class ModifierOption extends Equatable {
  final String id;
  final String name;
  final double price;
  final double? costPrice;
  final bool isDefault;
  final int displayOrder;

  const ModifierOption({
    required this.id,
    required this.name,
    this.price = 0,
    this.costPrice,
    this.isDefault = false,
    this.displayOrder = 0,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    // optionId can be populated object or string
    final optionData = json['optionId'];
    String id = '';
    String name = '';
    double basePrice = 0;
    double? costPrice;

    if (optionData is Map<String, dynamic>) {
      id = optionData['_id'] as String? ?? '';
      name = optionData['name'] as String? ?? '';
      basePrice = (optionData['basePrice'] as num?)?.toDouble() ?? 0;
      costPrice = (optionData['costPrice'] as num?)?.toDouble();
    } else if (optionData is String) {
      id = optionData;
    }

    // Price override takes priority
    final priceOverride = (json['priceOverride'] as num?)?.toDouble();

    return ModifierOption(
      id: id,
      name: name,
      price: priceOverride ?? basePrice,
      costPrice: (json['costPriceOverride'] as num?)?.toDouble() ?? costPrice,
      isDefault: json['isDefault'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, price];
}
