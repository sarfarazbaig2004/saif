class BomColumnKey {
  static const description = 'description';
  static const sectionCode = 'sectionCode';
  static const category = 'category';
  static const materialName = 'materialName';
  static const qtyPerStructure = 'qtyPerStructure';
  static const lengthMm = 'lengthMm';
  static const widthMm = 'widthMm';
  static const thicknessMm = 'thicknessMm';
  static const odMm = 'odMm';
  static const idMm = 'idMm';
  static const heightMm = 'heightMm';
  static const kgPerM = 'kgPerM';
  static const grade = 'grade';
  static const coating = 'coating';
  static const coatingSpec = 'coatingSpec';
  static const yieldStrength = 'yieldStrength';
  static const micron = 'micron';
  static const weight = 'weight';
  static const projectQty = 'projectQty';
  static const projectWeight = 'projectWeight';
  static const formula = 'formula';
  static const steelWeight = 'steelWeight';
  static const galvanisingWeight = 'galvanisingWeight';
  static const remarks = 'remarks';
}

class BomCustomField {
  final String id;
  final String name;
  final String type;

  const BomCustomField({
    required this.id,
    required this.name,
    required this.type,
  });

  factory BomCustomField.fromMap(Map<String, dynamic> map) {
    return BomCustomField(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? 'Text').toString(),
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'type': type};

  BomCustomField copyWith({String? name, String? type}) {
    return BomCustomField(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}

class BomFieldConfigResult {
  final List<String> visibleColumns;
  final List<BomCustomField> customFields;

  const BomFieldConfigResult({
    required this.visibleColumns,
    required this.customFields,
  });
}

class BomColumnDefinition {
  final String key;
  final String label;
  final double width;

  const BomColumnDefinition({
    required this.key,
    required this.label,
    required this.width,
  });

  bool get mandatory => BomColumnConfig.mandatory.contains(key);
}

class BomColumnConfig {
  const BomColumnConfig._();

  static const customPrefix = 'custom:';

  static const all = [
    BomColumnDefinition(
      key: BomColumnKey.description,
      label: 'Drawing Name',
      width: 220,
    ),
    BomColumnDefinition(
      key: BomColumnKey.sectionCode,
      label: 'Section',
      width: 150,
    ),
    BomColumnDefinition(
      key: BomColumnKey.category,
      label: 'Category',
      width: 130,
    ),
    BomColumnDefinition(
      key: BomColumnKey.materialName,
      label: 'Material Name',
      width: 180,
    ),
    BomColumnDefinition(
      key: BomColumnKey.qtyPerStructure,
      label: 'Qty/Table',
      width: 100,
    ),
    BomColumnDefinition(
      key: BomColumnKey.lengthMm,
      label: 'Length mm',
      width: 120,
    ),
    BomColumnDefinition(key: BomColumnKey.widthMm, label: 'Width', width: 100),
    BomColumnDefinition(
      key: BomColumnKey.thicknessMm,
      label: 'Thick',
      width: 100,
    ),
    BomColumnDefinition(key: BomColumnKey.odMm, label: 'OD/Dia', width: 100),
    BomColumnDefinition(key: BomColumnKey.idMm, label: 'ID', width: 100),
    BomColumnDefinition(
      key: BomColumnKey.heightMm,
      label: 'Height',
      width: 100,
    ),
    BomColumnDefinition(key: BomColumnKey.kgPerM, label: 'Kg/m', width: 100),
    BomColumnDefinition(key: BomColumnKey.grade, label: 'Grade', width: 120),
    BomColumnDefinition(
      key: BomColumnKey.coating,
      label: 'Material',
      width: 130,
    ),
    BomColumnDefinition(
      key: BomColumnKey.coatingSpec,
      label: 'Galvanisation Thickness / Coating Spec',
      width: 220,
    ),
    BomColumnDefinition(
      key: BomColumnKey.yieldStrength,
      label: 'Yield Strength as per IS 2062-2011',
      width: 230,
    ),
    BomColumnDefinition(key: BomColumnKey.micron, label: 'Micron', width: 110),
    BomColumnDefinition(
      key: BomColumnKey.weight,
      label: 'Weight per structure including galvanising (kg)',
      width: 240,
    ),
    BomColumnDefinition(
      key: BomColumnKey.projectQty,
      label: 'Qty for Project',
      width: 130,
    ),
    BomColumnDefinition(
      key: BomColumnKey.projectWeight,
      label: 'Weight for Project (kg)',
      width: 170,
    ),
    BomColumnDefinition(
      key: BomColumnKey.formula,
      label: 'Formula',
      width: 160,
    ),
    BomColumnDefinition(
      key: BomColumnKey.steelWeight,
      label: 'Steel Weight',
      width: 130,
    ),
    BomColumnDefinition(
      key: BomColumnKey.galvanisingWeight,
      label: 'Galvanising Weight',
      width: 160,
    ),
    BomColumnDefinition(
      key: BomColumnKey.remarks,
      label: 'Remarks',
      width: 180,
    ),
  ];

  static const mandatory = [
    BomColumnKey.description,
    BomColumnKey.sectionCode,
    BomColumnKey.qtyPerStructure,
    BomColumnKey.lengthMm,
    BomColumnKey.weight,
  ];

  static const presets = {
    'Customer BOM Format': [
      BomColumnKey.description,
      BomColumnKey.sectionCode,
      BomColumnKey.coating,
      BomColumnKey.coatingSpec,
      BomColumnKey.yieldStrength,
      BomColumnKey.qtyPerStructure,
      BomColumnKey.lengthMm,
      BomColumnKey.weight,
      BomColumnKey.projectQty,
      BomColumnKey.projectWeight,
    ],
    'Internal Engineering Format': [
      BomColumnKey.description,
      BomColumnKey.sectionCode,
      BomColumnKey.category,
      BomColumnKey.materialName,
      BomColumnKey.qtyPerStructure,
      BomColumnKey.lengthMm,
      BomColumnKey.kgPerM,
      BomColumnKey.grade,
      BomColumnKey.coating,
      BomColumnKey.coatingSpec,
      BomColumnKey.weight,
      BomColumnKey.projectWeight,
    ],
    'Advanced Format': [
      BomColumnKey.description,
      BomColumnKey.sectionCode,
      BomColumnKey.category,
      BomColumnKey.materialName,
      BomColumnKey.qtyPerStructure,
      BomColumnKey.lengthMm,
      BomColumnKey.widthMm,
      BomColumnKey.thicknessMm,
      BomColumnKey.odMm,
      BomColumnKey.idMm,
      BomColumnKey.heightMm,
      BomColumnKey.kgPerM,
      BomColumnKey.grade,
      BomColumnKey.yieldStrength,
      BomColumnKey.coating,
      BomColumnKey.coatingSpec,
      BomColumnKey.weight,
      BomColumnKey.projectQty,
      BomColumnKey.projectWeight,
      BomColumnKey.formula,
      BomColumnKey.steelWeight,
      BomColumnKey.galvanisingWeight,
      BomColumnKey.remarks,
    ],
  };

  static String customKey(String id) => '$customPrefix$id';
  static bool isCustomKey(String key) => key.startsWith(customPrefix);
  static String customId(String key) => key.substring(customPrefix.length);

  static List<String> sanitize(List<String> columns) {
    final known = all.map((c) => c.key).toSet();
    final next = <String>[];
    for (final key in columns) {
      if ((known.contains(key) || isCustomKey(key)) && !next.contains(key)) {
        next.add(key);
      }
    }
    for (var i = 0; i < mandatory.length; i++) {
      if (!next.contains(mandatory[i])) next.insert(i, mandatory[i]);
    }
    return next;
  }

  static double tableWidth(
    List<String> columns,
    List<BomCustomField> customFields,
  ) {
    final content = sanitize(columns).fold<double>(
      64 + 60,
      (total, key) => total + definitionFor(key, customFields).width,
    );
    return content < 2400 ? 2400 : content;
  }

  static BomColumnDefinition definitionFor(
    String key,
    List<BomCustomField> customFields,
  ) {
    if (isCustomKey(key)) {
      final id = customId(key);
      BomCustomField? field;
      for (final customField in customFields) {
        if (customField.id == id) field = customField;
      }
      return BomColumnDefinition(
        key: key,
        label: field != null && field.name.isNotEmpty
            ? field.name
            : 'Custom Field',
        width: 180,
      );
    }
    return all.firstWhere((column) => column.key == key);
  }
}
