import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/job_cards/models/job_card_model.dart';
import 'package:QUIK/modules/production/job_cards/screens/job_card_form_screen.dart';
import 'package:QUIK/modules/production/material_requirements/models/material_requirement_model.dart';
import 'package:QUIK/modules/production/material_requirements/repositories/material_requirement_repository.dart';
import 'package:QUIK/modules/production/material_requirements/services/inventory_availability_service.dart';

class JobCardDetailScreen extends StatelessWidget {
  final String tenantId;
  final JobCardModel jobCard;

  const JobCardDetailScreen({
    super.key,
    required this.tenantId,
    required this.jobCard,
  });

  Future<void> _edit(BuildContext context, String activeTenantId) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            JobCardFormScreen(tenantId: activeTenantId, jobCard: jobCard),
      ),
    );

    if (saved == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _generateMaterialRequirement(
    BuildContext context,
    String activeTenantId,
  ) async {
    final lines = _buildRequirementLines();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No job card items available.')),
      );
      return;
    }

    try {
      final repository = MaterialRequirementRepository(
        tenantId: activeTenantId,
      );
      final requirementId = repository.newRequirementId();
      final totalWeight = lines.fold<double>(
        0,
        (total, line) => total + line.requiredWeightKg,
      );

      final requirement = MaterialRequirementModel(
        requirementId: requirementId,
        requirementNo: repository.nextRequirementNo(jobCard.jobCardNo),
        jobCardId: jobCard.jobCardId,
        jobCardNo: jobCard.jobCardNo,
        customerPoId: jobCard.customerPoId,
        customerName: jobCard.customerName,
        projectCode: jobCard.projectCode,
        poNumber: jobCard.poNumber,
        bomId: jobCard.bomId,
        bomNumber: jobCard.bomReference,
        status: 'draft',
        lines: lines,
        totalWeightKg: totalWeight,
        tenantId: activeTenantId,
        companyId: activeTenantId,
      );

      await repository.save(requirement);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Material requirement draft created: ${requirement.requirementNo}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create material requirement: $e')),
      );
    }
  }

  Future<void> _checkInventoryAvailability(
    BuildContext context,
    String activeTenantId,
  ) async {
    final lines = _buildRequirementLines();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No material requirement lines found.')),
      );
      return;
    }

    final requirement = MaterialRequirementModel(
      requirementId: 'preview-${jobCard.jobCardId}',
      requirementNo: 'Preview',
      jobCardId: jobCard.jobCardId,
      jobCardNo: jobCard.jobCardNo,
      customerPoId: jobCard.customerPoId,
      customerName: jobCard.customerName,
      projectCode: jobCard.projectCode,
      poNumber: jobCard.poNumber,
      bomId: jobCard.bomId,
      bomNumber: jobCard.bomReference,
      status: 'draft',
      lines: lines,
      totalWeightKg: lines.fold<double>(
        0,
        (total, line) => total + line.requiredWeightKg,
      ),
      tenantId: activeTenantId,
      companyId: activeTenantId,
    );

    try {
      final result = await InventoryAvailabilityService(
        tenantId: activeTenantId,
      ).checkRequirement(requirement: requirement);
      if (!context.mounted) return;
      _showAvailabilityDialog(context, result);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to check inventory: $e')));
    }
  }

  List<MaterialRequirementLineModel> _buildRequirementLines() {
    if (jobCard.sourcePoItems.isNotEmpty) {
      return jobCard.sourcePoItems
          .asMap()
          .entries
          .map((entry) {
            final item = entry.value;
            final material = _firstNonEmpty([
              item['bomMaterial'],
              item['material'],
              item['itemName'],
              item['description'],
            ]);
            final section = _firstNonEmpty([
              item['bomSection'],
              item['section'],
              item['itemName'],
            ]);
            final weight = _toDouble(item['bomWeight'] ?? item['weightKg']);
            final qty = _toDouble(item['quantity']);
            return MaterialRequirementLineModel(
              lineNo: entry.key + 1,
              sourceItemId: _string(item['id'] ?? item['quotationItemId']),
              material: material,
              section: section,
              requiredWeightKg: weight > 0 ? weight : qty,
              requiredQty: qty,
              availableQty: 0,
              reservedQty: 0,
              shortageQty: 0,
              purchaseRequiredQty: 0,
              unit: weight > 0
                  ? 'KG'
                  : _firstNonEmpty([item['uom'], item['unit']]),
              lengthMm: _toDouble(item['bomLengthMm']),
              remarks:
                  'Customer: ${jobCard.customerName}; Project: ${jobCard.projectCode}; PO: ${jobCard.poNumber}',
            );
          })
          .toList(growable: false);
    }

    return jobCard.quantityLines
        .asMap()
        .entries
        .map((entry) {
          final line = entry.value;
          return MaterialRequirementLineModel(
            lineNo: entry.key + 1,
            sourceItemId: '',
            material: line.label,
            section: line.label,
            requiredWeightKg: line.unit.toLowerCase() == 'kg'
                ? line.quantity
                : 0,
            requiredQty: line.quantity,
            availableQty: 0,
            reservedQty: 0,
            shortageQty: 0,
            purchaseRequiredQty: 0,
            unit: line.unit,
            lengthMm: 0,
            remarks:
                'Customer: ${jobCard.customerName}; Project: ${jobCard.projectCode}; PO: ${jobCard.poNumber}',
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final activeTenantId = tenantId.trim();
    if (activeTenantId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Select a company workspace first.')),
      );
    }

    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: Text(jobCard.jobCardNo),
        actions: [
          TextButton.icon(
            onPressed: () =>
                _checkInventoryAvailability(context, activeTenantId),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Check Inventory Availability'),
          ),
          TextButton.icon(
            onPressed: () =>
                _generateMaterialRequirement(context, activeTenantId),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Generate Material Requirement'),
          ),
          TextButton.icon(
            onPressed: () => _edit(context, activeTenantId),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(jobCard: jobCard),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Order Details',
              children: [
                _detail('Project Code', jobCard.projectCode),
                _detail('Customer', jobCard.customerName),
                _detail('PO Number', jobCard.poNumber),
                _detail('Division', jobCard.division),
                _detail('Product Code', jobCard.productCode),
                _detail('Product Name', jobCard.productName),
                _detail('Contractor', jobCard.contractor),
                _detail('Drawing No', jobCard.drawingNo),
                _detail('Drawing Revision', jobCard.drawingRevision),
                _detail('Revision No', jobCard.revisionNo),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Planning',
              children: [
                _detail('BOM ID', jobCard.bomId),
                _detail('BOM Reference', jobCard.bomReference),
                _detail('BOQ ID', jobCard.boqId),
                _detail('Planned Qty', _qty(jobCard.plannedQty, jobCard.unit)),
                _detail(
                  'Completed Qty',
                  _qty(jobCard.completedQty, jobCard.unit),
                ),
                _detail('Balance Qty', _qty(jobCard.balanceQty, jobCard.unit)),
                _detail('Planned Start', _date(jobCard.plannedStartDate)),
                _detail('Planned End', _date(jobCard.plannedEndDate)),
                _detail('Target Date', _date(jobCard.targetDate)),
                _detail(
                  'Dispatch Commitment',
                  _date(jobCard.dispatchCommitmentDate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Quantity Breakup',
              children: jobCard.quantityLines.isEmpty
                  ? [
                      _detail(
                        'Quantity',
                        _qty(jobCard.plannedQty, jobCard.unit),
                      ),
                    ]
                  : jobCard.quantityLines
                        .map(
                          (line) => _detail(
                            line.label.isEmpty ? 'Quantity' : line.label,
                            _qty(line.quantity, line.unit),
                          ),
                        )
                        .toList(growable: false),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Status',
              children: [
                _detail('Priority', jobCard.priority),
                _detail('Status', jobCard.status),
                _detail('Delay Reason', jobCard.delayReason),
                _detail('Remarks', jobCard.remarks),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return _DetailRow(label: label, value: value.trim().isEmpty ? '-' : value);
  }

  String _qty(double value, String unit) {
    return '${value.toStringAsFixed(2)} ${unit.trim().isEmpty ? 'nos' : unit}';
  }

  String _date(DateTime? value) {
    if (value == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _string(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _string(Object? value) => value?.toString().trim() ?? '';

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showAvailabilityDialog(
    BuildContext context,
    InventoryAvailabilityResult result,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Inventory Status: ${_availabilityLabel(result.status)}'),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Material')),
                DataColumn(label: Text('Required')),
                DataColumn(label: Text('Available')),
                DataColumn(label: Text('Shortage')),
              ],
              rows: result.lines
                  .map((line) {
                    final requirement = line.requirementLine;
                    final material = _firstNonEmpty([
                      requirement.material,
                      requirement.section,
                    ]);
                    return DataRow(
                      cells: [
                        DataCell(Text(material.isEmpty ? '-' : material)),
                        DataCell(Text(_kg(_requiredQty(requirement)))),
                        DataCell(Text(_kg(line.availableQty))),
                        DataCell(Text(_kg(line.shortageQty))),
                      ],
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _availabilityLabel(InventoryAvailabilityStatus status) {
    switch (status) {
      case InventoryAvailabilityStatus.available:
        return 'Available';
      case InventoryAvailabilityStatus.partial:
        return 'Partial';
      case InventoryAvailabilityStatus.shortage:
        return 'Shortage';
    }
  }

  double _requiredQty(MaterialRequirementLineModel line) {
    if (line.requiredWeightKg > 0) return line.requiredWeightKg;
    return line.requiredQty;
  }

  String _kg(double value) => '${value.toStringAsFixed(2)} kg';
}

class _SummaryCard extends StatelessWidget {
  final JobCardModel jobCard;

  const _SummaryCard({required this.jobCard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: zBlueSoft,
            child: Icon(Icons.assignment_outlined, color: zBlue),
          ),
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobCard.jobCardNo,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jobCard.productName.isEmpty
                      ? jobCard.productCode
                      : jobCard.productName,
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _Pill(label: 'Status', value: jobCard.status),
          _Pill(label: 'Priority', value: jobCard.priority),
          _Pill(
            label: 'Balance',
            value: '${jobCard.balanceQty.toStringAsFixed(2)} ${jobCard.unit}',
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: zSurfaceSoft,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: ${value.trim().isEmpty ? '-' : value}',
        style: const TextStyle(
          color: zText,
          fontSize: 12.6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            style: const TextStyle(
              color: zText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                color: zMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: zText,
                fontSize: 13.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
