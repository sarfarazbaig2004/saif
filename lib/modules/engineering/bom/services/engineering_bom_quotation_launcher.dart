import 'package:flutter/material.dart';

import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';
import 'package:QUIK/modules/engineering/bom/services/engineering_bom_quotation_seed.dart';
import 'package:QUIK/modules/sales/quotations/quotation_screen_local.dart';

void openEngineeringBomQuotation({
  required BuildContext context,
  required String companyId,
  required String format,
  required String bomId,
  required String bomNo,
  required String inquiryId,
  required String customer,
  required String project,
  required double totalProjectWeight,
  required List<EngineeringBomLineModel> lines,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => QuotationScreenLocal(
        companyId: companyId,
        inquirySeed: EngineeringBomQuotationSeed.build(
          format: format,
          bomId: bomId,
          bomNo: bomNo,
          inquiryId: inquiryId,
          customer: customer,
          project: project,
          totalProjectWeight: totalProjectWeight,
          lines: lines,
        ),
      ),
    ),
  );
}
