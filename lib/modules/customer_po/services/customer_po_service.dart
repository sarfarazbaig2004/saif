import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/repositories/customer_po_repository.dart';

class CustomerPoService {
  final CustomerPoRepository _repository;

  CustomerPoService({CustomerPoRepository? repository})
    : _repository = repository ?? CustomerPoRepository();

  Future<void> createCustomerPo(CustomerPoModel po) async {
    if (po.poNumber.trim().isEmpty) {
      throw Exception('PO number is required');
    }

    if (po.customerName.trim().isEmpty) {
      throw Exception('Customer name is required');
    }

    if (po.totalValue <= 0) {
      throw Exception('Total PO value must be greater than zero');
    }

    await _repository.createCustomerPo(po);
  }
}
