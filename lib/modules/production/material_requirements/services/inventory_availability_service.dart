import 'package:QUIK/modules/inventory/fabrication/repositories/fabrication_inventory_repository.dart';
import 'package:QUIK/modules/production/material_requirements/models/material_requirement_model.dart';

enum InventoryAvailabilityStatus { available, partial, shortage }

class InventoryAvailabilityLine {
  final MaterialRequirementLineModel requirementLine;
  final double availableQty;
  final double shortageQty;
  final InventoryAvailabilityStatus status;

  const InventoryAvailabilityLine({
    required this.requirementLine,
    required this.availableQty,
    required this.shortageQty,
    required this.status,
  });
}

class InventoryAvailabilityResult {
  final List<InventoryAvailabilityLine> lines;

  const InventoryAvailabilityResult({required this.lines});

  InventoryAvailabilityStatus get status {
    if (lines.isEmpty) return InventoryAvailabilityStatus.shortage;
    if (lines.every(
      (line) => line.status == InventoryAvailabilityStatus.available,
    )) {
      return InventoryAvailabilityStatus.available;
    }
    if (lines.any(
      (line) => line.status == InventoryAvailabilityStatus.partial,
    )) {
      return InventoryAvailabilityStatus.partial;
    }
    if (lines.any((line) => line.availableQty > 0)) {
      return InventoryAvailabilityStatus.partial;
    }
    return InventoryAvailabilityStatus.shortage;
  }
}

class InventoryAvailabilityService {
  InventoryAvailabilityService({required this.tenantId})
    : _inventoryRepository = FabricationInventoryRepository(tenantId: tenantId);

  final String tenantId;
  final FabricationInventoryRepository _inventoryRepository;

  Future<InventoryAvailabilityResult> checkRequirement({
    required MaterialRequirementModel requirement,
  }) async {
    final stock = await _inventoryRepository.fetchStockSummary();
    final lines = requirement.lines
        .map((line) {
          final requiredQty = _requiredQty(line);
          final availableQty = stock
              .where(
                (row) =>
                    _matches(line, row.materialDescription, row.materialCode),
              )
              .fold<double>(0, (total, row) => total + row.closingStockKg);
          final shortageQty = requiredQty - availableQty;
          final status = shortageQty <= 0
              ? InventoryAvailabilityStatus.available
              : availableQty > 0
              ? InventoryAvailabilityStatus.partial
              : InventoryAvailabilityStatus.shortage;
          return InventoryAvailabilityLine(
            requirementLine: line,
            availableQty: availableQty,
            shortageQty: shortageQty <= 0 ? 0 : shortageQty,
            status: status,
          );
        })
        .toList(growable: false);

    return InventoryAvailabilityResult(lines: lines);
  }

  double _requiredQty(MaterialRequirementLineModel line) {
    if (line.requiredWeightKg > 0) return line.requiredWeightKg;
    return line.requiredQty;
  }

  bool _matches(
    MaterialRequirementLineModel line,
    String stockDescription,
    String stockCode,
  ) {
    final material = _normalize(line.material);
    final section = _normalize(line.section);
    final description = _normalize(stockDescription);
    final code = _normalize(stockCode);
    if (material.isNotEmpty &&
        (description.contains(material) || code.contains(material))) {
      return true;
    }
    if (section.isNotEmpty &&
        (description.contains(section) || code.contains(section))) {
      return true;
    }
    return false;
  }

  String _normalize(Object? value) {
    return value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
