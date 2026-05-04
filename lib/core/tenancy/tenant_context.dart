import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class TenantContext extends ChangeNotifier {
  TenantContext({
    required String selectedTenantId,
    required List<String> allowedTenantIds,
    required bool isPlatformAdmin,
    Map<String, String>? tenantNames,
  }) : _selectedTenantId = selectedTenantId.trim(),
       _allowedTenantIds = _normalizeTenantIds(allowedTenantIds),
       _isPlatformAdmin = isPlatformAdmin,
       _tenantNames = Map<String, String>.from(tenantNames ?? {}) {
    if (_selectedTenantId.isEmpty && _allowedTenantIds.isNotEmpty) {
      _selectedTenantId = _allowedTenantIds.first;
    }
  }

  String _selectedTenantId;
  List<String> _allowedTenantIds;
  bool _isPlatformAdmin;
  final Map<String, String> _tenantNames;

  String get selectedTenantId => _selectedTenantId;
  String get selectedCompanyId => _selectedTenantId;
  List<String> get allowedTenantIds => List.unmodifiable(_allowedTenantIds);
  bool get hasTenant => _selectedTenantId.isNotEmpty;
  bool get canSwitchTenant => _isPlatformAdmin || _allowedTenantIds.length > 1;
  bool get isPlatformAdmin => _isPlatformAdmin;

  String tenantName(String tenantId) {
    final id = tenantId.trim();
    if (id.isEmpty) return '';
    return (_tenantNames[id] ?? id).trim();
  }

  bool canAccess(String tenantId) {
    final id = tenantId.trim();
    if (id.isEmpty) return false;
    return _isPlatformAdmin || _allowedTenantIds.contains(id);
  }

  void selectTenant(String tenantId) {
    final id = tenantId.trim();
    if (id.isEmpty || id == _selectedTenantId || !canAccess(id)) return;
    _selectedTenantId = id;
    notifyListeners();
  }

  void replaceAllowedTenants(List<String> tenantIds) {
    _allowedTenantIds = _normalizeTenantIds(tenantIds);
    if (!canAccess(_selectedTenantId)) {
      _selectedTenantId = _allowedTenantIds.isEmpty
          ? ''
          : _allowedTenantIds.first;
    }
    notifyListeners();
  }

  void setPlatformAdmin(bool value) {
    if (_isPlatformAdmin == value) return;
    _isPlatformAdmin = value;
    notifyListeners();
  }

  void setTenantNames(Map<String, String> tenantNames) {
    _tenantNames
      ..clear()
      ..addAll(tenantNames);
    notifyListeners();
  }

  static List<String> _normalizeTenantIds(Iterable<String> tenantIds) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final tenantId in tenantIds) {
      final id = tenantId.trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      normalized.add(id);
    }
    return normalized;
  }
}

extension TenantContextReader on BuildContext {
  TenantContext get tenant => read<TenantContext>();
  TenantContext get watchTenant => watch<TenantContext>();
  String get selectedTenantId => read<TenantContext>().selectedTenantId;
}
