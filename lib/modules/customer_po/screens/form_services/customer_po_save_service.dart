import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/providers/customer_po_provider.dart';

class CustomerPoSaveService {
  const CustomerPoSaveService._();

  static Future<void> save({
    required CustomerPoProvider provider,
    required bool isEditMode,
    required CustomerPoModel po,
  }) async {
    if (isEditMode) {
      await provider.updateCustomerPo(po);
    } else {
      await provider.createCustomerPo(po);
    }
  }
}
