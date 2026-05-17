import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/services/customer_po_service.dart';

class CustomerPoProvider extends ChangeNotifier {
  final CustomerPoService _service;

  CustomerPoProvider({CustomerPoService? service})
    : _service = service ?? CustomerPoService();

  bool _loading = false;

  bool get loading => _loading;

  Future<void> createCustomerPo(CustomerPoModel po) async {
    try {
      _loading = true;
      notifyListeners();

      await _service.createCustomerPo(po);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomerPo(CustomerPoModel po) async {
    try {
      _loading = true;
      notifyListeners();

      await _service.updateCustomerPo(po);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
