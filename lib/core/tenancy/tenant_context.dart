import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:QUIK/core/app/aman_app_config.dart';

class TenantContext extends ChangeNotifier {
  String _selectedTenantId = AmanAppConfig.tenantId;
  List<String> _allowedTenantIds = const [AmanAppConfig.tenantId];
  Map<String, String> _tenantNames = const {
    AmanAppConfig.tenantId: AmanAppConfig.companyName,
  };

  String get selectedTenantId => _selectedTenantId;
  List<String> get allowedTenantIds => _allowedTenantIds;
  Map<String, String> get tenantNames => _tenantNames;

  void setSelectedTenant(String id) {
    _selectedTenantId = AmanAppConfig.tenantId;
    notifyListeners();
  }

  void selectTenant(String id) {
    setSelectedTenant(id);
  }

  void replaceAllowedTenants(List<String> ids) {
    _allowedTenantIds = const [AmanAppConfig.tenantId];
    notifyListeners();
  }

  void setTenantNames(Map<String, String> names) {
    _tenantNames = const {AmanAppConfig.tenantId: AmanAppConfig.companyName};
    notifyListeners();
  }
}

extension TenantContextExtension on BuildContext {
  TenantContext get tenant => read<TenantContext>();
  TenantContext get watchTenant => watch<TenantContext>();
}
