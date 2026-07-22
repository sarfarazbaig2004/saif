// FILE PATH: lib/modules/administration/company/screen_create_invite.dart

import 'package:flutter/material.dart';

import 'package:QUIK/core/modules/module_registry.dart';
import 'package:QUIK/core/modules/providers/module_access_provider.dart';
import 'package:QUIK/core/permissions/permission_catalogue.dart';
import 'package:QUIK/core/permissions/permission_evaluator.dart';
import 'package:QUIK/core/permissions/vertical_permission_assignment.dart';
import 'package:QUIK/core/permissions/vertical_permission_editor.dart';
import 'package:QUIK/modules/administration/users/helpers/user_management_constants.dart';
import 'package:QUIK/modules/administration/users/helpers/user_management_formatters.dart';
import 'package:QUIK/modules/administration/users/models/organization_access_selection.dart';
import 'package:QUIK/modules/administration/users/services/user_management_service.dart';
import 'package:QUIK/modules/administration/users/widgets/vertical_factory_access_selector.dart';
import 'package:QUIK/modules/settings/factory_master/factory_model.dart';
import 'package:QUIK/modules/settings/factory_master/factory_repository.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_model.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_repository.dart';

const Color _invitePrimaryColor = Color(0xFF17324D);
const Color _inviteAccentColor = Color(0xFF3B82F6);
const Color _inviteScaffoldBgColor = Color(0xFFF4F7FB);
const Color _inviteCardBorderColor = Color(0xFFE2E8F0);
const Color _inviteMutedTextColor = Color(0xFF64748B);
const Color _inviteHeadingTextColor = Color(0xFF0F172A);

class ScreenCreateInvite extends StatefulWidget {
  final String companyId;
  final String currentUid;
  final String? industry;

  const ScreenCreateInvite({
    super.key,
    required this.companyId,
    required this.currentUid,
    this.industry,
  });

  @override
  State<ScreenCreateInvite> createState() => _ScreenCreateInviteState();
}

class _ScreenCreateInviteState extends State<ScreenCreateInvite> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final UserManagementService _userManagementService = UserManagementService();
  late final FactoryRepository _factoryRepository;
  late final Stream<List<FactoryModel>> _factoryStream;
  late final VerticalRepository _verticalRepository;
  late final Stream<List<VerticalModel>> _verticalStream;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController departmentController = TextEditingController(
    text: 'Sales',
  );

  bool isLoading = false;
  bool sendInviteNow = true;

  String selectedRole = UserRoles.sales;
  String selectedDepartment = 'Sales';
  String selectedDesignation = 'Sales Executive';
  String selectedAccessScope = AccessScope.company;

  AccessSelectionMode _verticalMode = AccessSelectionMode.multiple;
  AccessSelectionMode _factoryMode = AccessSelectionMode.multiple;
  final Set<String> _selectedVerticalIds = <String>{};
  final Set<String> _selectedFactoryIds = <String>{};

  bool get isExportImport => widget.industry == 'export_import';

  final List<String> _defaultRoles = [
    UserRoles.admin,
    UserRoles.manager,
    UserRoles.sales,
    UserRoles.service,
  ];
  final List<String> _defaultDepartments = [
    'Sales',
    'CRM',
    'Inventory',
    'Purchase',
    'Dispatch',
    'Finance',
    'Administration',
    'Management',
    'Service',
  ];

  final List<Map<String, dynamic>> _tenantDepartments = [];
  final List<Map<String, dynamic>> _tenantRoles = [];
  bool _isLoadingMetadata = false;
  String? _metadataError;
  Set<String>? _lastLoadedEnabledModuleIds;

  Set<String> get _currentEnabledModuleIds {
    final moduleAccess = ModuleAccessProvider.maybeOf(context);

    if (moduleAccess == null) {
      return <String>{};
    }

    return moduleAccess.enabledModuleIds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabledModuleIds = _currentEnabledModuleIds;
    final hadLoadedIds = _lastLoadedEnabledModuleIds;

    final hasChanged =
        hadLoadedIds == null ||
        hadLoadedIds.length != enabledModuleIds.length ||
        !hadLoadedIds.containsAll(enabledModuleIds);

    if (hasChanged) {
      _loadTenantMetadata();
    }
  }

  final List<String> _designationOptions = const [
    'CEO',
    'GM',
    'Factory Head',
    'Project Head',
    'Production Head',
    'Account Head',
    'Production Manager',
    'Quality Manager',
    'Quality Supervisor',
    'Dispatch Incharge',
    'HR Executive',
    'Project Manager',
    'Project Coordinator',
    'Safety Officer',
    'Safety Supervisor',
    'Store Incharge',
    'Maintenance Manager',
    'Maintenance Executive',
    'Accounts Executive',
    'Production Engineer',
    'Vice President - Business Development',
    'Area Sales Manager',
    'Sales Executive',
    'Senior Sales Executive',
    'Regional Sales Manager',
  ];

  Set<String> selectedPermissions = <String>{};
  Map<String, Set<String>> _permissionsByVertical = <String, Set<String>>{};
  late final ValueNotifier<int> _permissionCountNotifier;

  // 🔥 CHANGED: 'sales' is completely removed from the export_import array
  @override
  void initState() {
    super.initState();
    _permissionCountNotifier = ValueNotifier<int>(selectedPermissions.length);
    _factoryRepository = FactoryRepository(companyId: widget.companyId);
    _factoryStream = _factoryRepository.watchFactories();
    _verticalRepository = VerticalRepository(companyId: widget.companyId);
    _verticalStream = _verticalRepository.watchVerticals();
    _setDefaultDesignation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTenantMetadata();
      }
    });
  }

  @override
  void dispose() {
    _permissionCountNotifier.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    departmentController.dispose();
    super.dispose();
  }

  void _setDefaultDesignation() {
    selectedDesignation = _designationOptions.isNotEmpty
        ? _designationOptions.first
        : '';
  }

  String _departmentLabelFromDoc(Map<String, dynamic> department) {
    return (department['label'] ?? department['name'] ?? department['id'] ?? '')
        .toString()
        .trim();
  }

  String _roleKeyFromDoc(Map<String, dynamic> role) {
    return (role['role'] ?? role['name'] ?? role['id'] ?? role['roleId'])
        .toString()
        .trim();
  }

  String _roleLabelFromDoc(Map<String, dynamic> role) {
    if (role.containsKey('label')) {
      return role['label'].toString();
    }
    final key = _roleKeyFromDoc(role);
    return formatRole(key);
  }

  String _moduleIdFromRoleDoc(Map<String, dynamic> role) {
    return (role['moduleId'] ?? role['module'] ?? role['moduleKey'])
        .toString()
        .trim();
  }

  String _moduleIdFromDepartmentDoc(Map<String, dynamic> department) {
    return (department['moduleId'] ??
            department['module'] ??
            department['moduleKey'])
        .toString()
        .trim();
  }

  List<String> _designationOptionsForDepartment(String department) {
    return _designationOptions;
  }

  Map<String, dynamic>? _findRoleDoc(String roleKey) {
    try {
      return _tenantRoles.firstWhere(
        (role) => _roleKeyFromDoc(role) == roleKey,
      );
    } catch (_) {
      return null;
    }
  }

  String _roleLabelFromKey(String? roleKey) {
    if (roleKey == null || roleKey.trim().isEmpty) {
      return '';
    }

    final roleDoc = _findRoleDoc(roleKey);
    if (roleDoc != null) {
      return _roleLabelFromDoc(roleDoc);
    }

    return formatRole(roleKey);
  }

  Future<void> _loadTenantMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
      _metadataError = null;
    });

    try {
      final enabledModuleIds = _currentEnabledModuleIds;

      final rawRoles = await _userManagementService.fetchTenantRoles(
        companyId: widget.companyId,
      );
      final rawDepartments = await _userManagementService
          .fetchTenantDepartments(companyId: widget.companyId);

      final tenantRoles = rawRoles
          .where((role) {
            final isActive = role['isActive'] == true;
            if (!isActive) return false;
            final moduleId = _moduleIdFromRoleDoc(role);
            if (moduleId.isNotEmpty && !enabledModuleIds.contains(moduleId)) {
              return false;
            }
            return true;
          })
          .toList(growable: false);

      final tenantDepartments = rawDepartments
          .where((department) {
            final isActive = department['isActive'] == true;
            if (!isActive) return false;
            final moduleId = _moduleIdFromDepartmentDoc(department);
            if (moduleId.isNotEmpty && !enabledModuleIds.contains(moduleId)) {
              return false;
            }
            return true;
          })
          .toList(growable: false);

      tenantRoles.sort(
        (a, b) => _roleLabelFromDoc(a).compareTo(_roleLabelFromDoc(b)),
      );
      tenantDepartments.sort(
        (a, b) =>
            _departmentLabelFromDoc(a).compareTo(_departmentLabelFromDoc(b)),
      );

      setState(() {
        _lastLoadedEnabledModuleIds = enabledModuleIds;
        _tenantRoles
          ..clear()
          ..addAll(tenantRoles);
        _tenantDepartments
          ..clear()
          ..addAll(tenantDepartments);

        if (!_tenantRoles.any(
              (role) => _roleKeyFromDoc(role) == selectedRole,
            ) &&
            _tenantRoles.isNotEmpty) {
          selectedRole = _roleKeyFromDoc(_tenantRoles.first);
        }

        if (!_tenantDepartments.any(
              (department) =>
                  _departmentLabelFromDoc(department) == selectedDepartment,
            ) &&
            _tenantDepartments.isNotEmpty) {
          selectedDepartment = _departmentLabelFromDoc(
            _tenantDepartments.first,
          );
        }
      });

      _applyRoleDefaults(selectedRole);
    } catch (e) {
      if (mounted) {
        setState(() {
          _metadataError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMetadata = false;
        });
      }
    }
  }

  List<String> get availableRoles {
    if (_tenantRoles.isNotEmpty) {
      return _tenantRoles.map(_roleKeyFromDoc).toList(growable: false);
    }

    return _defaultRoles;
  }

  List<String> get availableDepartments {
    if (_tenantDepartments.isNotEmpty) {
      return _tenantDepartments
          .map(_departmentLabelFromDoc)
          .toList(growable: false);
    }

    return _defaultDepartments;
  }

  bool get _canCreateInvite {
    if (_isLoadingMetadata) return false;

    if (!availableRoles.contains(selectedRole)) {
      return false;
    }

    if (!availableDepartments.contains(selectedDepartment)) {
      return false;
    }

    return true;
  }

  Widget _buildTenantMetadataStatus() {
    if (_isLoadingMetadata) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      );
    }

    if (_metadataError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          'Unable to load tenant configuration: $_metadataError',
          style: const TextStyle(color: Color(0xFF991B1B)),
        ),
      );
    }

    final bool hasTenantSetup =
        _tenantRoles.isNotEmpty && _tenantDepartments.isNotEmpty;

    if (!hasTenantSetup) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'Using default QUIK ERP roles and departments because tenant settings are not configured yet.',
          style: TextStyle(
            color: Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  // 🔥 CHANGED: Sales module and inquiryReport completely removed from defaults
  void _applyRoleDefaults(String role) {
    final roleDoc = _findRoleDoc(role);
    if (roleDoc == null) return;
    final roleDepartment = (roleDoc['department'] ?? '').toString().trim();
    final roleDesignation = (roleDoc['designation'] ?? '').toString().trim();
    setState(() {
      if (roleDepartment.isNotEmpty) {
        selectedDepartment = roleDepartment;
        departmentController.text = roleDepartment;
      }
      if (roleDesignation.isNotEmpty &&
          _designationOptions.contains(roleDesignation)) {
        selectedDesignation = roleDesignation;
      }
    });
  }

  int _countEnabledActionsInModule({
    required String moduleKey,
    required Map<String, dynamic> modulePermissions,
  }) {
    int count = 0;

    if (moduleKey == PermissionModules.dashboard) {
      for (final value in modulePermissions.values) {
        if (value == true) count++;
      }
      return count;
    }

    for (final submoduleValue in modulePermissions.values) {
      if (submoduleValue is Map) {
        for (final actionValue in submoduleValue.values) {
          if (actionValue == true) count++;
        }
      }
    }

    return count;
  }

  int _countTotalActionsInModule({
    required String moduleKey,
    required Map<String, dynamic> modulePermissions,
  }) {
    int count = 0;

    if (moduleKey == PermissionModules.dashboard) {
      return modulePermissions.length;
    }

    for (final submoduleValue in modulePermissions.values) {
      if (submoduleValue is Map) {
        count += submoduleValue.length;
      }
    }

    return count;
  }

  Future<void> _createInvite() async {
    if (!_formKey.currentState!.validate()) return;

    final normalizedSelection = PermissionEvaluator.normalizeDependencies(
      selectedPermissions,
    );
    final verticalsWithoutPermissions = _selectedVerticalIds
        .where(
          (verticalId) =>
              (_permissionsByVertical[verticalId] ?? const <String>{}).isEmpty,
        )
        .toList(growable: false);
    if (_selectedVerticalIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one vertical before creating the invite.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (verticalsWithoutPermissions.isNotEmpty || normalizedSelection.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one permission for every selected vertical.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _userManagementService.createInvite(
        companyId: widget.companyId,
        email: _normalizeEmail(emailController.text),
        role: selectedRole,
        permissions: PermissionEvaluator.toStorageMap(normalizedSelection),
        allowedModuleIds: PermissionEvaluator.deriveAllowedModuleIds(
          normalizedSelection,
        ),
        invitedByUid: widget.currentUid,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        department: departmentController.text.trim(),
        designation: selectedDesignation,
        accessScope: selectedAccessScope,
        verticalSelectionMode: _verticalMode.storageValue,
        verticalIds: _selectedVerticalIds.toList()..sort(),
        factorySelectionMode: _factoryMode.storageValue,
        factoryIds: _selectedFactoryIds.toList()..sort(),
        verticalPermissions: VerticalPermissionAssignments.toStorageMap(
          assignments: _permissionsByVertical,
          selectedVerticalIds: _selectedVerticalIds,
        ),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Invite Created'),
          content: SelectableText(
            'Invite Code: ${result.inviteCode}\n\n'
            'Valid for 7 days.\n'
            'Role: ${formatRole(selectedRole)}\n'
            'Department: ${departmentController.text.trim()}\n'
            'Designation: $selectedDesignation\n'
            'Selected permissions: ${normalizedSelection.length}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      nameController.clear();
      emailController.clear();
      phoneController.clear();
      _setDefaultDesignation();

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: _inviteMutedTextColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _inviteCardBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _inviteCardBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _inviteAccentColor, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      labelStyle: const TextStyle(color: _inviteMutedTextColor),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
    IconData? icon,
    String Function(String)? labelBuilder,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      decoration: _inputDecoration(label: label, icon: icon),
      items: options
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(labelBuilder != null ? labelBuilder(e) : e),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildVerticalFactoryAccessSelector() {
    return VerticalFactoryAccessSelector(
      verticalStream: _verticalStream,
      factoryStream: _factoryStream,
      verticalMode: _verticalMode,
      selectedVerticalIds: _selectedVerticalIds,
      factoryMode: _factoryMode,
      selectedFactoryIds: _selectedFactoryIds,
      verticalDecoration: _inputDecoration(
        label: 'Vertical',
        icon: Icons.account_tree_outlined,
      ),
      factoryDecoration: _inputDecoration(
        label: 'Factory',
        icon: Icons.factory_outlined,
      ),
      onVerticalChanged: (mode, ids) {
        setState(() {
          final shouldSeedFromLegacy =
              _permissionsByVertical.isEmpty && selectedPermissions.isNotEmpty;
          for (final verticalId in ids) {
            _permissionsByVertical.putIfAbsent(
              verticalId,
              () => shouldSeedFromLegacy
                  ? Set<String>.from(selectedPermissions)
                  : <String>{},
            );
          }
          _verticalMode = mode;
          _selectedVerticalIds
            ..clear()
            ..addAll(ids);
          selectedPermissions = VerticalPermissionAssignments.unionForVerticals(
            assignments: _permissionsByVertical,
            selectedVerticalIds: _selectedVerticalIds,
          );
          _permissionCountNotifier.value = selectedPermissions.length;
        });
      },
      onFactoryChanged: (mode, ids) {
        setState(() {
          _factoryMode = mode;
          _selectedFactoryIds
            ..clear()
            ..addAll(ids);
        });
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _inviteCardBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _inviteHeadingTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _inviteMutedTextColor,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPermissionModuleCard({
    required String moduleKey,
    required bool isExportImport,
    required Map<String, dynamic> modulePermissions,
    required void Function(
      String moduleKey,
      String? submoduleKey,
      String action,
      bool value,
    )
    onActionChanged,
  }) {
    final moduleLabel = formatModuleLabel(moduleKey);
    final selectedCount = _countEnabledActionsInModule(
      moduleKey: moduleKey,
      modulePermissions: modulePermissions,
    );
    final totalCount = _countTotalActionsInModule(
      moduleKey: moduleKey,
      modulePermissions: modulePermissions,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  moduleLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _inviteHeadingTextColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selectedCount == 0
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$selectedCount / $totalCount selected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selectedCount == 0
                        ? const Color(0xFF475569)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          children: moduleKey == PermissionModules.dashboard
              ? [
                  _buildActionGroup(
                    title: 'Dashboard',
                    actions: Map<String, bool>.from(modulePermissions),
                    onChanged: (action, value) =>
                        onActionChanged(moduleKey, null, action, value),
                  ),
                ]
              : (permissionSubmoduleMap[moduleKey] ?? const <String>[])
                    .where((submoduleKey) {
                      // 🔥 CHANGED: Deep strict filtering for export_import
                      if (isExportImport) {
                        if (moduleKey == 'sales') {
                          return false; // Strictly blocked
                        }
                        if (moduleKey == 'crm') {
                          return submoduleKey == 'customers';
                        }
                        if (moduleKey == 'finance') {
                          return [
                            'taxInvoice',
                            'paymentReceived',
                            'outstanding',
                            'expenseEntries',
                          ].contains(submoduleKey);
                        }
                        if (moduleKey == 'reports') {
                          return [
                            'salesReport',
                            'customerReport', // inquiryReport explicitly blocked
                            'paymentReport',
                          ].contains(submoduleKey);
                        }
                        return false;
                      }
                      return true;
                    })
                    .map((submoduleKey) {
                      final submodulePermissions = Map<String, bool>.from(
                        modulePermissions[submoduleKey] ?? {},
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: _buildActionGroup(
                          title: formatSubmoduleLabel(submoduleKey),
                          actions: submodulePermissions,
                          onChanged: (action, value) => onActionChanged(
                            moduleKey,
                            submoduleKey,
                            action,
                            value,
                          ),
                        ),
                      );
                    })
                    .toList(),
        ),
      ),
    );
  }

  Widget _buildActionGroup({
    required String title,
    required Map<String, bool> actions,
    required void Function(String action, bool value) onChanged,
  }) {
    final selectedCount = actions.values.where((e) => e).length;
    final totalCount = actions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _inviteHeadingTextColor,
                ),
              ),
            ),
            Text(
              '$selectedCount / $totalCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _inviteMutedTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.entries.map((entry) {
            return _PermissionChip(
              label: formatPermissionActionLabel(entry.key),
              value: entry.value,
              onChanged: (value) => onChanged(entry.key, value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInviteSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: _invitePrimaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _inviteHeadingTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${formatRole(selectedRole)} • Department: $selectedDepartment',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _inviteMutedTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Designation: ${selectedDesignation.isEmpty ? 'Not Assigned' : selectedDesignation}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _inviteMutedTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Access Scope: ${accessScopeLabels[selectedAccessScope] ?? selectedAccessScope}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _inviteMutedTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<int>(
                  valueListenable: _permissionCountNotifier,
                  builder: (context, count, _) => Text(
                    'Selected permissions: $count',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _inviteMutedTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sendInviteNow
                      ? 'Invite will be created and ready to share immediately.'
                      : 'Invite will be created without immediate sending flow.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _inviteMutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTwoColumn({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  List<String> get _designationOptionsForSelectedDepartment {
    return _designationOptionsForDepartment(selectedDepartment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _inviteScaffoldBgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _inviteHeadingTextColor,
        titleSpacing: 0,
        title: const Text(
          'Create Employee Invite',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _inviteHeadingTextColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Administration \u2022 Users \u2022 Invite User',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _inviteMutedTextColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Invite a new employee with structured access and module-based permissions.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _inviteMutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _inviteHeadingTextColor,
                            side: const BorderSide(
                              color: _inviteCardBorderColor,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Basic Details',
                      subtitle:
                          'Enter employee identity details for the invitation.',
                      child: Column(
                        children: [
                          _buildDesktopTwoColumn(
                            left: _buildTextField(
                              controller: nameController,
                              label: 'Employee Name',
                              hint: 'Enter full name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Employee name is required';
                                }
                                return null;
                              },
                            ),
                            right: _buildTextField(
                              controller: emailController,
                              label: 'Email Address',
                              hint: 'Enter business email',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) {
                                  return 'Email is required';
                                }
                                final emailRegex = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDesktopTwoColumn(
                            left: _buildTextField(
                              controller: phoneController,
                              label: 'Phone Number',
                              hint: 'Enter phone number',
                              icon: Icons.call_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            right: const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildTenantMetadataStatus(),
                    _buildSectionCard(
                      title: 'Department & Role',
                      subtitle:
                          'Assign the employee to a department and choose the access role.',
                      trailing: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => _applyRoleDefaults(selectedRole),
                        child: const Text('Apply Role Defaults'),
                      ),
                      child: Column(
                        children: [
                          _buildVerticalFactoryAccessSelector(),
                          const SizedBox(height: 16),
                          _buildDesktopTwoColumn(
                            left: _buildDropdownField(
                              label: 'Role',
                              value: selectedRole,
                              options: availableRoles,
                              icon: Icons.admin_panel_settings_outlined,
                              labelBuilder: _roleLabelFromKey,
                              onChanged: (value) => setState(() {
                                selectedRole = value ?? selectedRole;
                              }),
                            ),
                            right: _buildDropdownField(
                              label: 'Designation',
                              value: selectedDesignation,
                              options: _designationOptionsForSelectedDepartment,
                              icon: Icons.badge_outlined,
                              onChanged: (value) {
                                setState(() {
                                  selectedDesignation = value ?? '';
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDesktopTwoColumn(
                            left: _buildTextField(
                              controller: departmentController,
                              label: 'Department',
                              icon: Icons.apartment_outlined,
                            ),
                            right: const SizedBox(),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile.adaptive(
                            value: sendInviteNow,
                            onChanged: (value) {
                              setState(() {
                                sendInviteNow = value;
                              });
                            },
                            title: const Text(
                              'Send Invite Now',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _inviteHeadingTextColor,
                              ),
                            ),
                            subtitle: const Text(
                              'Keep this enabled to create a ready-to-share invite immediately.',
                              style: TextStyle(color: _inviteMutedTextColor),
                            ),
                            activeThumbColor: _inviteAccentColor,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 10),
                          _buildInviteSummary(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSectionCard(
                      title: 'Module Permissions',
                      subtitle:
                          'Permissions are aligned with your QUIK ERP modules and submodules.',
                      child: VerticalPermissionEditor(
                        verticalStream: _verticalStream,
                        selectedVerticalIds: _selectedVerticalIds,
                        permissionsByVertical: _permissionsByVertical,
                        fallbackPermissions: selectedPermissions,
                        visibleModuleIds: AmanPermissionCatalogue.modules
                            .where(
                              (module) =>
                                  module.id == ModuleIds.dashboard ||
                                  module.id == ModuleIds.settings ||
                                  _currentEnabledModuleIds.isEmpty ||
                                  _currentEnabledModuleIds.contains(module.id),
                            )
                            .map((module) => module.id)
                            .toSet(),
                        onChanged: (value) {
                          _permissionsByVertical = value;
                          selectedPermissions =
                              VerticalPermissionAssignments.unionForVerticals(
                                assignments: _permissionsByVertical,
                                selectedVerticalIds: _selectedVerticalIds,
                              );
                          _permissionCountNotifier.value =
                              selectedPermissions.length;
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _inviteCardBorderColor),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D0F172A),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 700) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _inviteHeadingTextColor,
                                      side: const BorderSide(
                                        color: _inviteCardBorderColor,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLoading || !_canCreateInvite
                                        ? null
                                        : _createInvite,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _invitePrimaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.4,
                                            ),
                                          )
                                        : const Text(
                                            'Create Invite',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              OutlinedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _inviteHeadingTextColor,
                                  side: const BorderSide(
                                    color: _inviteCardBorderColor,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: isLoading || !_canCreateInvite
                                    ? null
                                    : _createInvite,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _invitePrimaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : const Text(
                                        'Create Invite',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFE0ECFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? _inviteAccentColor : const Color(0xFFD6DEE8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 18,
              color: value ? _inviteAccentColor : _inviteMutedTextColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: value
                    ? const Color(0xFF1E3A8A)
                    : _inviteHeadingTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
