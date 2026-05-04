import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TenantContext extends ChangeNotifier {
  String _selectedTenantId = '';
  List<String> _allowedTenantIds = [];
  bool _isPlatformAdmin = false;
  Map<String, String> _tenantNames = {};

  String get selectedTenantId => _selectedTenantId;
  List<String> get allowedTenantIds => _allowedTenantIds;
  bool get isPlatformAdmin => _isPlatformAdmin;
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

  void setPlatformAdmin(bool value) {
    _isPlatformAdmin = value;
    notifyListeners();
  }

  void setTenantNames(Map<String, String> names) {
    _tenantNames = names;
    notifyListeners();
  }
}

extension TenantContextExtension on BuildContext {
  TenantContext get tenant => read<TenantContext>();
  TenantContext get watchTenant => watch<TenantContext>();
}
