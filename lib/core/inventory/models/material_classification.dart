class RawMaterialCategory {
  const RawMaterialCategory({required this.key, required this.label});

  final String key;
  final String label;
}

class ProductFamily {
  const ProductFamily({required this.key, required this.label});

  final String key;
  final String label;
}

class MaterialClassification {
  static const List<RawMaterialCategory> rawMaterialCategories = [
    RawMaterialCategory(key: 'ms_angle', label: 'MS Angle'),
    RawMaterialCategory(key: 'ms_channel', label: 'MS Channel'),
    RawMaterialCategory(key: 'ms_pipe', label: 'MS Pipe'),
    RawMaterialCategory(key: 'ms_plate', label: 'MS Plate'),
    RawMaterialCategory(key: 'ms_coil', label: 'MS Coil'),
    RawMaterialCategory(key: 'ms_flat', label: 'MS Flat'),
    RawMaterialCategory(key: 'ms_round', label: 'MS Round'),
    RawMaterialCategory(key: 'ms_t_channel', label: 'MS T Channel'),
    RawMaterialCategory(key: 'gi_hardware', label: 'GI Hardware'),
  ];

  static const List<ProductFamily> productFamilies = [
    ProductFamily(key: 'angular_tower', label: 'Angular Tower'),
    ProductFamily(key: 'delta_tower', label: 'Delta Tower'),
    ProductFamily(key: 'rtp_pole', label: 'RTP Pole'),
    ProductFamily(key: 'cable_tray', label: 'Cable Tray'),
    ProductFamily(key: 'foundation_bolts', label: 'Foundation Bolts'),
    ProductFamily(key: 'solar_structure', label: 'Solar Structure'),
    ProductFamily(key: 'railway_structure', label: 'Railway Structure'),
    ProductFamily(key: 'transmission_tower', label: 'Transmission Tower'),
  ];

  static const Map<String, List<String>> productFamilyRawMaterialMap = {
    'angular_tower': [
      'ms_angle',
      'ms_plate',
      'ms_flat',
      'ms_round',
      'gi_hardware',
    ],
    'delta_tower': [
      'ms_angle',
      'ms_channel',
      'ms_plate',
      'ms_flat',
      'gi_hardware',
    ],
    'rtp_pole': ['ms_pipe', 'ms_plate', 'ms_coil', 'ms_round', 'gi_hardware'],
    'cable_tray': ['ms_plate', 'ms_coil', 'ms_flat', 'gi_hardware'],
    'foundation_bolts': ['ms_round', 'ms_plate', 'gi_hardware'],
    'solar_structure': [
      'ms_channel',
      'ms_pipe',
      'ms_plate',
      'ms_t_channel',
      'gi_hardware',
    ],
    'railway_structure': [
      'ms_angle',
      'ms_channel',
      'ms_plate',
      'ms_flat',
      'gi_hardware',
    ],
    'transmission_tower': [
      'ms_angle',
      'ms_channel',
      'ms_plate',
      'ms_flat',
      'ms_round',
      'gi_hardware',
    ],
  };

  static String rawMaterialLabel(String key) {
    return rawMaterialCategories
        .firstWhere(
          (category) => category.key == key,
          orElse: () => RawMaterialCategory(key: key, label: key),
        )
        .label;
  }

  static String productFamilyLabel(String key) {
    return productFamilies
        .firstWhere(
          (family) => family.key == key,
          orElse: () => ProductFamily(key: key, label: key),
        )
        .label;
  }

  static List<RawMaterialCategory> rawMaterialsForFamily(String familyKey) {
    final rawMaterialKeys = productFamilyRawMaterialMap[familyKey] ?? const [];
    return rawMaterialCategories
        .where((category) => rawMaterialKeys.contains(category.key))
        .toList(growable: false);
  }

  static bool isRawMaterialMappedToFamily({
    required String rawMaterialCategoryKey,
    required String productFamilyKey,
  }) {
    final mapped = productFamilyRawMaterialMap[productFamilyKey] ?? const [];
    return mapped.contains(rawMaterialCategoryKey);
  }

  const MaterialClassification._();
}
