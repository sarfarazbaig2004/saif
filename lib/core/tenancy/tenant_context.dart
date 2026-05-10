import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TenantContext extends ChangeNotifier {
  String _selectedTenantId = '';
  List<String> _allowedTenantIds = [];
  Map<String, String> _tenantNames = {};

  String get selectedTenantId => _selectedTenantId;
  List<String> get allowedTenantIds => _allowedTenantIds;
  Map<String, String> get tenantNames => _tenantNames;

  void setSelectedTenant(String id) {
    _selectedTenantId = id;
    notifyListeners();
  }

  void selectTenant(String id) {
    setSelectedTenant(id);
  }

  void replaceAllowedTenants(List<String> ids) {
    _allowedTenantIds = ids;
    notifyListeners();
  }

  void setTenantNames(Map<String, String> names) {
    _tenantNames = Map<String, String>.from(names);
    notifyListeners();
  }
}

extension TenantContextExtension on BuildContext {
  TenantContext get tenant => read<TenantContext>();
  TenantContext get watchTenant => watch<TenantContext>();
}
