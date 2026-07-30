import 'package:flutter/material.dart';

import 'package:QUIK/modules/engineering/bom/widgets/engineering_bom_models.dart';
import 'package:QUIK/modules/inventory/item_master/screens_add_item_master.dart';
import 'package:QUIK/modules/inventory/item_master/screens_item_master_list.dart';

class EngineeringBomMaterialLookup {
  const EngineeringBomMaterialLookup._();

  static Future<void> pick({
    required BuildContext context,
    required String tenantId,
    required BomLineDraft line,
    required VoidCallback onChanged,
  }) async {
    final material = await showDialog<MaterialMasterModel>(
      context: context,
      builder: (_) => MaterialPickerDialog(tenantId: tenantId),
    );
    if (material == null) return;
    line.applyMaterial(material);
    onChanged();
  }
}
