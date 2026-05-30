import 'package:QUIK/modules/engineering/bom/widgets/bom_dimension_visibility.dart';

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
  static const micron = 'micron';
  static const weight = 'weight';
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
  final bool mandatory;

  const BomColumnDefinition({
    required this.key,
    required this.label,
    required this.width,
    this.mandatory = false,
  });
}

class BomColumnConfig {
  const BomColumnConfig._();

  static const customPrefix = 'custom:';

  static const all = [
    BomColumnDefinition(
      key: BomColumnKey.description,
      label: 'Description',
      width: 220,
      mandatory: true,
    ),
    BomColumnDefinition(
      key: BomColumnKey.sectionCode,
      label: 'Section Code',
      width: 150,
      mandatory: true,
    ),
    BomColumnDefinition(
      key: BomColumnKey.category,
      label: 'Category',
      width: 130,
    ),
    BomColumnDefinition(
      key: BomColumnKey.materialName,
      label: 'Material',
      width: 180,
    ),
    BomColumnDefinition(
      key: BomColumnKey.qtyPerStructure,
      label: 'Qty/Structure',
      width: 100,
      mandatory: true,
    ),
    BomColumnDefinition(
      key: BomColumnKey.lengthMm,
      label: 'Length mm',
      width: 120,
      mandatory: true,
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
      label: 'Coating',
      width: 130,
    ),
    BomColumnDefinition(key: BomColumnKey.micron, label: 'Micron', width: 110),
    BomColumnDefinition(
      key: BomColumnKey.weight,
      label: 'Weight',
      width: 140,
      mandatory: true,
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
    'Solar Structure': [
      BomColumnKey.description,
      BomColumnKey.sectionCode,
      BomColumnKey.materialName,
      BomColumnKey.qtyPerStructure,
      BomColumnKey.lengthMm,
      BomColumnKey.kgPerM,
      BomColumnKey.grade,
      BomColumnKey.coating,
      BomColumnKey.micron,
      BomColumnKey.weight,
    ],
    'Plate/Fabrication': [
      BomColumnKey.description,
      BomColumnKey.sectionCode,
      BomColumnKey.category,
      BomColumnKey.materialName,
      BomColumnKey.qtyPerStructure,
      BomColumnKey.lengthMm,
      BomColumnKey.widthMm,
      BomColumnKey.thicknessMm,
      BomColumnKey.grade,
      BomColumnKey.weight,
      BomColumnKey.remarks,
    ],
    'Pipe': [
      BomColumnKey.description,
      BomColumnKey.sectionCode,
      BomColumnKey.category,
      BomColumnKey.materialName,
      BomColumnKey.qtyPerStructure,
      BomColumnKey.lengthMm,
      BomColumnKey.odMm,
      BomColumnKey.thicknessMm,
      BomColumnKey.kgPerM,
      BomColumnKey.grade,
      BomColumnKey.weight,
    ],
    'Tower/Angle': [
      BomColumnKey.description,
      BomColumnKey.sectionCode,
      BomColumnKey.category,
      BomColumnKey.materialName,
      BomColumnKey.qtyPerStructure,
      BomColumnKey.lengthMm,
      BomColumnKey.kgPerM,
      BomColumnKey.grade,
      BomColumnKey.coating,
      BomColumnKey.weight,
    ],
    'Custom': [
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
      BomColumnKey.coating,
      BomColumnKey.micron,
      BomColumnKey.weight,
      BomColumnKey.remarks,
    ],
  };

  static String customKey(String id) => '$customPrefix$id';
  static bool isCustomKey(String key) => key.startsWith(customPrefix);
  static String customId(String key) => key.substring(customPrefix.length);

  static List<String> sanitize(List<String> columns) {
    final known = all.map((c) => c.key).toSet();
    final next = <String>{
      ...mandatory,
      ...columns.where((key) => known.contains(key) || isCustomKey(key)),
    };
    return [
      ...all.where((c) => next.contains(c.key)).map((c) => c.key),
      ...columns.where((key) => isCustomKey(key) && next.contains(key)),
    ];
  }

  static List<String> withCategoryFields(
    List<String> columns,
    String category,
  ) {
    final visibility = BomDimensionVisibility.forCategory(category);
    final auto = <String>[
      if (visibility.width) BomColumnKey.widthMm,
      if (visibility.thickness) BomColumnKey.thicknessMm,
      if (visibility.od) BomColumnKey.odMm,
      if (visibility.id) BomColumnKey.idMm,
      if (visibility.height) BomColumnKey.heightMm,
    ];
    return sanitize([...columns, ...auto]);
  }

  static double tableWidth(
    List<String> columns,
    List<BomCustomField> customFields,
  ) {
    final content = sanitize(columns).fold<double>(
      42 + 60,
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
