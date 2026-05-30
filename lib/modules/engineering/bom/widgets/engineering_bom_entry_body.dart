import 'package:flutter/material.dart';

import 'package:QUIK/modules/engineering/bom/helpers/bom_column_config.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_grid_card.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_header.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_revision_tabs.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_fastener_bom_models.dart';
import 'package:QUIK/modules/engineering/bom/widgets/engineering_fastener_bom_table.dart';

class EngineeringBomEntryBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController bomNo;
  final TextEditingController inquiryId;
  final TextEditingController customer;
  final TextEditingController project;
  final TextEditingController projectQuantity;
  final TextEditingController revision;
  final String status;
  final String revisionReason;
  final List<BomLineDraft> lines;
  final List<FastenerBomLineDraft> fasteners;
  final List<String> visibleColumns;
  final List<BomCustomField> customFields;
  final double projectQty;
  final double weightPerStructure;
  final double totalProjectWeight;
  final String tenantId;
  final ScrollController scrollController;
  final VoidCallback onChanged;
  final VoidCallback onAddLine;
  final ValueChanged<int> onDeleteLine;
  final VoidCallback onCustomizeColumns;
  final VoidCallback onAddFastener;
  final ValueChanged<int> onDeleteFastener;

  const EngineeringBomEntryBody({
    super.key,
    required this.formKey,
    required this.bomNo,
    required this.inquiryId,
    required this.customer,
    required this.project,
    required this.projectQuantity,
    required this.revision,
    required this.status,
    required this.revisionReason,
    required this.lines,
    required this.fasteners,
    required this.visibleColumns,
    required this.customFields,
    required this.projectQty,
    required this.weightPerStructure,
    required this.totalProjectWeight,
    required this.tenantId,
    required this.scrollController,
    required this.onChanged,
    required this.onAddLine,
    required this.onDeleteLine,
    required this.onCustomizeColumns,
    required this.onAddFastener,
    required this.onDeleteFastener,
  });

  @override
  Widget build(BuildContext context) {
    final readOnly = status.toLowerCase() == 'approved';
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EngineeringBomHeader(
              bomNo: bomNo,
              inquiryId: inquiryId,
              customer: customer,
              project: project,
              projectQuantity: projectQuantity,
              revision: revision,
              onChanged: onChanged,
              readOnly: readOnly,
            ),
            const SizedBox(height: 14),
            EngineeringBomRevisionTabs(
              bomNo: bomNo.text,
              revision: revision.text,
              status: status,
              revisionReason: revisionReason,
            ),
            const SizedBox(height: 14),
            EngineeringBomSummary(
              weightPerStructure: weightPerStructure,
              totalProjectWeight: totalProjectWeight,
              onAddLine: onAddLine,
              readOnly: readOnly,
            ),
            const SizedBox(height: 14),
            EngineeringBomGridCard(
              lines: lines,
              visibleColumns: visibleColumns,
              customFields: customFields,
              projectQuantity: projectQty,
              tenantId: tenantId,
              scrollController: scrollController,
              onChanged: onChanged,
              onCustomizeColumns: onCustomizeColumns,
              onDelete: onDeleteLine,
              readOnly: readOnly,
            ),
            const SizedBox(height: 14),
            EngineeringFastenerBomTable(
              lines: fasteners,
              projectQuantity: projectQty,
              onAddLine: onAddFastener,
              onDelete: onDeleteFastener,
              onChanged: onChanged,
              readOnly: readOnly,
            ),
          ],
        ),
      ),
    );
  }
}
