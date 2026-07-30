import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/engineering/bom/services/bom_weight_engine.dart';
import 'package:QUIK/modules/production/core/production_firestore_utils.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_model.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_repository.dart';


class ItemSubcategoryDefinition {
  const ItemSubcategoryDefinition({
    required this.name,
    required this.code,
    required this.attributeTemplateKey,
    required this.measurementProfileKey,
  });

  final String name;
  final String code;
  final String attributeTemplateKey;
  final String measurementProfileKey;

  factory ItemSubcategoryDefinition.fromMap(Map<String, dynamic> map) {
    return ItemSubcategoryDefinition(
      name: (map['name'] ?? '').toString().trim(),
      code: (map['code'] ?? '').toString().trim().toUpperCase(),
      attributeTemplateKey:
      (map['attributeTemplateKey'] ?? 'generic').toString().trim(),
      measurementProfileKey:
      (map['measurementProfileKey'] ?? 'COUNT').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'code': code.trim().toUpperCase(),
    'attributeTemplateKey': attributeTemplateKey.trim(),
    'measurementProfileKey': measurementProfileKey.trim(),
  };
}

class ItemCategoryDefinition {
  const ItemCategoryDefinition({
    required this.nature,
    required this.name,
    required this.code,
    required this.subcategories,
    this.isActive = true,
  });

  final String nature;
  final String name;
  final String code;
  final List<ItemSubcategoryDefinition> subcategories;
  final bool isActive;

  factory ItemCategoryDefinition.fromMap(Map<String, dynamic> map) {
    final raw = map['subcategories'];
    return ItemCategoryDefinition(
      nature: (map['nature'] ?? 'Other').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      code: (map['code'] ?? '').toString().trim().toUpperCase(),
      subcategories: raw is Iterable
          ? raw
          .whereType<Map>()
          .map(
            (entry) => ItemSubcategoryDefinition.fromMap(
          Map<String, dynamic>.from(entry),
        ),
      )
          .where((entry) => entry.name.isNotEmpty)
          .toList(growable: false)
          : const <ItemSubcategoryDefinition>[],
      isActive: map['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
    'nature': nature.trim(),
    'name': name.trim(),
    'code': code.trim().toUpperCase(),
    'subcategories': subcategories
        .map((entry) => entry.toMap())
        .toList(growable: false),
    'isActive': isActive,
  };
}

class UomDefinition {
  const UomDefinition({
    required this.code,
    required this.name,
    required this.dimension,
    this.decimalPlaces = 3,
    this.isActive = true,
  });

  final String code;
  final String name;
  final String dimension;
  final int decimalPlaces;
  final bool isActive;

  factory UomDefinition.fromMap(Map<String, dynamic> map) {
    return UomDefinition(
      code: (map['code'] ?? '').toString().trim().toUpperCase(),
      name: (map['name'] ?? '').toString().trim(),
      dimension: (map['dimension'] ?? 'Count').toString().trim(),
      decimalPlaces: (map['decimalPlaces'] is num)
          ? (map['decimalPlaces'] as num).toInt().clamp(0, 6).toInt()
          : 3,
      isActive: map['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
    'code': code.trim().toUpperCase(),
    'name': name.trim(),
    'dimension': dimension.trim(),
    'decimalPlaces': decimalPlaces.clamp(0, 6),
    'isActive': isActive,
  };
}

class MeasurementProfileDefinition {
  const MeasurementProfileDefinition({
    required this.key,
    required this.name,
    required this.baseUom,
    required this.purchaseUom,
    required this.issueUom,
    required this.secondaryUom,
    required this.conversionMethod,
    this.defaultFactor = 1,
    this.isActive = true,
  });

  final String key;
  final String name;
  final String baseUom;
  final String purchaseUom;
  final String issueUom;
  final String secondaryUom;
  final String conversionMethod;
  final double defaultFactor;
  final bool isActive;

  factory MeasurementProfileDefinition.fromMap(Map<String, dynamic> map) {
    return MeasurementProfileDefinition(
      key: (map['key'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      baseUom: (map['baseUom'] ?? 'NOS').toString().trim().toUpperCase(),
      purchaseUom:
      (map['purchaseUom'] ?? map['baseUom'] ?? 'NOS')
          .toString()
          .trim()
          .toUpperCase(),
      issueUom:
      (map['issueUom'] ?? map['baseUom'] ?? 'NOS')
          .toString()
          .trim()
          .toUpperCase(),
      secondaryUom:
      (map['secondaryUom'] ?? '').toString().trim().toUpperCase(),
      conversionMethod:
      (map['conversionMethod'] ?? 'Fixed').toString().trim(),
      defaultFactor: map['defaultFactor'] is num
          ? (map['defaultFactor'] as num).toDouble()
          : 1,
      isActive: map['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
    'key': key.trim(),
    'name': name.trim(),
    'baseUom': baseUom.trim().toUpperCase(),
    'purchaseUom': purchaseUom.trim().toUpperCase(),
    'issueUom': issueUom.trim().toUpperCase(),
    'secondaryUom': secondaryUom.trim().toUpperCase(),
    'conversionMethod': conversionMethod.trim(),
    'defaultFactor': defaultFactor,
    'isActive': isActive,
  };
}

class ItemMasterConfiguration {
  const ItemMasterConfiguration({
    required this.categories,
    required this.uoms,
    required this.measurementProfiles,
  });

  final List<ItemCategoryDefinition> categories;
  final List<UomDefinition> uoms;
  final List<MeasurementProfileDefinition> measurementProfiles;

  factory ItemMasterConfiguration.fromMap(Map<String, dynamic> map) {
    final defaults = ItemMasterConfiguration.defaults();
    final categoryRaw = map['categories'];
    final uomRaw = map['uoms'];
    final profileRaw = map['measurementProfiles'];

    final savedCategories = categoryRaw is Iterable
        ? categoryRaw
        .whereType<Map>()
        .map(
          (entry) => ItemCategoryDefinition.fromMap(
        Map<String, dynamic>.from(entry),
      ),
    )
        .where((entry) => entry.name.isNotEmpty)
        .toList(growable: false)
        : const <ItemCategoryDefinition>[];

    final savedUoms = uomRaw is Iterable
        ? uomRaw
        .whereType<Map>()
        .map(
          (entry) => UomDefinition.fromMap(
        Map<String, dynamic>.from(entry),
      ),
    )
        .where((entry) => entry.code.isNotEmpty)
        .toList(growable: false)
        : const <UomDefinition>[];

    final savedProfiles = profileRaw is Iterable
        ? profileRaw
        .whereType<Map>()
        .map(
          (entry) => MeasurementProfileDefinition.fromMap(
        Map<String, dynamic>.from(entry),
      ),
    )
        .where((entry) => entry.key.isNotEmpty)
        .toList(growable: false)
        : const <MeasurementProfileDefinition>[];

    return ItemMasterConfiguration(
      categories: _mergeCategories(defaults.categories, savedCategories),
      uoms: _mergeUoms(defaults.uoms, savedUoms),
      measurementProfiles: _mergeProfiles(
        defaults.measurementProfiles,
        savedProfiles,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'categories': categories.map((entry) => entry.toMap()).toList(),
    'uoms': uoms.map((entry) => entry.toMap()).toList(),
    'measurementProfiles': measurementProfiles
        .map((entry) => entry.toMap())
        .toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  List<ItemCategoryDefinition> categoriesForNature(String nature) {
    final normalizedNature = nature.trim().toLowerCase();
    final result = categories
        .where(
          (entry) =>
      entry.isActive &&
          entry.nature.trim().toLowerCase() == normalizedNature,
    )
        .map(_ensureCategoryHasSubcategory)
        .toList(growable: false);

    return result;
  }

  ItemCategoryDefinition? categoryByName(String nature, String name) {
    final normalized = name.trim().toLowerCase();
    for (final entry in categoriesForNature(nature)) {
      if (entry.name.toLowerCase() == normalized) return entry;
    }
    return null;
  }

  List<ItemSubcategoryDefinition> subcategoriesFor(
      ItemCategoryDefinition? category,
      ) {
    if (category == null) return const <ItemSubcategoryDefinition>[];
    return [..._ensureCategoryHasSubcategory(category).subcategories];
  }

  ItemSubcategoryDefinition? subcategoryByName(
      ItemCategoryDefinition? category,
      String name,
      ) {
    final normalized = name.trim().toLowerCase();
    for (final entry in subcategoriesFor(category)) {
      if (entry.name.toLowerCase() == normalized) return entry;
    }
    return null;
  }

  MeasurementProfileDefinition? profileByKey(String key) {
    final normalized = key.trim().toLowerCase();
    for (final entry in measurementProfiles) {
      if (entry.isActive && entry.key.toLowerCase() == normalized) return entry;
    }
    return null;
  }

  static List<ItemCategoryDefinition> _mergeCategories(
      List<ItemCategoryDefinition> defaults,
      List<ItemCategoryDefinition> saved,
      ) {
    final merged = <String, ItemCategoryDefinition>{};

    for (final category in defaults) {
      merged[_categoryKey(category.nature, category.name)] =
          _ensureCategoryHasSubcategory(category);
    }

    for (final category in saved) {
      final key = _categoryKey(category.nature, category.name);
      final defaultCategory = merged[key];
      final subcategories = _mergeSubcategories(
        defaultCategory?.subcategories ?? const <ItemSubcategoryDefinition>[],
        category.subcategories,
      );

      merged[key] = _ensureCategoryHasSubcategory(
        ItemCategoryDefinition(
          nature: category.nature,
          name: category.name,
          code: category.code.isEmpty
              ? defaultCategory?.code ?? _codeFromName(category.name)
              : category.code,
          subcategories: subcategories,
          isActive: category.isActive,
        ),
      );
    }

    return merged.values.toList(growable: false);
  }

  static List<ItemSubcategoryDefinition> _mergeSubcategories(
      List<ItemSubcategoryDefinition> defaults,
      List<ItemSubcategoryDefinition> saved,
      ) {
    final merged = <String, ItemSubcategoryDefinition>{};
    for (final entry in defaults) {
      merged[entry.name.trim().toLowerCase()] = entry;
    }
    for (final entry in saved) {
      merged[entry.name.trim().toLowerCase()] = ItemSubcategoryDefinition(
        name: entry.name,
        code: entry.code.isEmpty ? _codeFromName(entry.name) : entry.code,
        attributeTemplateKey: entry.attributeTemplateKey.isEmpty
            ? 'generic'
            : entry.attributeTemplateKey,
        measurementProfileKey: entry.measurementProfileKey.isEmpty
            ? 'COUNT'
            : entry.measurementProfileKey,
      );
    }
    return merged.values.toList(growable: false);
  }

  static List<UomDefinition> _mergeUoms(
      List<UomDefinition> defaults,
      List<UomDefinition> saved,
      ) {
    final merged = <String, UomDefinition>{
      for (final entry in defaults) entry.code.toUpperCase(): entry,
    };
    for (final entry in saved) {
      merged[entry.code.toUpperCase()] = entry;
    }
    final values = merged.values.toList(growable: false)
      ..sort((a, b) => a.code.compareTo(b.code));
    return values;
  }

  static List<MeasurementProfileDefinition> _mergeProfiles(
      List<MeasurementProfileDefinition> defaults,
      List<MeasurementProfileDefinition> saved,
      ) {
    final merged = <String, MeasurementProfileDefinition>{
      for (final entry in defaults) entry.key.toUpperCase(): entry,
    };
    for (final entry in saved) {
      merged[entry.key.toUpperCase()] = entry;
    }
    final values = merged.values.toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return values;
  }

  static ItemCategoryDefinition _ensureCategoryHasSubcategory(
      ItemCategoryDefinition category,
      ) {
    if (category.subcategories.isNotEmpty) return category;
    return ItemCategoryDefinition(
      nature: category.nature,
      name: category.name,
      code: category.code.isEmpty
          ? _codeFromName(category.name)
          : category.code,
      subcategories: [
        ItemSubcategoryDefinition(
          name: 'General',
          code: 'GEN',
          attributeTemplateKey: _fallbackTemplateForNature(category.nature),
          measurementProfileKey: _fallbackProfileForNature(category.nature),
        ),
      ],
      isActive: category.isActive,
    );
  }

  static String _categoryKey(String nature, String name) {
    return '${nature.trim().toLowerCase()}|${name.trim().toLowerCase()}';
  }

  static String _codeFromName(String value) {
    final parts = value
        .toUpperCase()
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'GEN';
    if (parts.length == 1) {
      return parts.first.substring(0, math.min(3, parts.first.length));
    }
    return parts
        .take(3)
        .map((part) => part.substring(0, 1))
        .join();
  }

  static String _fallbackTemplateForNature(String nature) {
    switch (nature) {
      case 'Service':
        return 'service';
      case 'Finished Good':
        return 'assembly';
      case 'Semi-Finished Good':
        return 'fabricatedMember';
      default:
        return 'generic';
    }
  }

  static String _fallbackProfileForNature(String nature) {
    switch (nature) {
      case 'Raw Material':
      case 'Scrap':
        return 'WEIGHT';
      case 'Semi-Finished Good':
        return 'COUNT_WEIGHT';
      case 'Finished Good':
        return 'ASSEMBLY';
      case 'Service':
        return 'SERVICE';
      default:
        return 'COUNT';
    }
  }

  static ItemMasterConfiguration defaults() {
    ItemSubcategoryDefinition sub(
        String name,
        String code,
        String template,
        String profile,
        ) => ItemSubcategoryDefinition(
      name: name,
      code: code,
      attributeTemplateKey: template,
      measurementProfileKey: profile,
    );

    ItemCategoryDefinition cat(
        String nature,
        String name,
        String code,
        List<ItemSubcategoryDefinition> subcategories,
        ) => ItemCategoryDefinition(
      nature: nature,
      name: name,
      code: code,
      subcategories: subcategories,
    );

    return ItemMasterConfiguration(
      categories: [
        cat('Raw Material', 'Structural Steel', 'STL', [
          sub('Equal Angle', 'ANG', 'angle', 'WEIGHT_LENGTH'),
          sub('Unequal Angle', 'UAN', 'angle', 'WEIGHT_LENGTH'),
          sub('Channel', 'CHN', 'section', 'WEIGHT_LENGTH'),
          sub('Beam', 'BEM', 'section', 'WEIGHT_LENGTH'),
          sub('Flat', 'FLT', 'flat', 'WEIGHT_LENGTH'),
          sub('Plate', 'PLT', 'plate', 'WEIGHT_AREA'),
          sub('Sheet', 'SHT', 'plate', 'WEIGHT_AREA'),
          sub('Chequered Plate', 'CHQ', 'plate', 'WEIGHT_AREA'),
          sub('Round Bar / Rod', 'RBR', 'roundBar', 'WEIGHT_LENGTH'),
          sub('Pipe / Tube', 'PIP', 'pipe', 'WEIGHT_LENGTH'),
          sub('Square Hollow Section', 'SHS', 'hollowSection', 'WEIGHT_LENGTH'),
          sub('Rectangular Hollow Section', 'RHS', 'hollowSection', 'WEIGHT_LENGTH'),
          sub('C Section', 'CSE', 'coldFormedSection', 'WEIGHT_LENGTH'),
          sub('Z Section', 'ZSE', 'coldFormedSection', 'WEIGHT_LENGTH'),
          sub('Purlin', 'PUR', 'coldFormedSection', 'WEIGHT_LENGTH'),
          sub('Special / Custom Section', 'SPL', 'section', 'WEIGHT_LENGTH'),
        ]),
        cat('Raw Material', 'Galvanizing Chemical', 'GAL', [
          sub('Zinc Ingot', 'ZIN', 'chemical', 'WEIGHT'),
          sub('Hydrochloric Acid', 'HCL', 'chemical', 'VOLUME'),
          sub('Flux Chemical', 'FLX', 'chemical', 'WEIGHT'),
          sub('Passivation Chemical', 'PAS', 'chemical', 'VOLUME'),
          sub('Degreasing Chemical', 'DEG', 'chemical', 'VOLUME'),
          sub('Ammonium Chloride', 'AMC', 'chemical', 'WEIGHT'),
        ]),
        cat('Raw Material', 'Paint & Coating', 'PNT', [
          sub('Primer', 'PRI', 'chemical', 'VOLUME'),
          sub('Paint', 'PNT', 'chemical', 'VOLUME'),
          sub('Thinner', 'THN', 'chemical', 'VOLUME'),
          sub('Zinc-Rich Touch-Up Paint', 'ZTP', 'chemical', 'VOLUME'),
        ]),
        cat('Raw Material', 'Civil Material', 'CIV', [
          sub('Cement', 'CEM', 'packaged', 'PACK_WEIGHT'),
          sub('Sand', 'SND', 'generic', 'WEIGHT'),
          sub('Aggregate', 'AGR', 'generic', 'WEIGHT'),
          sub('Grout', 'GRT', 'packaged', 'PACK_WEIGHT'),
          sub('Admixture', 'ADM', 'chemical', 'VOLUME'),
        ]),
        cat('Raw Material', 'Electrical Material', 'ELM', [
          sub('Cable', 'CBL', 'generic', 'WEIGHT_LENGTH'),
          sub('Earthing Strip', 'ERS', 'flat', 'WEIGHT_LENGTH'),
          sub('Conductor', 'CND', 'generic', 'WEIGHT_LENGTH'),
          sub('Electrical General', 'ELG', 'generic', 'COUNT'),
        ]),
        cat('Raw Material', 'Fuel & Lubricant', 'FUL', [
          sub('Diesel', 'DSL', 'chemical', 'VOLUME'),
          sub('Hydraulic Oil', 'HYO', 'chemical', 'VOLUME'),
          sub('Gear Oil', 'GRO', 'chemical', 'VOLUME'),
          sub('Grease', 'GRS', 'packaged', 'PACK_WEIGHT'),
        ]),
        cat('Raw Material', 'Timber', 'TMB', [
          sub('Timber Section', 'TMS', 'generic', 'COUNT'),
          sub('Wooden Plank', 'WPL', 'generic', 'COUNT'),
        ]),
        cat('Raw Material', 'General Raw Material', 'GRM', [
          sub('General', 'GEN', 'generic', 'WEIGHT'),
        ]),

        cat('Bought-Out Component', 'Structural Fastener', 'FST', [
          sub('Structural Bolt', 'BLT', 'fastener', 'COUNT_WEIGHT'),
          sub('Nut', 'NUT', 'fastener', 'COUNT_WEIGHT'),
          sub('Plain Washer', 'PWS', 'fastener', 'COUNT_WEIGHT'),
          sub('Spring Washer', 'SWS', 'fastener', 'COUNT_WEIGHT'),
          sub('Step Bolt', 'STB', 'fastener', 'COUNT_WEIGHT'),
          sub('Anchor Bolt', 'ANB', 'fastener', 'COUNT_WEIGHT'),
          sub('U-Bolt', 'UBT', 'fastener', 'COUNT_WEIGHT'),
          sub('Threaded Rod', 'TRD', 'fastener', 'COUNT_WEIGHT'),
        ]),
        cat('Bought-Out Component', 'Solar Hardware', 'SOL', [
          sub('Mid Clamp', 'MCL', 'fastener', 'COUNT_WEIGHT'),
          sub('End Clamp', 'ECL', 'fastener', 'COUNT_WEIGHT'),
          sub('Module Fastener Kit', 'MFK', 'packaged', 'COUNT'),
          sub('Cable Support', 'CBS', 'generic', 'COUNT'),
          sub('Foundation Hardware', 'FDH', 'fastener', 'COUNT_WEIGHT'),
        ]),
        cat('Bought-Out Component', 'Telecom Accessory', 'TEL', [
          sub('Antenna Mount', 'AMT', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Cable Tray', 'CTR', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Ladder', 'LDR', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Safety Rail', 'SFR', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Platform Accessory', 'PFA', 'fabricatedMember', 'COUNT_WEIGHT'),
        ]),
        cat('Bought-Out Component', 'Electrical Component', 'ELC', [
          sub('Switchgear', 'SWG', 'generic', 'COUNT'),
          sub('Electrical Panel', 'EPN', 'generic', 'COUNT'),
          sub('Motor', 'MTR', 'generic', 'COUNT'),
          sub('Sensor', 'SNS', 'generic', 'COUNT'),
          sub('Electrical General', 'ELG', 'generic', 'COUNT'),
        ]),
        cat('Bought-Out Component', 'Mechanical Component', 'MEC', [
          sub('Bearing', 'BRG', 'generic', 'COUNT'),
          sub('Gearbox', 'GBX', 'generic', 'COUNT'),
          sub('Coupling', 'CPL', 'generic', 'COUNT'),
          sub('Valve', 'VLV', 'generic', 'COUNT'),
          sub('Mechanical General', 'MEG', 'generic', 'COUNT'),
        ]),

        cat('Consumable', 'Welding Consumable', 'WEL', [
          sub('Welding Electrode', 'ELD', 'packaged', 'PACK_WEIGHT'),
          sub('Welding Wire', 'WWR', 'packaged', 'PACK_WEIGHT'),
          sub('Welding Flux', 'WFX', 'packaged', 'PACK_WEIGHT'),
          sub('Shielding Gas', 'GAS', 'gas', 'VOLUME'),
        ]),
        cat('Consumable', 'Fabrication Consumable', 'FAB', [
          sub('Cutting Disc', 'CUT', 'packaged', 'COUNT'),
          sub('Grinding Disc', 'GRD', 'packaged', 'COUNT'),
          sub('Drill Bit', 'DRL', 'packaged', 'COUNT'),
          sub('Cutting Nozzle', 'NOZ', 'packaged', 'COUNT'),
          sub('Anti-Spatter Chemical', 'ASP', 'chemical', 'VOLUME'),
          sub('Marking Consumable', 'MRK', 'packaged', 'COUNT'),
        ]),
        cat('Consumable', 'Galvanizing Consumable', 'GVC', [
          sub('Binding Wire', 'BDW', 'packaged', 'PACK_WEIGHT'),
          sub('Skimming Tool Consumable', 'SKM', 'packaged', 'COUNT'),
          sub('Galvanizing General', 'GVG', 'generic', 'COUNT'),
        ]),
        cat('Consumable', 'Maintenance Consumable', 'MNC', [
          sub('Cleaning Chemical', 'CLN', 'chemical', 'VOLUME'),
          sub('Cotton Waste', 'CTW', 'packaged', 'PACK_WEIGHT'),
          sub('Maintenance General', 'MNG', 'generic', 'COUNT'),
        ]),
        cat('Consumable', 'Office Consumable', 'OFC', [
          sub('Stationery', 'STN', 'packaged', 'COUNT'),
          sub('Printing Consumable', 'PRC', 'packaged', 'COUNT'),
          sub('Office General', 'OFG', 'generic', 'COUNT'),
        ]),

        cat('Spare Part', 'Mechanical Spare', 'MSP', [
          sub('Bearing', 'BRG', 'generic', 'COUNT'),
          sub('Gear / Sprocket', 'GER', 'generic', 'COUNT'),
          sub('Coupling', 'CPL', 'generic', 'COUNT'),
          sub('Mechanical General', 'MEG', 'generic', 'COUNT'),
        ]),
        cat('Spare Part', 'Electrical Spare', 'ESP', [
          sub('Contactor / Relay', 'CTR', 'generic', 'COUNT'),
          sub('Motor Spare', 'MTS', 'generic', 'COUNT'),
          sub('Cable / Connector', 'CBC', 'generic', 'COUNT'),
          sub('Electrical General', 'ELG', 'generic', 'COUNT'),
        ]),
        cat('Spare Part', 'Hydraulic & Pneumatic Spare', 'HPS', [
          sub('Hydraulic Seal', 'HSL', 'generic', 'COUNT'),
          sub('Hose', 'HSE', 'generic', 'COUNT'),
          sub('Valve', 'VLV', 'generic', 'COUNT'),
          sub('Cylinder Spare', 'CYS', 'generic', 'COUNT'),
        ]),
        cat('Spare Part', 'Machine Spare', 'MCH', [
          sub('Drill Machine Spare', 'DMS', 'generic', 'COUNT'),
          sub('CNC Spare', 'CNS', 'generic', 'COUNT'),
          sub('Galvanizing Plant Spare', 'GPS', 'generic', 'COUNT'),
          sub('Machine General', 'MCG', 'generic', 'COUNT'),
        ]),
        cat('Spare Part', 'Vehicle Spare', 'VSP', [
          sub('Tyre', 'TYR', 'generic', 'COUNT'),
          sub('Battery', 'BAT', 'generic', 'COUNT'),
          sub('Filter', 'FIL', 'generic', 'COUNT'),
          sub('Vehicle General', 'VEG', 'generic', 'COUNT'),
        ]),

        cat('Tool & Equipment', 'Hand Tool', 'HDT', [
          sub('Spanner / Wrench', 'SPN', 'generic', 'COUNT'),
          sub('Hammer', 'HMR', 'generic', 'COUNT'),
          sub('Pliers / Cutter', 'PLC', 'generic', 'COUNT'),
          sub('Hand Tool General', 'HTG', 'generic', 'COUNT'),
        ]),
        cat('Tool & Equipment', 'Power Tool', 'PWT', [
          sub('Grinding Machine', 'GRM', 'generic', 'COUNT'),
          sub('Drilling Machine', 'DRM', 'generic', 'COUNT'),
          sub('Cutting Machine', 'CTM', 'generic', 'COUNT'),
          sub('Power Tool General', 'PTG', 'generic', 'COUNT'),
        ]),
        cat('Tool & Equipment', 'Measuring Instrument', 'MSI', [
          sub('Vernier / Micrometer', 'VRN', 'generic', 'COUNT'),
          sub('Measuring Tape', 'MTP', 'generic', 'COUNT'),
          sub('Coating Thickness Gauge', 'CTG', 'generic', 'COUNT'),
          sub('Instrument General', 'ING', 'generic', 'COUNT'),
        ]),
        cat('Tool & Equipment', 'Lifting Equipment', 'LFT', [
          sub('Chain Pulley Block', 'CPB', 'generic', 'COUNT'),
          sub('Sling', 'SLG', 'generic', 'COUNT'),
          sub('Shackle', 'SHK', 'generic', 'COUNT'),
          sub('Lifting General', 'LFG', 'generic', 'COUNT'),
        ]),
        cat('Tool & Equipment', 'Welding Equipment', 'WDE', [
          sub('Welding Machine', 'WDM', 'generic', 'COUNT'),
          sub('Welding Holder', 'WDH', 'generic', 'COUNT'),
          sub('Welding Equipment General', 'WEG', 'generic', 'COUNT'),
        ]),

        cat('Safety Item', 'Personal Protective Equipment', 'PPE', [
          sub('Safety Helmet', 'HLM', 'generic', 'COUNT'),
          sub('Safety Shoes', 'SHO', 'generic', 'COUNT'),
          sub('Safety Gloves', 'GLV', 'generic', 'COUNT'),
          sub('Safety Goggles', 'GGL', 'generic', 'COUNT'),
          sub('Safety Jacket', 'JKT', 'generic', 'COUNT'),
        ]),
        cat('Safety Item', 'Fall Protection', 'FAL', [
          sub('Safety Harness', 'HNS', 'generic', 'COUNT'),
          sub('Lifeline', 'LFL', 'generic', 'COUNT'),
          sub('Fall Arrester', 'FAR', 'generic', 'COUNT'),
        ]),
        cat('Safety Item', 'Fire Safety', 'FSF', [
          sub('Fire Extinguisher', 'FEX', 'generic', 'COUNT'),
          sub('Fire Blanket', 'FBL', 'generic', 'COUNT'),
          sub('Fire Safety General', 'FSG', 'generic', 'COUNT'),
        ]),
        cat('Safety Item', 'Barricading & Signage', 'BRS', [
          sub('Barricading Tape', 'BRT', 'packaged', 'COUNT'),
          sub('Safety Sign', 'SGN', 'generic', 'COUNT'),
          sub('Safety Cone', 'CON', 'generic', 'COUNT'),
        ]),

        cat('Packaging Material', 'Timber Packaging', 'TPK', [
          sub('Wooden Pallet', 'WPL', 'generic', 'COUNT'),
          sub('Wooden Crate', 'WCR', 'generic', 'COUNT'),
          sub('Wooden Spacer', 'WSP', 'generic', 'COUNT'),
        ]),
        cat('Packaging Material', 'Metal Packaging', 'MPK', [
          sub('Steel Strap', 'STS', 'packaged', 'COUNT'),
          sub('Binding Wire', 'BDW', 'packaged', 'PACK_WEIGHT'),
          sub('Metal Packing General', 'MPG', 'generic', 'COUNT'),
        ]),
        cat('Packaging Material', 'General Packaging', 'GPK', [
          sub('Plastic Sheet', 'PLS', 'packaged', 'COUNT'),
          sub('Carton', 'CTN', 'generic', 'COUNT'),
          sub('Label / Tag', 'TAG', 'packaged', 'COUNT'),
        ]),

        cat('Semi-Finished Good', 'Tower Component', 'TWR', [
          sub('Tower Member', 'TLM', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Gusset Plate', 'GSP', 'plate', 'COUNT_WEIGHT'),
          sub('Cleat', 'CLT', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Bracing Member', 'BRC', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Cross Arm Component', 'CAR', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Stub Angle', 'STU', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Base Plate', 'BPL', 'plate', 'COUNT_WEIGHT'),
        ]),
        cat('Semi-Finished Good', 'Telecom Component', 'TCM', [
          sub('Lattice Member', 'LAT', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Tubular Member', 'TUB', 'pipe', 'COUNT_WEIGHT'),
          sub('Antenna Mount', 'AMT', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Cable Tray', 'CTR', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Ladder', 'LDR', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Working Platform', 'WPF', 'fabricatedMember', 'COUNT_WEIGHT'),
        ]),
        cat('Semi-Finished Good', 'Solar Structure Component', 'SMS', [
          sub('Module Rail', 'MRL', 'coldFormedSection', 'COUNT_WEIGHT'),
          sub('Rafter', 'RAF', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Purlin Member', 'PUM', 'coldFormedSection', 'COUNT_WEIGHT'),
          sub('Column / Post', 'PST', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Torque Tube', 'TTB', 'pipe', 'COUNT_WEIGHT'),
          sub('Solar Bracing Member', 'SBR', 'fabricatedMember', 'COUNT_WEIGHT'),
        ]),
        cat('Semi-Finished Good', 'Galvanized Component', 'GVC', [
          sub('Galvanized Tower Member', 'GTM', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Galvanized Plate', 'GPL', 'plate', 'COUNT_WEIGHT'),
          sub('Galvanized Assembly', 'GAS', 'fabricatedMember', 'COUNT_WEIGHT'),
        ]),
        cat('Semi-Finished Good', 'General Fabricated Component', 'GFC', [
          sub('Cut Component', 'CUT', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Welded Assembly', 'WAS', 'fabricatedMember', 'COUNT_WEIGHT'),
          sub('Machined Component', 'MAC', 'fabricatedMember', 'COUNT_WEIGHT'),
        ]),

        cat('Finished Good', 'Transmission Line Tower', 'TLT', [
          sub('Tower Assembly', 'TAS', 'assembly', 'ASSEMBLY'),
          sub('Tower Extension', 'TEX', 'assembly', 'ASSEMBLY'),
          sub('Tower Pack', 'TPK', 'assembly', 'ASSEMBLY'),
        ]),
        cat('Finished Good', 'Telecom Tower', 'TCT', [
          sub('Ground Based Tower', 'GBT', 'assembly', 'ASSEMBLY'),
          sub('Roof Top Tower', 'RTT', 'assembly', 'ASSEMBLY'),
          sub('Monopole', 'MNP', 'assembly', 'ASSEMBLY'),
        ]),
        cat('Finished Good', 'Solar Mounting Structure', 'SST', [
          sub('Fixed Tilt MMS', 'FTM', 'assembly', 'ASSEMBLY'),
          sub('Tracker Structure', 'TRK', 'assembly', 'ASSEMBLY'),
          sub('Solar Structure Pack', 'SSP', 'assembly', 'ASSEMBLY'),
        ]),
        cat('Finished Good', 'General Fabricated Structure', 'GFS', [
          sub('Fabricated Assembly', 'FAS', 'assembly', 'ASSEMBLY'),
          sub('Galvanized Assembly', 'GVA', 'assembly', 'ASSEMBLY'),
          sub('Structure Pack', 'SPK', 'assembly', 'ASSEMBLY'),
        ]),

        cat('Service', 'Manufacturing Service', 'MFS', [
          sub('Galvanizing Service', 'GAL', 'service', 'SERVICE'),
          sub('Fabrication Service', 'FAB', 'service', 'SERVICE'),
          sub('Machining Service', 'MAC', 'service', 'SERVICE'),
          sub('Painting Service', 'PNT', 'service', 'SERVICE'),
        ]),
        cat('Service', 'Logistics Service', 'LGS', [
          sub('Transport Service', 'TRN', 'service', 'SERVICE'),
          sub('Loading / Unloading Service', 'LDU', 'service', 'SERVICE'),
          sub('Freight Service', 'FRT', 'service', 'SERVICE'),
        ]),
        cat('Service', 'Testing & Inspection Service', 'TIS', [
          sub('Material Testing Service', 'MTS', 'service', 'SERVICE'),
          sub('Galvanizing Test Service', 'GTS', 'service', 'SERVICE'),
          sub('Third-Party Inspection', 'TPI', 'service', 'SERVICE'),
        ]),
        cat('Service', 'Maintenance Service', 'MNS', [
          sub('Machine Maintenance', 'MCM', 'service', 'SERVICE'),
          sub('Electrical Maintenance', 'ELM', 'service', 'SERVICE'),
          sub('Civil Maintenance', 'CVM', 'service', 'SERVICE'),
        ]),

        cat('Asset', 'Plant & Machinery', 'PAM', [
          sub('Fabrication Machine', 'FBM', 'generic', 'COUNT'),
          sub('Galvanizing Plant Equipment', 'GPE', 'generic', 'COUNT'),
          sub('Material Handling Equipment', 'MHE', 'generic', 'COUNT'),
          sub('Plant General', 'PAG', 'generic', 'COUNT'),
        ]),
        cat('Asset', 'Vehicle', 'VEH', [
          sub('Commercial Vehicle', 'CMV', 'generic', 'COUNT'),
          sub('Forklift', 'FKL', 'generic', 'COUNT'),
          sub('Crane', 'CRN', 'generic', 'COUNT'),
          sub('Vehicle General', 'VEG', 'generic', 'COUNT'),
        ]),
        cat('Asset', 'IT & Office Equipment', 'ITO', [
          sub('Computer / Laptop', 'CMP', 'generic', 'COUNT'),
          sub('Printer', 'PRN', 'generic', 'COUNT'),
          sub('Furniture', 'FUR', 'generic', 'COUNT'),
          sub('Office Equipment General', 'OEG', 'generic', 'COUNT'),
        ]),

        cat('Scrap', 'Production Scrap', 'SCP', [
          sub('Steel Scrap', 'STL', 'generic', 'WEIGHT'),
          sub('Zinc Ash', 'ZAS', 'generic', 'WEIGHT'),
          sub('Zinc Dross', 'ZDR', 'generic', 'WEIGHT'),
          sub('Packaging Scrap', 'PKG', 'generic', 'WEIGHT'),
          sub('Other Scrap', 'OTH', 'generic', 'WEIGHT'),
        ]),

        cat('Other', 'General', 'GEN', [
          sub('General', 'GEN', 'generic', 'COUNT'),
        ]),
      ],
      uoms: const [
        UomDefinition(code: 'KG', name: 'Kilogram', dimension: 'Weight'),
        UomDefinition(code: 'MT', name: 'Metric Tonne', dimension: 'Weight'),
        UomDefinition(code: 'GM', name: 'Gram', dimension: 'Weight'),
        UomDefinition(code: 'NOS', name: 'Numbers', dimension: 'Count', decimalPlaces: 0),
        UomDefinition(code: 'PCS', name: 'Pieces', dimension: 'Count', decimalPlaces: 0),
        UomDefinition(code: 'SET', name: 'Set', dimension: 'Count', decimalPlaces: 0),
        UomDefinition(code: 'BOX', name: 'Box', dimension: 'Pack', decimalPlaces: 0),
        UomDefinition(code: 'BAG', name: 'Bag', dimension: 'Pack', decimalPlaces: 0),
        UomDefinition(code: 'DRUM', name: 'Drum', dimension: 'Pack', decimalPlaces: 0),
        UomDefinition(code: 'BUNDLE', name: 'Bundle', dimension: 'Pack', decimalPlaces: 0),
        UomDefinition(code: 'MTR', name: 'Metre', dimension: 'Length'),
        UomDefinition(code: 'MM', name: 'Millimetre', dimension: 'Length'),
        UomDefinition(code: 'SQM', name: 'Square Metre', dimension: 'Area'),
        UomDefinition(code: 'CUM', name: 'Cubic Metre', dimension: 'Volume'),
        UomDefinition(code: 'LTR', name: 'Litre', dimension: 'Volume'),
        UomDefinition(code: 'KL', name: 'Kilolitre', dimension: 'Volume'),
        UomDefinition(code: 'SHEET', name: 'Sheet', dimension: 'Count', decimalPlaces: 0),
        UomDefinition(code: 'ROLL', name: 'Roll', dimension: 'Count', decimalPlaces: 0),
        UomDefinition(code: 'JOB', name: 'Job', dimension: 'Service', decimalPlaces: 0),
        UomDefinition(code: 'TRIP', name: 'Trip', dimension: 'Service', decimalPlaces: 0),
        UomDefinition(code: 'DAY', name: 'Day', dimension: 'Time'),
      ],
      measurementProfiles: const [
        MeasurementProfileDefinition(
          key: 'WEIGHT_LENGTH',
          name: 'Weight with Length',
          baseUom: 'KG',
          purchaseUom: 'MT',
          issueUom: 'KG',
          secondaryUom: 'MTR',
          conversionMethod: 'Formula',
        ),
        MeasurementProfileDefinition(
          key: 'WEIGHT_AREA',
          name: 'Weight with Area / Sheet',
          baseUom: 'KG',
          purchaseUom: 'MT',
          issueUom: 'KG',
          secondaryUom: 'SQM',
          conversionMethod: 'Formula',
        ),
        MeasurementProfileDefinition(
          key: 'WEIGHT',
          name: 'Weight Only',
          baseUom: 'KG',
          purchaseUom: 'MT',
          issueUom: 'KG',
          secondaryUom: '',
          conversionMethod: 'Fixed',
          defaultFactor: 1000,
        ),
        MeasurementProfileDefinition(
          key: 'COUNT',
          name: 'Count Only',
          baseUom: 'NOS',
          purchaseUom: 'NOS',
          issueUom: 'NOS',
          secondaryUom: '',
          conversionMethod: 'Fixed',
        ),
        MeasurementProfileDefinition(
          key: 'COUNT_WEIGHT',
          name: 'Count with Weight',
          baseUom: 'NOS',
          purchaseUom: 'NOS',
          issueUom: 'NOS',
          secondaryUom: 'KG',
          conversionMethod: 'Formula',
        ),
        MeasurementProfileDefinition(
          key: 'PACK_WEIGHT',
          name: 'Pack with Weight',
          baseUom: 'KG',
          purchaseUom: 'BOX',
          issueUom: 'KG',
          secondaryUom: 'NOS',
          conversionMethod: 'Fixed',
        ),
        MeasurementProfileDefinition(
          key: 'VOLUME',
          name: 'Volume',
          baseUom: 'LTR',
          purchaseUom: 'LTR',
          issueUom: 'LTR',
          secondaryUom: 'KG',
          conversionMethod: 'Transaction Entered',
        ),
        MeasurementProfileDefinition(
          key: 'ASSEMBLY',
          name: 'Assembly with Weight',
          baseUom: 'SET',
          purchaseUom: 'SET',
          issueUom: 'SET',
          secondaryUom: 'KG',
          conversionMethod: 'BOM Calculated',
        ),
        MeasurementProfileDefinition(
          key: 'SERVICE',
          name: 'Service',
          baseUom: 'JOB',
          purchaseUom: 'JOB',
          issueUom: 'JOB',
          secondaryUom: '',
          conversionMethod: 'Not Applicable',
        ),
      ],
    );
  }
}


class ItemMasterConfigurationRepository {
  ItemMasterConfigurationRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String companyId;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _document => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('settings')
      .doc('item_master_configuration');

  Stream<ItemMasterConfiguration> watchConfiguration() {
    return _document.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return ItemMasterConfiguration.defaults();
      }
      return ItemMasterConfiguration.fromMap(snapshot.data()!);
    });
  }

  Future<void> saveConfiguration(ItemMasterConfiguration configuration) {
    return _document.set(
      configuration.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> seedRecommendedDefaults() async {
    final snapshot = await _document.get();
    final configuration = snapshot.exists && snapshot.data() != null
        ? ItemMasterConfiguration.fromMap(snapshot.data()!)
        : ItemMasterConfiguration.defaults();
    await _document.set(
      configuration.toMap(),
      SetOptions(merge: false),
    );
  }
}

class ItemMasterModel {
  const ItemMasterModel({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.itemNature,
    required this.itemType,
    required this.itemShape,
    required this.itemGrade,
    required this.density,
    required this.formulaType,
    required this.standardWeightPerMeter,
    required this.unit,
    this.description = '',
    this.category = '',
    this.subCategory = '',
    this.categoryCode = '',
    this.subCategoryCode = '',
    this.measurementProfileKey = '',
    this.attributeTemplateKey = '',
    this.secondaryUnit = '',
    this.conversionMethod = 'Fixed',
    this.secondaryConversionFactor = 1,
    this.attributes = const <String, dynamic>{},
    this.purchaseUnit = '',
    this.issueUnit = '',
    this.conversionFactor = 1,
    this.hsnCode = '',
    this.taxRate = 0,
    this.valuationMethod = 'Weighted Average',
    this.yieldStrength = '',
    this.coating = '',
    this.coatingType = '',
    this.coatingSpec = '',
    this.baseWeightPerMeter = 0,
    this.coatingFormula = '',
    this.weightFormula = '',
    this.inventoryTracked = true,
    this.batchTracked = false,
    this.serialTracked = false,
    this.expiryTracked = false,
    this.qualityInspectionRequired = false,
    this.allowNegativeStock = false,
    this.technicalSpecificationEnabled = false,
    this.reorderLevel = 0,
    this.minimumStockLevel = 0,
    this.maximumStockLevel = 0,
    this.purchaseTolerancePercent = 0,
    this.appliesToAllVerticals = true,
    this.verticalIds = const [],
    this.verticalNames = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String itemCode;
  final String itemName;
  final String itemNature;
  final String itemType;
  final String itemShape;
  final String itemGrade;
  final String description;
  final String category;
  final String subCategory;
  final String categoryCode;
  final String subCategoryCode;
  final String measurementProfileKey;
  final String attributeTemplateKey;
  final String secondaryUnit;
  final String conversionMethod;
  final double secondaryConversionFactor;
  final Map<String, dynamic> attributes;
  final String purchaseUnit;
  final String issueUnit;
  final String hsnCode;
  final String valuationMethod;
  final String yieldStrength;
  final String coating;
  final String coatingType;
  final String coatingSpec;
  final String formulaType;
  final String weightFormula;
  final String coatingFormula;
  final String unit;
  final double conversionFactor;
  final double taxRate;
  final double density;
  final double standardWeightPerMeter;
  final double baseWeightPerMeter;
  final double reorderLevel;
  final double minimumStockLevel;
  final double maximumStockLevel;
  final double purchaseTolerancePercent;
  final bool inventoryTracked;
  final bool batchTracked;
  final bool serialTracked;
  final bool expiryTracked;
  final bool qualityInspectionRequired;
  final bool allowNegativeStock;
  final bool technicalSpecificationEnabled;
  final bool appliesToAllVerticals;
  final List<String> verticalIds;
  final List<String> verticalNames;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const List<String> itemNatures = [
    'Raw Material',
    'Bought-Out Component',
    'Consumable',
    'Spare Part',
    'Tool & Equipment',
    'Safety Item',
    'Packaging Material',
    'Semi-Finished Good',
    'Finished Good',
    'Service',
    'Asset',
    'Scrap',
    'Other',
  ];

  static const Map<String, List<String>> categoryOptionsByNature = {
    'Raw Material': [
      'Structural Steel',
      'Cement',
      'Aggregate',
      'Sand',
      'Pipe & Fitting',
      'Electrical Material',
      'Paint & Chemical',
      'Fuel & Lubricant',
      'Timber',
      'Fastener',
      'General Raw Material',
    ],
    'Bought-Out Component': [
      'Structural Fastener',
      'Solar Hardware',
      'Telecom Accessory',
      'Electrical Component',
      'General Bought-Out Component',
    ],
    'Consumable': [
      'Welding Consumable',
      'Cutting Consumable',
      'Abrasive',
      'Cleaning Consumable',
      'Office Consumable',
      'PPE Consumable',
      'General Consumable',
    ],
    'Spare Part': [
      'Mechanical Spare',
      'Electrical Spare',
      'Hydraulic Spare',
      'Pneumatic Spare',
      'Vehicle Spare',
      'Machine Spare',
      'General Spare',
    ],
    'Tool & Equipment': [
      'Hand Tool',
      'Power Tool',
      'Measuring Tool',
      'Lifting Equipment',
      'Construction Equipment',
      'General Tool',
    ],
    'Safety Item': [
      'Head Protection',
      'Eye Protection',
      'Hand Protection',
      'Foot Protection',
      'Fall Protection',
      'Fire Safety',
      'General Safety',
    ],
    'Packaging Material': [
      'Pallet',
      'Crate',
      'Carton',
      'Strapping',
      'Protective Packaging',
      'General Packaging',
    ],
    'Semi-Finished Good': [
      'Cut Component',
      'Welded Assembly',
      'Machined Component',
      'Coated Component',
      'General Semi-Finished Good',
    ],
    'Finished Good': [
      'Fabricated Structure',
      'Galvanized Product',
      'Roofing Product',
      'Assembly',
      'General Finished Good',
    ],
    'Service': [
      'Transport Service',
      'Fabrication Service',
      'Galvanizing Service',
      'Testing Service',
      'Maintenance Service',
      'Consultancy Service',
      'Labour Service',
    ],
    'Asset': [
      'Plant & Machinery',
      'Vehicle',
      'IT Equipment',
      'Furniture',
      'Office Equipment',
      'General Asset',
    ],
    'Scrap': [
      'Production Scrap',
      'Steel Scrap',
      'Zinc Scrap',
      'Packaging Scrap',
    ],
    'Other': ['General'],
  };

  static List<String> categoriesForNature(String nature) {
    return categoryOptionsByNature[nature] ?? const ['General'];
  }

  static const List<String> engineeringTypes = [
    'Plate',
    'Pipe',
    'Round Bar',
    'Flange',
    'Flat',
    'Angle',
    'Channel',
    'C Section',
    'Roofing Sheet',
    'Hollow Section',
    'Beam',
    'Custom',
  ];

  // Legacy compatibility for BOM and fabrication modules.
  static const List<String> materialTypes = engineeringTypes;

  static const List<String> commonUnits = [
    'KG',
    'MT',
    'GM',
    'NOS',
    'PCS',
    'MTR',
    'SQM',
    'CUM',
    'LTR',
    'ML',
    'BAG',
    'BOX',
    'SET',
    'ROLL',
    'SHEET',
    'PAIR',
    'DAY',
    'JOB',
  ];

  static const List<String> valuationMethods = [
    'Weighted Average',
    'FIFO',
    'Standard Cost',
  ];

  static const Map<String, double> densities = {
    'MS': 7850.0,
    'SS304': 8000.0,
    'Aluminium': 2700.0,
  };

  static String normalizeItemCode(String code) {
    return code.toUpperCase().replaceAll(RegExp(r'[\s-]+'), '').trim();
  }

  static String normalizeMaterialCode(String code) => normalizeItemCode(code);

  String get normalizedItemCode => normalizeItemCode(itemCode);
  String get normalizedMaterialCode => normalizedItemCode;

  String get displayName {
    final code = itemCode.trim();
    final name = itemName.trim();
    if (code.isEmpty) return name;
    if (name.isEmpty) return code;
    return '$code - $name';
  }

  String get scopeLabel {
    if (appliesToAllVerticals || verticalIds.isEmpty) return 'All Verticals';
    if (verticalNames.isNotEmpty) return verticalNames.join(', ');
    return '${verticalIds.length} selected verticals';
  }

  bool isAvailableInVertical(String? verticalId) {
    final id = (verticalId ?? '').trim();
    if (id.isEmpty || appliesToAllVerticals || verticalIds.isEmpty) return true;
    return verticalIds.contains(id);
  }

  bool get hasTrackingControl {
    return batchTracked || serialTracked || expiryTracked;
  }

  // Compatibility getters for existing BOM, production and fabrication code.
  String get materialCode => itemCode;
  String get materialName => itemName;
  String get materialType => itemType;
  String get materialShape => itemShape;
  String get materialGrade => itemGrade;

  ItemMasterModel copyWith({
    String? id,
    String? itemCode,
    String? itemName,
    String? itemNature,
    String? itemType,
    String? itemShape,
    String? itemGrade,
    String? description,
    String? category,
    String? subCategory,
    String? categoryCode,
    String? subCategoryCode,
    String? measurementProfileKey,
    String? attributeTemplateKey,
    String? secondaryUnit,
    String? conversionMethod,
    double? secondaryConversionFactor,
    Map<String, dynamic>? attributes,
    String? purchaseUnit,
    String? issueUnit,
    String? hsnCode,
    String? valuationMethod,
    String? yieldStrength,
    String? coating,
    String? coatingType,
    String? coatingSpec,
    String? formulaType,
    String? weightFormula,
    String? coatingFormula,
    String? unit,
    double? conversionFactor,
    double? taxRate,
    double? density,
    double? standardWeightPerMeter,
    double? baseWeightPerMeter,
    double? reorderLevel,
    double? minimumStockLevel,
    double? maximumStockLevel,
    double? purchaseTolerancePercent,
    bool? inventoryTracked,
    bool? batchTracked,
    bool? serialTracked,
    bool? expiryTracked,
    bool? qualityInspectionRequired,
    bool? allowNegativeStock,
    bool? technicalSpecificationEnabled,
    bool? appliesToAllVerticals,
    List<String>? verticalIds,
    List<String>? verticalNames,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemMasterModel(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      itemNature: itemNature ?? this.itemNature,
      itemType: itemType ?? this.itemType,
      itemShape: itemShape ?? this.itemShape,
      itemGrade: itemGrade ?? this.itemGrade,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      categoryCode: categoryCode ?? this.categoryCode,
      subCategoryCode: subCategoryCode ?? this.subCategoryCode,
      measurementProfileKey:
      measurementProfileKey ?? this.measurementProfileKey,
      attributeTemplateKey:
      attributeTemplateKey ?? this.attributeTemplateKey,
      secondaryUnit: secondaryUnit ?? this.secondaryUnit,
      conversionMethod: conversionMethod ?? this.conversionMethod,
      secondaryConversionFactor:
      secondaryConversionFactor ?? this.secondaryConversionFactor,
      attributes: attributes ?? this.attributes,
      purchaseUnit: purchaseUnit ?? this.purchaseUnit,
      issueUnit: issueUnit ?? this.issueUnit,
      hsnCode: hsnCode ?? this.hsnCode,
      valuationMethod: valuationMethod ?? this.valuationMethod,
      yieldStrength: yieldStrength ?? this.yieldStrength,
      coating: coating ?? this.coating,
      coatingType: coatingType ?? this.coatingType,
      coatingSpec: coatingSpec ?? this.coatingSpec,
      formulaType: formulaType ?? this.formulaType,
      weightFormula: weightFormula ?? this.weightFormula,
      coatingFormula: coatingFormula ?? this.coatingFormula,
      unit: unit ?? this.unit,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      taxRate: taxRate ?? this.taxRate,
      density: density ?? this.density,
      standardWeightPerMeter:
      standardWeightPerMeter ?? this.standardWeightPerMeter,
      baseWeightPerMeter: baseWeightPerMeter ?? this.baseWeightPerMeter,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      minimumStockLevel: minimumStockLevel ?? this.minimumStockLevel,
      maximumStockLevel: maximumStockLevel ?? this.maximumStockLevel,
      purchaseTolerancePercent:
      purchaseTolerancePercent ?? this.purchaseTolerancePercent,
      inventoryTracked: inventoryTracked ?? this.inventoryTracked,
      batchTracked: batchTracked ?? this.batchTracked,
      serialTracked: serialTracked ?? this.serialTracked,
      expiryTracked: expiryTracked ?? this.expiryTracked,
      qualityInspectionRequired:
      qualityInspectionRequired ?? this.qualityInspectionRequired,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
      technicalSpecificationEnabled:
      technicalSpecificationEnabled ?? this.technicalSpecificationEnabled,
      appliesToAllVerticals:
      appliesToAllVerticals ?? this.appliesToAllVerticals,
      verticalIds: verticalIds ?? this.verticalIds,
      verticalNames: verticalNames ?? this.verticalNames,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final effectiveCategory = category.trim().isEmpty ? itemNature : category;
    final effectivePurchaseUnit = purchaseUnit.trim().isEmpty
        ? unit
        : purchaseUnit;
    final effectiveIssueUnit = issueUnit.trim().isEmpty ? unit : issueUnit;
    final effectiveWeightFormula = weightFormula.trim().isEmpty
        ? formulaType
        : weightFormula;
    final keywords = <String>{
      itemCode.trim().toLowerCase(),
      itemName.trim().toLowerCase(),
      itemNature.trim().toLowerCase(),
      effectiveCategory.trim().toLowerCase(),
      subCategory.trim().toLowerCase(),
      itemGrade.trim().toLowerCase(),
    }.where((value) => value.isNotEmpty).toList(growable: false);

    return {
      'itemCode': itemCode,
      'normalizedItemCode': normalizedItemCode,
      'itemName': itemName,
      'itemNature': itemNature,
      'itemType': itemType,
      'itemShape': itemShape,
      'itemGrade': itemGrade,
      'description': description,
      'category': effectiveCategory,
      'subCategory': subCategory,
      'categoryCode': categoryCode,
      'subCategoryCode': subCategoryCode,
      'measurementProfileKey': measurementProfileKey,
      'attributeTemplateKey': attributeTemplateKey,
      'secondaryUnit': secondaryUnit,
      'conversionMethod': conversionMethod,
      'secondaryConversionFactor': secondaryConversionFactor,
      'attributes': attributes,
      'baseUnit': unit,
      'purchaseUnit': effectivePurchaseUnit,
      'issueUnit': effectiveIssueUnit,
      'conversionFactor': conversionFactor,
      'hsnCode': hsnCode,
      'taxRate': taxRate,
      'valuationMethod': valuationMethod,
      'inventoryTracked': inventoryTracked,
      'batchTracked': batchTracked,
      'serialTracked': serialTracked,
      'expiryTracked': expiryTracked,
      'qualityInspectionRequired': qualityInspectionRequired,
      'allowNegativeStock': allowNegativeStock,
      'technicalSpecificationEnabled': technicalSpecificationEnabled,
      'reorderLevel': reorderLevel,
      'minimumStockLevel': minimumStockLevel,
      'maximumStockLevel': maximumStockLevel,
      'purchaseTolerancePercent': purchaseTolerancePercent,
      'appliesToAllVerticals': appliesToAllVerticals,
      'verticalIds': appliesToAllVerticals ? <String>[] : verticalIds,
      'verticalNames': appliesToAllVerticals ? <String>[] : verticalNames,
      'verticalScopeKeys': appliesToAllVerticals
          ? const <String>['ALL']
          : verticalIds,
      'searchKeywords': keywords,
      'yieldStrength': yieldStrength,
      'coating': coating,
      'coatingType': coatingType,
      'coatingSpec': coatingSpec,
      'density': density,
      'formulaType': formulaType,
      'weightFormula': effectiveWeightFormula,
      'standardWeightPerMeter': standardWeightPerMeter,
      'baseWeightPerMeter': baseWeightPerMeter,
      'coatingFormula': coatingFormula,
      'unit': unit,
      'isActive': isActive,
      // Legacy aliases retained to avoid breaking existing modules.
      'materialCode': itemCode,
      'normalizedMaterialCode': normalizedItemCode,
      'materialName': itemName,
      'materialType': itemType,
      'materialShape': itemShape,
      'shape': itemShape,
      'materialGrade': itemGrade,
      'grade': itemGrade,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ItemMasterModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
    return ItemMasterModel.fromMap({
      ...?snapshot.data(),
      'id': snapshot.id,
    });
  }

  factory ItemMasterModel.fromMap(Map<String, dynamic> map) {
    final itemType = (
        map['itemType'] ??
            map['materialType'] ??
            map['category'] ??
            ''
    ).toString();
    final itemNature = (map['itemNature'] ?? '').toString().trim().isNotEmpty
        ? map['itemNature'].toString()
        : _inferLegacyNature(itemType);
    final unit = (map['baseUnit'] ?? map['unit'] ?? 'KG').toString();
    final verticalIds = _stringList(map['verticalIds']);
    final verticalNames = _stringList(map['verticalNames']);
    final legacyHasTechnicalData = itemType.trim().isNotEmpty ||
        (map['materialGrade'] ?? map['grade'] ?? '').toString().isNotEmpty ||
        doubleFromValue(map['standardWeightPerMeter']) > 0;

    return ItemMasterModel(
      id: (map['id'] ?? '').toString(),
      itemCode: (map['itemCode'] ?? map['materialCode'] ?? '').toString(),
      itemName: (map['itemName'] ?? map['materialName'] ?? '').toString(),
      itemNature: itemNature,
      itemType: itemType,
      itemShape: (
          map['itemShape'] ??
              map['materialShape'] ??
              map['shape'] ??
              ''
      ).toString(),
      itemGrade: (
          map['itemGrade'] ??
              map['materialGrade'] ??
              map['grade'] ??
              ''
      ).toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? itemType).toString(),
      subCategory: (map['subCategory'] ?? '').toString(),
      categoryCode: (map['categoryCode'] ?? '').toString(),
      subCategoryCode: (map['subCategoryCode'] ?? '').toString(),
      measurementProfileKey:
      (map['measurementProfileKey'] ?? '').toString(),
      attributeTemplateKey:
      (map['attributeTemplateKey'] ?? '').toString(),
      secondaryUnit: (map['secondaryUnit'] ?? '').toString(),
      conversionMethod: (map['conversionMethod'] ?? 'Fixed').toString(),
      secondaryConversionFactor: _positiveOrDefault(
        doubleFromValue(map['secondaryConversionFactor']),
        1,
      ),
      attributes: map['attributes'] is Map
          ? Map<String, dynamic>.from(map['attributes'] as Map)
          : const <String, dynamic>{},
      purchaseUnit: (map['purchaseUnit'] ?? unit).toString(),
      issueUnit: (map['issueUnit'] ?? unit).toString(),
      conversionFactor: _positiveOrDefault(
        doubleFromValue(map['conversionFactor']),
        1,
      ),
      hsnCode: (map['hsnCode'] ?? '').toString(),
      taxRate: doubleFromValue(map['taxRate'] ?? map['gstRate']),
      valuationMethod: (map['valuationMethod'] ?? 'Weighted Average').toString(),
      yieldStrength: (map['yieldStrength'] ?? map['grade'] ?? '').toString(),
      coating: (map['coating'] ?? map['coatingType'] ?? '').toString(),
      coatingType: (map['coatingType'] ?? map['coating'] ?? '').toString(),
      coatingSpec: (map['coatingSpec'] ?? '').toString(),
      density: doubleFromValue(map['density']),
      formulaType: (
          map['formulaType'] ??
              map['weightFormula'] ??
              ''
      ).toString(),
      weightFormula: (
          map['weightFormula'] ??
              map['formulaType'] ??
              ''
      ).toString(),
      standardWeightPerMeter: doubleFromValue(
        map['standardWeightPerMeter'] ?? map['unitWeightKgPerM'],
      ),
      baseWeightPerMeter: doubleFromValue(
        map['baseWeightPerMeter'] ??
            map['standardWeightPerMeter'] ??
            0,
      ),
      coatingFormula: (map['coatingFormula'] ?? '').toString(),
      unit: unit,
      inventoryTracked: map['inventoryTracked'] == null
          ? itemNature != 'Service'
          : map['inventoryTracked'] == true,
      batchTracked: map['batchTracked'] == true,
      serialTracked: map['serialTracked'] == true,
      expiryTracked: map['expiryTracked'] == true,
      qualityInspectionRequired:
      map['qualityInspectionRequired'] == true,
      allowNegativeStock: map['allowNegativeStock'] == true,
      technicalSpecificationEnabled:
      map['technicalSpecificationEnabled'] == null
          ? legacyHasTechnicalData
          : map['technicalSpecificationEnabled'] == true,
      reorderLevel: doubleFromValue(map['reorderLevel']),
      minimumStockLevel: doubleFromValue(map['minimumStockLevel']),
      maximumStockLevel: doubleFromValue(map['maximumStockLevel']),
      purchaseTolerancePercent: doubleFromValue(
        map['purchaseTolerancePercent'],
      ),
      appliesToAllVerticals: map['appliesToAllVerticals'] == null
          ? verticalIds.isEmpty
          : map['appliesToAllVerticals'] == true,
      verticalIds: verticalIds,
      verticalNames: verticalNames,
      isActive: map['isActive'] == null ? true : map['isActive'] == true,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  static String _inferLegacyNature(String itemType) {
    final normalized = itemType.trim().toLowerCase();
    if (engineeringTypes.any(
          (value) => value.toLowerCase() == normalized,
    )) {
      return 'Raw Material';
    }
    if (normalized.contains('consumable')) return 'Consumable';
    if (normalized.contains('spare')) return 'Spare Part';
    if (normalized.contains('tool')) return 'Tool & Equipment';
    return 'Raw Material';
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static double _positiveOrDefault(double value, double fallback) {
    return value > 0 ? value : fallback;
  }
}

typedef MaterialMasterModel = ItemMasterModel;

class ItemMasterDuplicateException implements Exception {
  const ItemMasterDuplicateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ItemMasterRepository {
  ItemMasterRepository({
    required this.tenantId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String tenantId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref {
    return TenantFirestore(
      tenantId: tenantId,
      firestore: _firestore,
    ).collection('material_master');
  }

  String get collectionPath => 'companies/${tenantId.trim()}/material_master';

  String newItemId() => _ref.doc().id;
  String newMaterialId() => newItemId();

  Stream<List<ItemMasterModel>> watchItems() {
    return _ref.orderBy('materialName').snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(ItemMasterModel.fromFirestore)
          .toList(growable: false);
      items.sort(
            (a, b) => a.itemName.toLowerCase().compareTo(
          b.itemName.toLowerCase(),
        ),
      );
      return items;
    });
  }

  Stream<List<MaterialMasterModel>> watchMaterials() => watchItems();

  Future<List<ItemMasterModel>> fetchAllItems({int limit = 1000}) async {
    final snapshot = await _ref.limit(limit).get();
    return snapshot.docs
        .map(ItemMasterModel.fromFirestore)
        .toList(growable: false);
  }

  Future<List<MaterialMasterModel>> fetchAllMaterials({int limit = 1000}) {
    return fetchAllItems(limit: limit);
  }

  Future<List<ItemMasterModel>> searchItems(
      String query, {
        int limit = 300,
        bool includeInactive = false,
      }) async {
    final normalized = query.trim().toLowerCase();
    final snapshot = await _ref.limit(limit).get();
    final items = snapshot.docs
        .map(ItemMasterModel.fromFirestore)
        .where((item) {
      if (!includeInactive && !item.isActive) return false;
      if (normalized.isEmpty) return true;
      final haystack = [
        item.itemCode,
        item.itemName,
        item.itemNature,
        item.itemType,
        item.category,
        item.subCategory,
        item.itemGrade,
        item.scopeLabel,
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    })
        .toList(growable: false);
    items.sort(
          (a, b) => a.itemName.toLowerCase().compareTo(
        b.itemName.toLowerCase(),
      ),
    );
    return items;
  }

  Future<List<MaterialMasterModel>> searchMaterials(String query) {
    return searchItems(query);
  }

  Future<ItemMasterModel?> findByItemCode(String itemCode) async {
    final normalized = ItemMasterModel.normalizeItemCode(itemCode);
    if (normalized.isEmpty) return null;
    return _findDuplicateByNormalizedCode(normalized, excludeId: '');
  }

  Future<MaterialMasterModel?> findByMaterialCode(String materialCode) {
    return findByItemCode(materialCode);
  }

  Future<MaterialMasterModel?> findByNormalizedMaterialCode(String code) {
    return findByItemCode(code);
  }

  Future<void> saveItem(ItemMasterModel item) async {
    final normalized = item.normalizedItemCode;
    if (normalized.isEmpty) {
      throw const FormatException('Item code is required.');
    }
    if (item.itemName.trim().isEmpty) {
      throw const FormatException('Item name is required.');
    }

    final duplicate = await _findDuplicateByNormalizedCode(
      normalized,
      excludeId: item.id,
    );
    if (duplicate != null) {
      throw ItemMasterDuplicateException(
        'Item code "${item.itemCode}" already exists as '
            '"${duplicate.displayName}".',
      );
    }

    final docId = item.id.trim().isEmpty ? newItemId() : item.id.trim();
    final document = _ref.doc(docId);
    final current = await document.get();

    await document.set({
      ...item.copyWith(id: docId).toFirestore(),
      'tenantId': tenantId,
      'companyId': tenantId,
      if (!current.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveMaterial(MaterialMasterModel material) {
    return saveItem(material);
  }

  Future<void> deleteItemPermanently(String itemId) async {
    final id = itemId.trim();
    if (id.isEmpty) {
      throw const FormatException('A valid item ID is required for deletion.');
    }
    await _ref.doc(id).delete();
  }

  Future<void> deleteMaterialPermanently(String materialId) {
    return deleteItemPermanently(materialId);
  }

  Future<void> setItemActive(String itemId, bool isActive) async {
    final id = itemId.trim();
    if (id.isEmpty) return;
    await _ref.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setMaterialActive(String materialId, bool isActive) {
    return setItemActive(materialId, isActive);
  }

  Future<ItemMasterModel?> _findDuplicateByNormalizedCode(
      String normalized, {
        required String excludeId,
      }) async {
    if (normalized.isEmpty) return null;

    final newFieldSnapshot = await _ref
        .where('normalizedItemCode', isEqualTo: normalized)
        .limit(2)
        .get();
    for (final doc in newFieldSnapshot.docs) {
      if (doc.id != excludeId) return ItemMasterModel.fromFirestore(doc);
    }

    final legacyFieldSnapshot = await _ref
        .where('normalizedMaterialCode', isEqualTo: normalized)
        .limit(2)
        .get();
    for (final doc in legacyFieldSnapshot.docs) {
      if (doc.id != excludeId) return ItemMasterModel.fromFirestore(doc);
    }

    final fallbackSnapshot = await _ref.limit(500).get();
    for (final doc in fallbackSnapshot.docs) {
      if (doc.id == excludeId) continue;
      final item = ItemMasterModel.fromFirestore(doc);
      if (item.normalizedItemCode == normalized) return item;
    }
    return null;
  }
}

typedef MaterialMasterRepository = ItemMasterRepository;

class WeightFormulaInput {
  const WeightFormulaInput({
    required this.formulaType,
    required this.materialGrade,
    required this.qty,
    required this.lengthMm,
    this.widthMm = 0,
    this.thicknessMm = 0,
    this.odMm = 0,
    this.idMm = 0,
    this.radiusMm = 0,
    this.density = 0,
    this.standardWeightPerMeter = 0,
  });

  final String formulaType;
  final String materialGrade;
  final double qty;
  final double lengthMm;
  final double widthMm;
  final double thicknessMm;
  final double odMm;
  final double idMm;
  final double radiusMm;
  final double density;
  final double standardWeightPerMeter;
}

class WeightFormulaService {
  const WeightFormulaService._();

  static double densityForGrade(String grade) {
    final normalized = grade.trim().toLowerCase();
    for (final entry in ItemMasterModel.densities.entries) {
      if (entry.key.toLowerCase() == normalized) return entry.value;
    }
    return ItemMasterModel.densities['MS']!;
  }

  static String formulaTypeForMaterial(String materialType) {
    switch (materialType.trim().toLowerCase()) {
      case 'plate':
      case 'flat':
      case 'flange':
        return 'plate';
      case 'pipe':
        return 'pipe';
      case 'round bar':
      case 'roundbar':
        return 'roundBar';
      default:
        return 'sectionWeightPerMeter';
    }
  }

  static double calculateWeight(WeightFormulaInput input) {
    final qty = input.qty <= 0 ? 1.0 : input.qty;
    final density = input.density > 0
        ? input.density
        : densityForGrade(input.materialGrade);

    switch (input.formulaType.trim()) {
      case 'plate':
        return qty *
            _mm3ToM3(
              input.lengthMm * input.widthMm * input.thicknessMm,
            ) *
            density;
      case 'pipe':
        return qty *
            (math.pow(input.odMm, 2) - math.pow(input.idMm, 2)) *
            0.02466 *
            _mmToM(input.lengthMm);
      case 'roundBar':
        final radiusM = _mmToM(
          input.radiusMm > 0 ? input.radiusMm : input.odMm / 2,
        );
        return qty *
            math.pi *
            math.pow(radiusM, 2) *
            _mmToM(input.lengthMm) *
            density;
      default:
        return BomWeightEngine.roundWeight(
          qty * _mmToM(input.lengthMm) * input.standardWeightPerMeter,
        );
    }
  }

  static double _mmToM(double value) => value / 1000;
  static double _mm3ToM3(double value) => value / 1000000000;
}

class ScreenAddItemMaster extends StatefulWidget {
  const ScreenAddItemMaster({
    super.key,
    required this.tenantId,
    this.item,
    this.activeVerticalId,
    this.activeVerticalName,
  });

  final String tenantId;
  final ItemMasterModel? item;
  final String? activeVerticalId;
  final String? activeVerticalName;

  bool get isEditing => item != null;

  @override
  State<ScreenAddItemMaster> createState() => _ScreenAddItemMasterState();
}

class _ScreenAddItemMasterState extends State<ScreenAddItemMaster> {
  final _formKey = GlobalKey<FormState>();
  late final ItemMasterRepository _repository = ItemMasterRepository(
    tenantId: widget.tenantId,
  );
  late final ItemMasterConfigurationRepository _configurationRepository =
  ItemMasterConfigurationRepository(companyId: widget.tenantId);
  late final Stream<ItemMasterConfiguration> _configurationStream =
  _configurationRepository.watchConfiguration();
  late final Stream<List<VerticalModel>> _verticalsStream = VerticalRepository(
    companyId: widget.tenantId,
  ).watchVerticals();
  ItemMasterConfiguration _configuration = ItemMasterConfiguration.defaults();
  String _configurationSignature = '';
  late final String _draftItemId;

  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _subCategory;
  late final TextEditingController _hsnCode;
  late final TextEditingController _taxRate;
  late final TextEditingController _shape;
  late final TextEditingController _grade;
  late final TextEditingController _yieldStrength;
  late final TextEditingController _coating;
  late final TextEditingController _coatingSpec;
  late final TextEditingController _density;
  late final TextEditingController _standardWeight;
  late final TextEditingController _baseWeight;
  late final TextEditingController _coatingFormula;
  late final TextEditingController _unit;
  late final TextEditingController _purchaseUnit;
  late final TextEditingController _issueUnit;
  late final TextEditingController _conversionFactor;
  late final TextEditingController _reorderLevel;
  late final TextEditingController _minimumStock;
  late final TextEditingController _maximumStock;
  late final TextEditingController _purchaseTolerance;
  late final TextEditingController _secondaryUnit;
  late final TextEditingController _secondaryConversionFactor;
  late final Map<String, TextEditingController> _attributeControllers;

  late String _itemNature;
  late String _itemType;
  late String _formulaType;
  late String _valuationMethod;
  late String _measurementProfileKey;
  late String _attributeTemplateKey;
  late String _conversionMethod;
  late bool _inventoryTracked;
  late bool _batchTracked;
  late bool _serialTracked;
  late bool _expiryTracked;
  late bool _qualityInspectionRequired;
  late bool _allowNegativeStock;
  late bool _technicalSpecificationEnabled;
  late bool _appliesToAllVerticals;
  late bool _isActive;
  late Set<String> _selectedVerticalIds;

  int _stepIndex = 0;
  bool _saving = false;
  bool _dirty = false;

  ItemMasterModel? get _existing => widget.item;

  static const _steps = [
    _StepDefinition(
      title: 'Identity',
      subtitle: 'Code, name and classification',
      icon: Icons.badge_outlined,
    ),
    _StepDefinition(
      title: 'Business Scope',
      subtitle: 'Vertical availability and status',
      icon: Icons.account_tree_outlined,
    ),
    _StepDefinition(
      title: 'Units & Stock',
      subtitle: 'UOM, valuation and levels',
      icon: Icons.inventory_2_outlined,
    ),
    _StepDefinition(
      title: 'Controls',
      subtitle: 'Tracking, quality and tolerance',
      icon: Icons.tune_outlined,
    ),
    _StepDefinition(
      title: 'Technical',
      subtitle: 'Engineering specification',
      icon: Icons.engineering_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final item = _existing;
    _draftItemId = item?.id ?? _repository.newItemId();
    _code = TextEditingController(text: item?.itemCode ?? '');
    _name = TextEditingController(text: item?.itemName ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _category = TextEditingController(text: item?.category ?? '');
    _subCategory = TextEditingController(text: item?.subCategory ?? '');
    _hsnCode = TextEditingController(text: item?.hsnCode ?? '');
    _taxRate = TextEditingController(text: _formatNumber(item?.taxRate ?? 0));
    _shape = TextEditingController(text: item?.itemShape ?? '');
    _grade = TextEditingController(text: item?.itemGrade ?? 'MS');
    _yieldStrength = TextEditingController(text: item?.yieldStrength ?? '');
    _coating = TextEditingController(
      text: item?.coatingType.trim().isNotEmpty == true
          ? item!.coatingType
          : item?.coating ?? '',
    );
    _coatingSpec = TextEditingController(text: item?.coatingSpec ?? '');
    _density = TextEditingController(
      text: _formatNumber(
        item?.density ?? ItemMasterModel.densities['MS']!,
      ),
    );
    _standardWeight = TextEditingController(
      text: _formatNumber(item?.standardWeightPerMeter ?? 0),
    );
    _baseWeight = TextEditingController(
      text: _formatNumber(item?.baseWeightPerMeter ?? 0),
    );
    _coatingFormula = TextEditingController(
      text: item?.coatingFormula ?? '',
    );
    _unit = TextEditingController(text: item?.unit ?? 'KG');
    _purchaseUnit = TextEditingController(
      text: item?.purchaseUnit ?? item?.unit ?? 'KG',
    );
    _issueUnit = TextEditingController(
      text: item?.issueUnit ?? item?.unit ?? 'KG',
    );
    _conversionFactor = TextEditingController(
      text: _formatNumber(item?.conversionFactor ?? 1),
    );
    _reorderLevel = TextEditingController(
      text: _formatNumber(item?.reorderLevel ?? 0),
    );
    _minimumStock = TextEditingController(
      text: _formatNumber(item?.minimumStockLevel ?? 0),
    );
    _maximumStock = TextEditingController(
      text: _formatNumber(item?.maximumStockLevel ?? 0),
    );
    _purchaseTolerance = TextEditingController(
      text: _formatNumber(item?.purchaseTolerancePercent ?? 0),
    );
    _secondaryUnit = TextEditingController(text: item?.secondaryUnit ?? 'MTR');
    _secondaryConversionFactor = TextEditingController(
      text: _formatNumber(item?.secondaryConversionFactor ?? 1),
    );
    final savedAttributes = item?.attributes ?? const <String, dynamic>{};
    _attributeControllers = {
      for (final key in const [
        'lengthMm',
        'widthMm',
        'heightMm',
        'thicknessMm',
        'leg1Mm',
        'leg2Mm',
        'outerDiameterMm',
        'innerDiameterMm',
        'diameterMm',
        'wallThicknessMm',
        'standardLengthMm',
        'threadPitchMm',
        'packSize',
        'piecesPerPack',
        'weightPerPieceKg',
        'weightPer1000PiecesKg',
        'shelfLifeDays',
      ])
        key: TextEditingController(
          text: _formatNumber(doubleFromValue(savedAttributes[key])),
        ),
    };

    _itemNature = item?.itemNature ?? 'Raw Material';
    _itemType = item?.itemType.trim().isNotEmpty == true
        ? item!.itemType
        : 'Custom';
    _formulaType = item?.formulaType.trim().isNotEmpty == true
        ? item!.formulaType
        : WeightFormulaService.formulaTypeForMaterial(_itemType);
    _valuationMethod = item?.valuationMethod ?? 'Weighted Average';
    _measurementProfileKey = item?.measurementProfileKey.trim().isNotEmpty == true
        ? item!.measurementProfileKey
        : 'WEIGHT_LENGTH';
    _attributeTemplateKey = item?.attributeTemplateKey.trim().isNotEmpty == true
        ? item!.attributeTemplateKey
        : 'generic';
    _conversionMethod = item?.conversionMethod ?? 'Fixed';
    _inventoryTracked = item?.inventoryTracked ?? true;
    _batchTracked = item?.batchTracked ?? false;
    _serialTracked = item?.serialTracked ?? false;
    _expiryTracked = item?.expiryTracked ?? false;
    _qualityInspectionRequired =
        item?.qualityInspectionRequired ?? (_itemNature == 'Raw Material');
    _allowNegativeStock = item?.allowNegativeStock ?? false;
    _technicalSpecificationEnabled =
        item?.technicalSpecificationEnabled ?? (_itemNature == 'Raw Material');
    _isActive = item?.isActive ?? true;

    final activeVerticalId = (widget.activeVerticalId ?? '').trim();
    _appliesToAllVerticals = item?.appliesToAllVerticals ??
        activeVerticalId.isEmpty;
    _selectedVerticalIds = item == null
        ? {
      if (activeVerticalId.isNotEmpty) activeVerticalId,
    }
        : item.verticalIds.toSet();

    _syncClassificationWithConfiguration(
      markDirty: false,
      preserveLegacy: item != null,
      notify: false,
    );

    if (item == null) {
      _refreshGeneratedCode(markDirty: false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _code,
      _name,
      _description,
      _category,
      _subCategory,
      _hsnCode,
      _taxRate,
      _shape,
      _grade,
      _yieldStrength,
      _coating,
      _coatingSpec,
      _density,
      _standardWeight,
      _baseWeight,
      _coatingFormula,
      _unit,
      _purchaseUnit,
      _issueUnit,
      _conversionFactor,
      _reorderLevel,
      _minimumStock,
      _maximumStock,
      _purchaseTolerance,
      _secondaryUnit,
      _secondaryConversionFactor,
      ..._attributeControllers.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscardChanges();
        if (discard == true && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: zCanvasBg,
        body: SafeArea(
          child: StreamBuilder<List<VerticalModel>>(
            stream: _verticalsStream,
            builder: (context, verticalSnapshot) {
              final verticals = (verticalSnapshot.data ?? const <VerticalModel>[])
                  .where((vertical) => vertical.isActive && !vertical.isDeleted)
                  .toList(growable: false);
              return StreamBuilder<ItemMasterConfiguration>(
                stream: _configurationStream,
                builder: (context, configurationSnapshot) {
                  final nextConfiguration = configurationSnapshot.data ??
                      ItemMasterConfiguration.defaults();
                  final signature = _configurationFingerprint(nextConfiguration);
                  if (signature != _configurationSignature) {
                    _configuration = nextConfiguration;
                    _configurationSignature = signature;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _syncClassificationWithConfiguration(
                        markDirty: false,
                        preserveLegacy: widget.isEditing,
                      );
                    });
                  }
                  return Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final desktop = constraints.maxWidth >= 1050;
                            if (!desktop) {
                              return _buildCompactBody(verticals);
                            }
                            return _buildDesktopBody(verticals);
                          },
                        ),
                      ),
                      _buildBottomBar(verticals),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: zBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: _saving ? null : _requestClose,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Edit Item Master' : 'Create Item Master',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: zText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isEditing ? _existing!.displayName : 'New item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(isActive: _isActive),
        ],
      ),
    );
  }

  Widget _buildDesktopBody(List<VerticalModel> verticals) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 245, child: _buildStepRail()),
        const VerticalDivider(width: 1, color: zBorder),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: KeyedSubtree(
                      key: ValueKey(_stepIndex),
                      child: _buildStepContent(verticals),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: zBorder),
        SizedBox(width: 300, child: _buildLiveSummary(verticals)),
      ],
    );
  }

  Widget _buildCompactBody(List<VerticalModel> verticals) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(
            height: 66,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _steps.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final step = _steps[index];
                return ChoiceChip(
                  selected: index == _stepIndex,
                  avatar: Icon(step.icon, size: 17),
                  label: Text(step.title),
                  onSelected: (_) => setState(() => _stepIndex = index),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(
                  key: ValueKey(_stepIndex),
                  child: _buildStepContent(verticals),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRail() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'SETUP',
                style: TextStyle(
                  color: zMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(_steps.length, (index) {
              final step = _steps[index];
              final selected = index == _stepIndex;
              final completed = index < _stepIndex;
              final color = Theme.of(context).colorScheme.primary;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: selected ? color.withValues(alpha: 0.09) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _stepIndex = index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: selected || completed
                                  ? color.withValues(alpha: 0.12)
                                  : zSurfaceSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              completed ? Icons.check : step.icon,
                              size: 17,
                              color: selected || completed ? color : zMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step.title,
                              style: TextStyle(
                                color: selected ? zText : zMuted,
                                fontSize: 12.5,
                                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSummary(List<VerticalModel> verticals) {
    final color = Theme.of(context).colorScheme.primary;
    final selectedNames = verticals
        .where((vertical) => _selectedVerticalIds.contains(vertical.id))
        .map((vertical) => vertical.name)
        .toList(growable: false);
    final scope = _appliesToAllVerticals
        ? 'All Verticals'
        : selectedNames.isEmpty
        ? 'No vertical selected'
        : selectedNames.join(', ');

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIVE ITEM',
              style: TextStyle(
                color: zMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: zSurfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: zBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_natureIcon(_itemNature), color: color, size: 21),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name.text.trim().isEmpty ? 'Unnamed Item' : _name.text.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: zText,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _code.text.trim().isEmpty ? 'ITEM CODE' : _code.text.trim().toUpperCase(),
                    style: const TextStyle(
                      color: zMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SummaryLine(label: 'Nature', value: _itemNature),
            _SummaryLine(
              label: 'Category',
              value: _category.text.trim().isEmpty ? 'Not set' : _category.text.trim(),
            ),
            _SummaryLine(label: 'Scope', value: scope),
            _SummaryLine(
              label: 'Base UOM',
              value: _unit.text.trim().isEmpty ? 'Not set' : _unit.text.trim().toUpperCase(),
            ),
            _SummaryLine(label: 'Valuation', value: _valuationMethod),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ControlBadge(label: 'Inventory', enabled: _inventoryTracked),
                _ControlBadge(label: 'Batch', enabled: _batchTracked),
                _ControlBadge(label: 'Serial', enabled: _serialTracked),
                _ControlBadge(label: 'Expiry', enabled: _expiryTracked),
                _ControlBadge(label: 'QC', enabled: _qualityInspectionRequired),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(List<VerticalModel> verticals) {
    switch (_stepIndex) {
      case 0:
        return _buildIdentityStep();
      case 1:
        return _buildScopeStep(verticals);
      case 2:
        return _buildUnitsStep();
      case 3:
        return _buildControlsStep();
      case 4:
        return _buildTechnicalStep();
      default:
        return _buildIdentityStep();
    }
  }

  Widget _buildIdentityStep() {
    return _StepCard(
      title: 'Identity & classification',
      subtitle: 'Core details used across purchase, stock, BOM and reporting.',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final singleColumn = constraints.maxWidth < 680;
            final fieldWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - 14) / 2;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(width: fieldWidth, child: _autoCodeField()),
                SizedBox(
                  width: fieldWidth,
                  child: _textField(
                    controller: _name,
                    label: 'Item Name',
                    hint: 'Clear operational name',
                    requiredField: true,
                  ),
                ),
                SizedBox(width: fieldWidth, child: _itemNatureField()),
                SizedBox(width: fieldWidth, child: _categoryField()),
                SizedBox(
                  width: fieldWidth,
                  child: _subcategoryField(),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _textField(
                    controller: _hsnCode,
                    label: 'HSN / SAC Code',
                    hint: 'Tax classification',
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _numberField(
                    controller: _taxRate,
                    label: 'Tax Rate %',
                    maximum: 100,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _textField(
                    controller: _description,
                    label: 'Description',
                    hint: 'Specification, buying description or intended use',
                    maxLines: 3,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildScopeStep(List<VerticalModel> verticals) {
    final color = Theme.of(context).colorScheme.primary;
    final selectedFactoryNames = verticals
        .where(
          (vertical) =>
      _appliesToAllVerticals ||
          _selectedVerticalIds.contains(vertical.id),
    )
        .expand((vertical) => vertical.factoryNames)
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return _StepCard(
      title: 'Business scope and availability',
      subtitle: 'Control where this item can be purchased, received, issued and reported.',
      children: [
        Row(
          children: [
            Expanded(
              child: _SelectablePanel(
                selected: _appliesToAllVerticals,
                icon: Icons.language_outlined,
                title: 'Organization-wide',
                subtitle: 'Available to every current and future vertical.',
                onTap: () {
                  setState(() {
                    _appliesToAllVerticals = true;
                    _markDirty();
                  });
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SelectablePanel(
                selected: !_appliesToAllVerticals,
                icon: Icons.account_tree_outlined,
                title: 'Selected verticals',
                subtitle: 'Restrict usage to explicitly selected verticals.',
                onTap: () {
                  setState(() {
                    _appliesToAllVerticals = false;
                    _markDirty();
                  });
                },
              ),
            ),
          ],
        ),
        if (!_appliesToAllVerticals) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: zSurfaceSoft,
              border: Border.all(color: zBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select applicable verticals',
                        style: TextStyle(
                          color: zText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${_selectedVerticalIds.length} selected',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (verticals.isEmpty)
                  const Text(
                    'No active verticals are configured. Add verticals in Settings before restricting this item.',
                    style: TextStyle(color: zMuted, height: 1.45),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: verticals.map((vertical) {
                      final selected = _selectedVerticalIds.contains(vertical.id);
                      return FilterChip(
                        selected: selected,
                        avatar: Icon(
                          selected ? Icons.check_circle : Icons.layers_outlined,
                          size: 17,
                        ),
                        label: Text(vertical.name),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedVerticalIds.add(vertical.id);
                            } else {
                              _selectedVerticalIds.remove(vertical.id);
                            }
                            _markDirty();
                          });
                        },
                      );
                    }).toList(growable: false),
                  ),
              ],
            ),
          ),
        ],
        if (selectedFactoryNames.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: zSurfaceSoft,
              border: Border.all(color: zBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Linked factories',
                  style: TextStyle(
                    color: zText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: selectedFactoryNames
                      .map(
                        (name) => Chip(
                      avatar: const Icon(Icons.factory_outlined, size: 16),
                      label: Text(name),
                    ),
                  )
                      .toList(growable: false),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Factory linkage is inherited from the selected verticals. Physical stock will still be tracked by factory and store in Inventory Status.',
                  style: TextStyle(color: zMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnitsStep() {
    return _StepCard(
      title: 'Units, valuation and stock policy',
      subtitle: 'Define one reliable stock unit and the conversion used during procurement.',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth < 760
                ? constraints.maxWidth
                : (constraints.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(width: fieldWidth, child: _measurementProfileField()),
                SizedBox(width: fieldWidth, child: _valuationField()),
                SizedBox(width: fieldWidth, child: _uomField(_unit, 'Base Stock UOM')),
                SizedBox(width: fieldWidth, child: _uomField(_purchaseUnit, 'Purchase UOM')),
                SizedBox(width: fieldWidth, child: _uomField(_issueUnit, 'Issue UOM')),
                SizedBox(width: fieldWidth, child: _uomField(_secondaryUnit, 'Secondary / Engineering UOM', requiredField: false)),
                SizedBox(width: fieldWidth, child: _conversionMethodField()),
                SizedBox(
                  width: fieldWidth,
                  child: _numberField(
                    controller: _conversionFactor,
                    label: 'Purchase-to-Base Conversion',
                    minimum: 0.000001,
                    helper: 'Example: 1 MT = 1000 KG',
                  ),
                ),
                if (_secondaryUnit.text.trim().isNotEmpty)
                  SizedBox(
                    width: fieldWidth,
                    child: _numberField(
                      controller: _secondaryConversionFactor,
                      label: 'Secondary Conversion Factor',
                      minimum: 0.000001,
                      helper: 'Used only for fixed secondary conversions.',
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const _Subheading(
          title: 'Stock thresholds',
          subtitle: 'Used for low-stock alerts and replenishment planning.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _numberField(
                controller: _minimumStock,
                label: 'Minimum Stock',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _numberField(
                controller: _reorderLevel,
                label: 'Reorder Level',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _numberField(
                controller: _maximumStock,
                label: 'Maximum Stock',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlsStep() {
    return _StepCard(
      title: 'Operational controls',
      subtitle: 'These rules drive inward validation, stock posting and traceability.',
      children: [
        _TogglePanel(
          icon: Icons.inventory_outlined,
          title: 'Track inventory',
          subtitle: 'Maintain stock balances and movement history for this item.',
          value: _inventoryTracked,
          onChanged: (value) {
            setState(() {
              _inventoryTracked = value;
              if (!value) {
                _batchTracked = false;
                _serialTracked = false;
                _expiryTracked = false;
                _allowNegativeStock = false;
              }
              _markDirty();
            });
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TogglePanel(
                compact: true,
                enabled: _inventoryTracked,
                icon: Icons.qr_code_2_outlined,
                title: 'Batch / Lot',
                subtitle: 'Trace inward and issue by batch.',
                value: _batchTracked,
                onChanged: (value) {
                  setState(() {
                    _batchTracked = value;
                    _markDirty();
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TogglePanel(
                compact: true,
                enabled: _inventoryTracked,
                icon: Icons.qr_code_scanner_outlined,
                title: 'Serial Number',
                subtitle: 'Track every unit individually.',
                value: _serialTracked,
                onChanged: (value) {
                  setState(() {
                    _serialTracked = value;
                    _markDirty();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TogglePanel(
                compact: true,
                enabled: _inventoryTracked,
                icon: Icons.event_busy_outlined,
                title: 'Expiry',
                subtitle: 'Capture manufacturing and expiry dates.',
                value: _expiryTracked,
                onChanged: (value) {
                  setState(() {
                    _expiryTracked = value;
                    _markDirty();
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TogglePanel(
                compact: true,
                icon: Icons.fact_check_outlined,
                title: 'Quality Inspection',
                subtitle: 'Hold inward until QC acceptance.',
                value: _qualityInspectionRequired,
                onChanged: (value) {
                  setState(() {
                    _qualityInspectionRequired = value;
                    _markDirty();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _TogglePanel(
          enabled: _inventoryTracked,
          icon: Icons.warning_amber_outlined,
          title: 'Allow negative stock',
          subtitle: 'Not recommended. Enable only for an approved exceptional workflow.',
          value: _allowNegativeStock,
          onChanged: (value) {
            setState(() {
              _allowNegativeStock = value;
              _markDirty();
            });
          },
        ),
        const SizedBox(height: 18),
        _numberField(
          controller: _purchaseTolerance,
          label: 'Purchase Quantity Tolerance %',
          maximum: 100,
          helper: 'Maximum permitted excess over ordered quantity before approval is required.',
        ),
      ],
    );
  }

  Widget _buildTechnicalStep() {
    return _StepCard(
      title: 'Technical and engineering specification',
      subtitle: 'Enable only when BOM, fabrication or weight calculations require these attributes.',
      children: [
        _TogglePanel(
          icon: Icons.engineering_outlined,
          title: 'Enable technical specification',
          subtitle: 'Stores grade, shape, coating, density and weight formula data.',
          value: _technicalSpecificationEnabled,
          onChanged: (value) {
            setState(() {
              _technicalSpecificationEnabled = value;
              _markDirty();
            });
          },
        ),
        if (_technicalSpecificationEnabled) ...[
          const SizedBox(height: 18),
          const _Subheading(
            title: 'Smart dimensional attributes',
            subtitle: 'Fields adapt to the selected subcategory.',
          ),
          const SizedBox(height: 12),
          _smartAttributeFields(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _engineeringTypeField()),
              const SizedBox(width: 14),
              Expanded(
                child: _textField(
                  controller: _shape,
                  label: 'Shape / Section',
                  hint: 'Equal Angle, NB Pipe, SHS...',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _textField(
                  controller: _grade,
                  label: 'Material Grade',
                  hint: 'MS, SS304, YS550...',
                  onChanged: (value) {
                    _density.text = _formatNumber(
                      WeightFormulaService.densityForGrade(value),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: _yieldStrength,
                  label: 'Yield Strength',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _textField(
                  controller: _coating,
                  label: 'Coating Type',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _textField(
                  controller: _coatingSpec,
                  label: 'Coating Specification',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _density,
                  label: 'Density (kg/m³)',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: _formulaTypeField()),
              const SizedBox(width: 14),
              Expanded(
                child: _numberField(
                  controller: _standardWeight,
                  label: 'Standard Weight (kg/m)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _baseWeight,
                  label: 'Base Weight (kg/m)',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _textField(
                  controller: _coatingFormula,
                  label: 'Coating Formula / Note',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(List<VerticalModel> verticals) {
    final lastStep = _stepIndex == _steps.length - 1;
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: zBorder)),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _saving || _stepIndex == 0
                    ? null
                    : () => setState(() => _stepIndex--),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Previous'),
              ),
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : _requestClose,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              if (!lastStep)
                FilledButton.icon(
                  onPressed: _saving ? null : _goNext,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Continue'),
                )
              else
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(verticals),
                  icon: _saving
                      ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_saving ? 'Saving...' : 'Save Item'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemNatureField() {
    final textTheme = Theme.of(context).textTheme;
    return DropdownButtonFormField<String>(
      key: ValueKey('nature-$_itemNature'),
      initialValue: ItemMasterModel.itemNatures.contains(_itemNature)
          ? _itemNature
          : 'Other',
      isExpanded: true,
      style: textTheme.bodyMedium?.copyWith(
        color: zText,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration('Item Nature', requiredField: true),
      selectedItemBuilder: (context) {
        return ItemMasterModel.itemNatures
            .map(
              (nature) => Align(
            alignment: Alignment.centerLeft,
            child: Text(
              nature,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
            .toList(growable: false);
      },
      items: ItemMasterModel.itemNatures
          .map(
            (nature) => DropdownMenuItem<String>(
          value: nature,
          child: Row(
            children: [
              Icon(_natureIcon(nature), size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nature,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      )
          .toList(growable: false),
      onChanged: _saving
          ? null
          : (value) {
        if (value == null || value == _itemNature) return;
        _selectNature(value);
      },
    );
  }

  Widget _categoryField() {
    final definitions = _configuration.categoriesForNature(_itemNature);
    final configuredNames = definitions
        .map((entry) => entry.name)
        .toList(growable: false);
    final current = _category.text.trim();
    final options = <String>[
      ...configuredNames,
      if (current.isNotEmpty && !configuredNames.contains(current)) current,
    ];
    final selectedValue = current.isNotEmpty && options.contains(current)
        ? current
        : options.isNotEmpty
        ? options.first
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('category-$_itemNature-$selectedValue'),
      initialValue: selectedValue,
      isExpanded: true,
      decoration: _inputDecoration(
        'Category',
        requiredField: true,
        hint: options.isEmpty ? 'No category configured' : 'Select category',
      ).copyWith(
        suffixIcon: Tooltip(
          message: 'Manage categories in Settings > Inventory Masters',
          child: const Icon(Icons.lock_outline, size: 17),
        ),
      ),
      items: options
          .map(
            (name) => DropdownMenuItem<String>(
          value: name,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
          .toList(growable: false),
      onChanged: _saving || options.isEmpty
          ? null
          : (value) {
        if (value == null || value == _category.text.trim()) return;
        _selectCategory(value);
      },
      validator: (value) {
        if ((value ?? '').trim().isEmpty) return 'Category is required.';
        return null;
      },
    );
  }

  Widget _subcategoryField() {
    final categoryDefinition = _configuration.categoryByName(
      _itemNature,
      _category.text,
    );
    final definitions = _configuration.subcategoriesFor(categoryDefinition);
    final configuredNames = definitions
        .map((entry) => entry.name)
        .toList(growable: false);
    final current = _subCategory.text.trim();
    final options = <String>[
      ...configuredNames,
      if (current.isNotEmpty && !configuredNames.contains(current)) current,
    ];
    final selectedValue = current.isNotEmpty && options.contains(current)
        ? current
        : options.isNotEmpty
        ? options.first
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(
        'subcategory-$_itemNature-${_category.text}-$selectedValue',
      ),
      initialValue: selectedValue,
      isExpanded: true,
      decoration: _inputDecoration(
        'Subcategory',
        requiredField: true,
        hint: _category.text.trim().isEmpty
            ? 'Select category first'
            : options.isEmpty
            ? 'No subcategory configured'
            : 'Select subcategory',
      ).copyWith(
        suffixIcon: Tooltip(
          message:
          'Subcategory controls UOM, dimensions and technical fields',
          child: const Icon(Icons.schema_outlined, size: 17),
        ),
      ),
      items: options
          .map(
            (name) => DropdownMenuItem<String>(
          value: name,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
          .toList(growable: false),
      onChanged: _saving || options.isEmpty
          ? null
          : (value) {
        if (value == null || value == _subCategory.text.trim()) return;
        final selected = definitions.cast<ItemSubcategoryDefinition?>().firstWhere(
              (entry) => entry?.name == value,
          orElse: () => null,
        );
        setState(() {
          _subCategory.text = value;
          if (selected != null) _applySubcategoryDefaults(selected);
          _refreshGeneratedCode(markDirty: false);
          _dirty = true;
        });
      },
      validator: (value) {
        if ((value ?? '').trim().isEmpty) return 'Subcategory is required.';
        return null;
      },
    );
  }

  void _selectNature(String value) {
    _itemNature = value;
    _applyNatureDefaults(value);
    _category.clear();
    _subCategory.clear();
    _syncClassificationWithConfiguration(
      markDirty: true,
      preserveLegacy: false,
    );
  }

  void _selectCategory(String value) {
    setState(() {
      _category.text = value;
      _subCategory.clear();
      final category = _configuration.categoryByName(_itemNature, value);
      final subcategories = _configuration.subcategoriesFor(category);
      if (subcategories.isNotEmpty) {
        final first = subcategories.first;
        _subCategory.text = first.name;
        _applySubcategoryDefaults(first);
      }
      _refreshGeneratedCode(markDirty: false);
      _dirty = true;
    });
  }

  void _applyNatureDefaults(String value) {
    if (value == 'Service') {
      _inventoryTracked = false;
      _batchTracked = false;
      _serialTracked = false;
      _expiryTracked = false;
      _qualityInspectionRequired = false;
      _technicalSpecificationEnabled = false;
    } else if (value == 'Raw Material') {
      _inventoryTracked = true;
      _qualityInspectionRequired = true;
      _technicalSpecificationEnabled = true;
    } else if (value == 'Tool & Equipment' || value == 'Asset') {
      _inventoryTracked = true;
      _serialTracked = true;
      _technicalSpecificationEnabled = false;
    } else if (value == 'Scrap') {
      _inventoryTracked = true;
      _batchTracked = false;
      _serialTracked = false;
      _expiryTracked = false;
      _technicalSpecificationEnabled = false;
    } else {
      _inventoryTracked = true;
      _technicalSpecificationEnabled = false;
    }
  }

  void _syncClassificationWithConfiguration({
    required bool markDirty,
    required bool preserveLegacy,
    bool notify = true,
  }) {
    final categories = _configuration.categoriesForNature(_itemNature);
    if (categories.isEmpty) return;

    var autoSelected = false;
    var selectedCategory = _configuration.categoryByName(
      _itemNature,
      _category.text,
    );
    if (selectedCategory == null &&
        (!preserveLegacy || _category.text.trim().isEmpty)) {
      selectedCategory = categories.first;
      _category.text = selectedCategory.name;
      autoSelected = true;
    }

    if (selectedCategory != null) {
      final subcategories = _configuration.subcategoriesFor(selectedCategory);
      var selectedSubcategory = _configuration.subcategoryByName(
        selectedCategory,
        _subCategory.text,
      );
      if (selectedSubcategory == null &&
          (!preserveLegacy || _subCategory.text.trim().isEmpty) &&
          subcategories.isNotEmpty) {
        selectedSubcategory = subcategories.first;
        _subCategory.text = selectedSubcategory.name;
        autoSelected = true;
      }
      if (selectedSubcategory != null && (!preserveLegacy || autoSelected)) {
        _applySubcategoryDefaults(selectedSubcategory);
      }
    }

    _refreshGeneratedCode(markDirty: false);
    if (markDirty) _dirty = true;
    if (notify && mounted) setState(() {});
  }

  String _configurationFingerprint(ItemMasterConfiguration configuration) {
    final categoryPart = configuration.categories
        .map(
          (category) =>
      '${category.nature}:${category.name}:${category.isActive}:'
          '${category.subcategories.map((entry) => '${entry.name}:${entry.code}:${entry.attributeTemplateKey}:${entry.measurementProfileKey}').join(',')}',
    )
        .join('|');
    final uomPart = configuration.uoms
        .map((entry) => '${entry.code}:${entry.isActive}')
        .join('|');
    final profilePart = configuration.measurementProfiles
        .map((entry) => '${entry.key}:${entry.isActive}')
        .join('|');
    return '$categoryPart#$uomPart#$profilePart';
  }

  void _applySubcategoryDefaults(ItemSubcategoryDefinition definition) {
    _attributeTemplateKey = definition.attributeTemplateKey;
    _measurementProfileKey = definition.measurementProfileKey;
    final profile = _configuration.profileByKey(_measurementProfileKey);
    if (profile != null) {
      _unit.text = profile.baseUom;
      _purchaseUnit.text = profile.purchaseUom;
      _issueUnit.text = profile.issueUom;
      _secondaryUnit.text = profile.secondaryUom;
      _conversionMethod = profile.conversionMethod;
      _conversionFactor.text = _formatNumber(profile.defaultFactor);
      _secondaryConversionFactor.text = '1';
    }
    _technicalSpecificationEnabled =
        definition.attributeTemplateKey != 'service' &&
            definition.attributeTemplateKey != 'generic';

    switch (definition.attributeTemplateKey) {
      case 'angle':
        _itemType = 'Angle';
        _shape.text = definition.name;
        _formulaType = 'sectionWeightPerMeter';
        break;
      case 'flat':
        _itemType = 'Flat';
        _shape.text = definition.name;
        _formulaType = 'plate';
        break;
      case 'plate':
        _itemType = 'Plate';
        _shape.text = definition.name;
        _formulaType = 'plate';
        break;
      case 'roundBar':
        _itemType = 'Round Bar';
        _shape.text = definition.name;
        _formulaType = 'roundBar';
        break;
      case 'pipe':
        _itemType = 'Pipe';
        _shape.text = definition.name;
        _formulaType = 'pipe';
        break;
      case 'hollowSection':
        _itemType = 'Hollow Section';
        _shape.text = definition.name;
        _formulaType = 'sectionWeightPerMeter';
        break;
      case 'coldFormedSection':
        _itemType = 'C Section';
        _shape.text = definition.name;
        _formulaType = 'sectionWeightPerMeter';
        break;
      case 'section':
        _itemType = 'Custom';
        _shape.text = definition.name;
        _formulaType = 'sectionWeightPerMeter';
        break;
      default:
        _itemType = 'Custom';
        _shape.text = definition.name;
    }
  }

  Widget _measurementProfileField() {
    final profiles = _configuration.measurementProfiles
        .where((entry) => entry.isActive)
        .toList(growable: false);
    return DropdownButtonFormField<String>(
      initialValue: profiles.any((entry) => entry.key == _measurementProfileKey)
          ? _measurementProfileKey
          : null,
      isExpanded: true,
      decoration: _inputDecoration('Measurement Profile'),
      items: profiles
          .map(
            (entry) => DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.name, overflow: TextOverflow.ellipsis),
        ),
      )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) return;
        final profile = _configuration.profileByKey(value);
        if (profile == null) return;
        setState(() {
          _measurementProfileKey = value;
          _unit.text = profile.baseUom;
          _purchaseUnit.text = profile.purchaseUom;
          _issueUnit.text = profile.issueUom;
          _secondaryUnit.text = profile.secondaryUom;
          _conversionMethod = profile.conversionMethod;
          _conversionFactor.text = _formatNumber(profile.defaultFactor);
          _dirty = true;
        });
      },
    );
  }

  Widget _conversionMethodField() {
    const methods = [
      'Fixed',
      'Formula',
      'Transaction Entered',
      'BOM Calculated',
      'Not Applicable',
    ];
    return DropdownButtonFormField<String>(
      initialValue: methods.contains(_conversionMethod)
          ? _conversionMethod
          : 'Fixed',
      isExpanded: true,
      decoration: _inputDecoration('Conversion Method'),
      items: methods
          .map((entry) => DropdownMenuItem(value: entry, child: Text(entry)))
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _conversionMethod = value;
          _dirty = true;
        });
      },
    );
  }

  Widget _smartAttributeFields() {
    final template = _attributeTemplateKey;
    final fields = <(String, String, String)>[];

    void add(String key, String label, String unit) {
      fields.add((key, label, unit));
    }

    switch (template) {
      case 'angle':
        add('leg1Mm', 'Leg 1', 'mm');
        add('leg2Mm', 'Leg 2', 'mm');
        add('thicknessMm', 'Thickness', 'mm');
        add('standardLengthMm', 'Standard Length', 'mm');
        break;
      case 'flat':
        add('widthMm', 'Width', 'mm');
        add('thicknessMm', 'Thickness', 'mm');
        add('standardLengthMm', 'Standard Length', 'mm');
        break;
      case 'plate':
        add('lengthMm', 'Length', 'mm');
        add('widthMm', 'Width', 'mm');
        add('thicknessMm', 'Thickness', 'mm');
        break;
      case 'roundBar':
        add('diameterMm', 'Diameter', 'mm');
        add('standardLengthMm', 'Standard Length', 'mm');
        break;
      case 'pipe':
      case 'hollowSection':
        add('outerDiameterMm', 'Outer Diameter / Width', 'mm');
        add('heightMm', 'Height', 'mm');
        add('wallThicknessMm', 'Wall Thickness', 'mm');
        add('standardLengthMm', 'Standard Length', 'mm');
        break;
      case 'section':
      case 'coldFormedSection':
        add('heightMm', 'Depth / Height', 'mm');
        add('widthMm', 'Flange Width', 'mm');
        add('thicknessMm', 'Thickness', 'mm');
        add('standardLengthMm', 'Standard Length', 'mm');
        break;
      case 'fastener':
        add('diameterMm', 'Diameter', 'mm');
        add('lengthMm', 'Length', 'mm');
        add('threadPitchMm', 'Thread Pitch', 'mm');
        add('piecesPerPack', 'Pieces per Pack', 'Nos');
        add('weightPer1000PiecesKg', 'Weight / 1000 Pieces', 'kg');
        break;
      case 'chemical':
      case 'packaged':
      case 'gas':
        add('packSize', 'Pack Size', _purchaseUnit.text);
        add('piecesPerPack', 'Pieces per Pack', 'Nos');
        add('shelfLifeDays', 'Shelf Life', 'days');
        break;
      case 'fabricatedMember':
        add('lengthMm', 'Finished Length', 'mm');
        add('weightPerPieceKg', 'Weight per Piece', 'kg');
        break;
      case 'assembly':
        add('weightPerPieceKg', 'Standard Assembly Weight', 'kg');
        break;
      default:
        add('lengthMm', 'Length', 'mm');
        add('widthMm', 'Width', 'mm');
        add('heightMm', 'Height', 'mm');
        add('weightPerPieceKg', 'Weight per Piece', 'kg');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth < 680
            ? constraints.maxWidth
            : (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: fields
              .map(
                (field) => SizedBox(
              width: fieldWidth,
              child: _numberField(
                controller: _attributeControllers[field.$1]!,
                label: '${field.$2} (${field.$3})',
              ),
            ),
          )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _autoCodeField() {
    return TextFormField(
      controller: _code,
      readOnly: true,
      decoration: _inputDecoration(
        'Item Code',
        requiredField: true,
      ).copyWith(
        prefixIcon: const Icon(Icons.auto_awesome_outlined, size: 18),
        suffixIcon: Tooltip(
          message: widget.isEditing
              ? 'Item code is locked after creation'
              : 'Generated automatically from nature, category and record ID',
          child: const Icon(Icons.lock_outline, size: 17),
        ),
      ),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) return 'Item Code is required.';
        return null;
      },
    );
  }

  void _refreshGeneratedCode({bool markDirty = true}) {
    if (widget.isEditing) return;

    final code = _generateItemCode(
      nature: _itemNature,
      category: _category.text,
      subCategory: _subCategory.text,
      documentId: _draftItemId,
    );

    if (_code.text == code) return;
    _code.text = code;
    if (markDirty) _markDirty();
  }

  String _generateItemCode({
    required String nature,
    required String category,
    required String subCategory,
    required String documentId,
  }) {
    const prefixes = <String, String>{
      'Raw Material': 'RM',
      'Bought-Out Component': 'BOC',
      'Consumable': 'CON',
      'Spare Part': 'SPR',
      'Tool & Equipment': 'TOL',
      'Safety Item': 'SAF',
      'Packaging Material': 'PKG',
      'Semi-Finished Good': 'SFG',
      'Finished Good': 'FG',
      'Service': 'SRV',
      'Asset': 'AST',
      'Scrap': 'SCP',
      'Other': 'ITM',
    };

    final naturePrefix = prefixes[nature] ?? 'ITM';
    final categoryDefinition =
    _configuration.categoryByName(nature, category);
    final subcategoryDefinition = _configuration.subcategoryByName(
      categoryDefinition,
      subCategory,
    );
    final normalizedCategory = category
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final categoryPrefix = subcategoryDefinition?.code.isNotEmpty == true
        ? subcategoryDefinition!.code
        : categoryDefinition?.code.isNotEmpty == true
        ? categoryDefinition!.code
        : normalizedCategory.isEmpty
        ? 'GEN'
        : normalizedCategory.padRight(3, 'X').substring(0, 3);
    final normalizedId = documentId
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final suffix = normalizedId.length <= 6
        ? normalizedId.padLeft(6, '0')
        : normalizedId.substring(normalizedId.length - 6);

    return '$naturePrefix-$categoryPrefix-$suffix';
  }

  Widget _engineeringTypeField() {
    return DropdownButtonFormField<String>(
      initialValue: ItemMasterModel.engineeringTypes.contains(_itemType)
          ? _itemType
          : 'Custom',
      decoration: _inputDecoration('Engineering Type'),
      items: ItemMasterModel.engineeringTypes
          .map(
            (type) => DropdownMenuItem(value: type, child: Text(type)),
      )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _itemType = value;
          _formulaType = WeightFormulaService.formulaTypeForMaterial(value);
          if (_shape.text.trim().isEmpty) _shape.text = value;
          _markDirty();
        });
      },
    );
  }

  Widget _formulaTypeField() {
    const formulas = [
      'plate',
      'pipe',
      'roundBar',
      'sectionWeightPerMeter',
    ];
    return DropdownButtonFormField<String>(
      initialValue: formulas.contains(_formulaType)
          ? _formulaType
          : 'sectionWeightPerMeter',
      decoration: _inputDecoration('Weight Formula'),
      items: const [
        DropdownMenuItem(value: 'plate', child: Text('Plate Volume')),
        DropdownMenuItem(value: 'pipe', child: Text('Pipe OD / ID')),
        DropdownMenuItem(value: 'roundBar', child: Text('Round Bar')),
        DropdownMenuItem(
          value: 'sectionWeightPerMeter',
          child: Text('Standard kg per metre'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _formulaType = value;
          _markDirty();
        });
      },
    );
  }

  Widget _valuationField() {
    return DropdownButtonFormField<String>(
      initialValue: ItemMasterModel.valuationMethods.contains(_valuationMethod)
          ? _valuationMethod
          : 'Weighted Average',
      decoration: _inputDecoration('Valuation Method'),
      items: ItemMasterModel.valuationMethods
          .map(
            (method) => DropdownMenuItem(value: method, child: Text(method)),
      )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _valuationMethod = value;
          _markDirty();
        });
      },
    );
  }

  Widget _uomField(
      TextEditingController controller,
      String label, {
        bool requiredField = true,
      }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (value) {
        final query = value.text.trim().toUpperCase();
        final units = _configuration.uoms
            .where((entry) => entry.isActive)
            .map((entry) => entry.code)
            .toList(growable: false);
        if (query.isEmpty) return units;
        return units.where((unit) => unit.contains(query));
      },
      onSelected: (value) {
        controller.text = value;
        _markDirty();
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        if (textController.text != controller.text) {
          textController.value = controller.value;
        }
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.characters,
          decoration: _inputDecoration(label, requiredField: requiredField),
          onChanged: (value) {
            controller.text = value.toUpperCase();
            _markDirty();
          },
          validator: (value) {
            if (requiredField && (value ?? '').trim().isEmpty) {
              return '$label is required.';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool requiredField = false,
    bool enabled = true,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(
        label,
        requiredField: requiredField,
        hint: hint,
      ),
      onChanged: (value) {
        _markDirty();
        onChanged?.call(value);
        setState(() {});
      },
      validator: requiredField
          ? (value) {
        if ((value ?? '').trim().isEmpty) return '$label is required.';
        return null;
      }
          : null,
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    double minimum = 0,
    double? maximum,
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label, helper: helper),
      onChanged: (_) {
        _markDirty();
        setState(() {});
      },
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return null;
        final number = double.tryParse(text);
        if (number == null) return 'Enter a valid number.';
        if (number < minimum) return 'Minimum value is $minimum.';
        if (maximum != null && number > maximum) {
          return 'Maximum value is $maximum.';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(
      String label, {
        bool requiredField = false,
        String? hint,
        String? helper,
      }) {
    return InputDecoration(
      labelText: requiredField ? '$label *' : label,
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: zMuted,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
      ),
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: zBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Future<void> _goNext() async {
    final valid = _validateCurrentStep();
    if (!valid) return;
    setState(() => _stepIndex++);
  }

  bool _validateCurrentStep() {
    final formValid = _formKey.currentState?.validate() ?? true;
    if (!formValid) return false;

    if (_stepIndex == 0) {
      if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) return false;
      if (_category.text.trim().isEmpty) {
        _showSnack('Category is required.');
        return false;
      }
      if (_subCategory.text.trim().isEmpty) {
        _showSnack('Subcategory is required.');
        return false;
      }
    }

    if (_stepIndex == 1 &&
        !_appliesToAllVerticals &&
        _selectedVerticalIds.isEmpty) {
      _showSnack('Select at least one vertical or choose Organization-wide.');
      return false;
    }

    if (_stepIndex == 2) {
      final conversion = _parseDouble(_conversionFactor.text);
      if (conversion <= 0) {
        _showSnack('Purchase-to-base conversion must be greater than zero.');
        return false;
      }
      final maximumStock = _parseDouble(_maximumStock.text);
      final minimumStock = _parseDouble(_minimumStock.text);
      if (maximumStock > 0 && maximumStock < minimumStock) {
        _showSnack('Maximum stock cannot be less than minimum stock.');
        return false;
      }
    }
    return true;
  }

  bool _validateAllForSave() {
    if (_code.text.trim().isEmpty ||
        _name.text.trim().isEmpty ||
        _category.text.trim().isEmpty ||
        _subCategory.text.trim().isEmpty) {
      setState(() => _stepIndex = 0);
      _showSnack(
        'Item code, item name, category and subcategory are required.',
      );
      return false;
    }

    if (!_appliesToAllVerticals && _selectedVerticalIds.isEmpty) {
      setState(() => _stepIndex = 1);
      _showSnack('Select at least one vertical or choose Organization-wide.');
      return false;
    }

    if (_unit.text.trim().isEmpty ||
        _purchaseUnit.text.trim().isEmpty ||
        _issueUnit.text.trim().isEmpty) {
      setState(() => _stepIndex = 2);
      _showSnack('Base, purchase and issue UOM are required.');
      return false;
    }

    final conversion = double.tryParse(_conversionFactor.text.trim());
    if (conversion == null || conversion <= 0) {
      setState(() => _stepIndex = 2);
      _showSnack('Purchase-to-base conversion must be greater than zero.');
      return false;
    }

    final minimumStock = double.tryParse(_minimumStock.text.trim()) ?? 0;
    final maximumStock = double.tryParse(_maximumStock.text.trim()) ?? 0;
    if (minimumStock < 0 || maximumStock < 0) {
      setState(() => _stepIndex = 2);
      _showSnack('Stock levels cannot be negative.');
      return false;
    }
    if (maximumStock > 0 && maximumStock < minimumStock) {
      setState(() => _stepIndex = 2);
      _showSnack('Maximum stock cannot be less than minimum stock.');
      return false;
    }

    final taxRate = double.tryParse(_taxRate.text.trim()) ?? 0;
    final tolerance = double.tryParse(_purchaseTolerance.text.trim()) ?? 0;
    if (taxRate < 0 || taxRate > 100 || tolerance < 0 || tolerance > 100) {
      setState(() => _stepIndex = taxRate < 0 || taxRate > 100 ? 0 : 3);
      _showSnack('Tax rate and purchase tolerance must be between 0 and 100.');
      return false;
    }

    return true;
  }

  Future<void> _save(List<VerticalModel> verticals) async {
    if (_saving || !_validateAllForSave()) return;

    final verticalNameById = {
      for (final vertical in verticals) vertical.id: vertical.name,
    };
    final selectedVerticalNames = _selectedVerticalIds
        .map((id) => verticalNameById[id] ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    setState(() => _saving = true);

    final item = ItemMasterModel(
      id: _draftItemId,
      itemCode: _code.text.trim().toUpperCase(),
      itemName: _name.text.trim(),
      itemNature: _itemNature,
      itemType: _technicalSpecificationEnabled ? _itemType : '',
      itemShape: _technicalSpecificationEnabled ? _shape.text.trim() : '',
      itemGrade: _technicalSpecificationEnabled ? _grade.text.trim() : '',
      description: _description.text.trim(),
      category: _category.text.trim(),
      subCategory: _subCategory.text.trim(),
      categoryCode: _configuration
          .categoryByName(_itemNature, _category.text)
          ?.code ??
          '',
      subCategoryCode: _configuration
          .subcategoryByName(
        _configuration.categoryByName(_itemNature, _category.text),
        _subCategory.text,
      )
          ?.code ??
          '',
      measurementProfileKey: _measurementProfileKey,
      attributeTemplateKey: _attributeTemplateKey,
      secondaryUnit: _secondaryUnit.text.trim().toUpperCase(),
      conversionMethod: _conversionMethod,
      secondaryConversionFactor: _parseDouble(
        _secondaryConversionFactor.text,
        fallback: 1,
      ),
      attributes: {
        for (final entry in _attributeControllers.entries)
          if (_parseDouble(entry.value.text) != 0)
            entry.key: _parseDouble(entry.value.text),
      },
      purchaseUnit: _purchaseUnit.text.trim().toUpperCase(),
      issueUnit: _issueUnit.text.trim().toUpperCase(),
      conversionFactor: _parseDouble(_conversionFactor.text, fallback: 1),
      hsnCode: _hsnCode.text.trim(),
      taxRate: _parseDouble(_taxRate.text),
      valuationMethod: _valuationMethod,
      yieldStrength:
      _technicalSpecificationEnabled ? _yieldStrength.text.trim() : '',
      coating: _technicalSpecificationEnabled ? _coating.text.trim() : '',
      coatingType:
      _technicalSpecificationEnabled ? _coating.text.trim() : '',
      coatingSpec:
      _technicalSpecificationEnabled ? _coatingSpec.text.trim() : '',
      density:
      _technicalSpecificationEnabled ? _parseDouble(_density.text) : 0,
      formulaType: _technicalSpecificationEnabled ? _formulaType : '',
      weightFormula: _technicalSpecificationEnabled ? _formulaType : '',
      standardWeightPerMeter: _technicalSpecificationEnabled
          ? _parseDouble(_standardWeight.text)
          : 0,
      baseWeightPerMeter: _technicalSpecificationEnabled
          ? _parseDouble(_baseWeight.text)
          : 0,
      coatingFormula: _technicalSpecificationEnabled
          ? _coatingFormula.text.trim()
          : '',
      unit: _unit.text.trim().toUpperCase(),
      inventoryTracked: _inventoryTracked,
      batchTracked: _inventoryTracked && _batchTracked,
      serialTracked: _inventoryTracked && _serialTracked,
      expiryTracked: _inventoryTracked && _expiryTracked,
      qualityInspectionRequired: _qualityInspectionRequired,
      allowNegativeStock: _inventoryTracked && _allowNegativeStock,
      technicalSpecificationEnabled: _technicalSpecificationEnabled,
      reorderLevel: _parseDouble(_reorderLevel.text),
      minimumStockLevel: _parseDouble(_minimumStock.text),
      maximumStockLevel: _parseDouble(_maximumStock.text),
      purchaseTolerancePercent: _parseDouble(_purchaseTolerance.text),
      appliesToAllVerticals: _appliesToAllVerticals,
      verticalIds: _appliesToAllVerticals
          ? const []
          : _selectedVerticalIds.toList(growable: false),
      verticalNames: _appliesToAllVerticals
          ? const []
          : selectedVerticalNames,
      isActive: _isActive,
      createdAt: _existing?.createdAt,
      updatedAt: _existing?.updatedAt,
    );

    try {
      await _repository.saveItem(item);
      if (!mounted) return;
      _dirty = false;
      Navigator.of(context).pop(true);
    } on ItemMasterDuplicateException catch (error) {
      _showSnack(error.message);
      setState(() => _stepIndex = 0);
    } on FormatException catch (error) {
      _showSnack(error.message);
    } catch (error, stackTrace) {
      debugPrint(
        'ITEM_MASTER_SAVE_ERROR tenantId=${widget.tenantId} '
            'path=${_repository.collectionPath} error=$error\n$stackTrace',
      );
      _showSnack('Unable to save the item. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestClose() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await _confirmDiscardChanges();
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<bool?> _confirmDiscardChanges() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('The changes made on this item have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _markDirty() {
    if (_dirty) return;
    _dirty = true;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double _parseDouble(String value, {double fallback = 0}) {
    return double.tryParse(value.trim()) ?? fallback;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  static IconData _natureIcon(String nature) {
    switch (nature) {
      case 'Raw Material':
        return Icons.view_in_ar_outlined;
      case 'Consumable':
        return Icons.local_fire_department_outlined;
      case 'Spare Part':
        return Icons.settings_outlined;
      case 'Tool & Equipment':
        return Icons.handyman_outlined;
      case 'Safety Item':
        return Icons.health_and_safety_outlined;
      case 'Packaging Material':
        return Icons.inventory_outlined;
      case 'Semi-Finished Good':
        return Icons.precision_manufacturing_outlined;
      case 'Finished Good':
        return Icons.task_alt_outlined;
      case 'Service':
        return Icons.design_services_outlined;
      case 'Asset':
        return Icons.apartment_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class _StepDefinition {
  const _StepDefinition({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: zText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: zMuted,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class _SelectablePanel extends StatelessWidget {
  const _SelectablePanel({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? color.withValues(alpha: 0.07) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? color : zBorder,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.12)
                      : zSurfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: selected ? color : zMuted, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: zText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: zMuted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? color : zMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TogglePanel extends StatelessWidget {
  const _TogglePanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: value && enabled
              ? color.withValues(alpha: 0.055)
              : Colors.white,
          border: Border.all(
            color: value && enabled
                ? color.withValues(alpha: 0.45)
                : zBorder,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: value && enabled
                    ? color.withValues(alpha: 0.12)
                    : zSurfaceSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 19,
                color: value && enabled ? color : zMuted,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: zText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: zMuted,
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled && value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: zText,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: zMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: zMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: zText,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBadge extends StatelessWidget {
  const _ControlBadge({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: enabled ? color.withValues(alpha: 0.08) : zSurfaceSoft,
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.30) : zBorder,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? color : zMuted,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? zSuccess : zMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
