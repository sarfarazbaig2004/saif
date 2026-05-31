import 'package:QUIK/modules/production/material_requirements/models/material_requirement_model.dart';
import 'package:QUIK/modules/purchase/purchase_requisitions/models/purchase_requisition_model.dart';
import 'package:QUIK/modules/purchase/purchase_requisitions/repositories/purchase_requisition_repository.dart';

class MaterialRequirementPrService {
  MaterialRequirementPrService({required this.tenantId});

  final String tenantId;

  Future<PurchaseRequisitionModel?> createFromRequirement({
    required MaterialRequirementModel requirement,
  }) async {
    final lines = requirement.lines
        .where((line) => line.purchaseRequiredQty > 0)
        .map(
          (line) => PurchaseRequisitionLineModel(
            lineNo: line.lineNo,
            material: line.material,
            section: line.section,
            requiredQty: line.requiredQty,
            availableQty: line.availableQty,
            reservedQty: line.reservedQty,
            purchaseQty: line.purchaseRequiredQty,
            unit: line.unit,
            remarks: line.remarks,
          ),
        )
        .toList(growable: false);

    if (lines.isEmpty) return null;

    final repository = PurchaseRequisitionRepository(tenantId: tenantId);
    final requisitionId = repository.newRequisitionId();

    final requisition = PurchaseRequisitionModel(
      requisitionId: requisitionId,
      requisitionNo: repository.nextRequisitionNo(),
      materialRequirementId: requirement.requirementId,
      materialRequirementNo: requirement.requirementNo,
      jobCardId: requirement.jobCardId,
      jobCardNo: requirement.jobCardNo,
      customerPoId: requirement.customerPoId,
      poNumber: requirement.poNumber,
      customerName: requirement.customerName,
      bomId: requirement.bomId,
      bomNumber: requirement.bomNumber,
      status: 'draft',
      lines: lines,
      tenantId: tenantId,
      companyId: tenantId,
    );

    await repository.save(requisition);
    return requisition;
  }
}
