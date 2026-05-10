import 'package:flutter/widgets.dart';

import 'package:QUIK/core/modules/module_registry.dart';
import 'package:QUIK/core/modules/services/tenant_module_service.dart';

class ModuleAccessController extends ChangeNotifier {
  ModuleAccessController({
    TenantModuleService? service,
    this.fallbackToActiveRegistryWhenUnconfigured = false,
    this.fallbackToActiveRegistryOnError = false,
  }) : _service = service ?? TenantModuleService();

  final TenantModuleService _service;
  final bool fallbackToActiveRegistryWhenUnconfigured;
  final bool fallbackToActiveRegistryOnError;

  bool _isLoading = false;
  String? _tenantId;
  String? _error;
  Set<String> _enabledModuleIds = const {};

  bool get isLoading => _isLoading;
  String? get tenantId => _tenantId;
  String? get error => _error;
  Set<String> get enabledModuleIds => Set.unmodifiable(_enabledModuleIds);

  bool isModuleEnabled(String moduleId) {
    final normalizedModuleId = moduleId.trim();
    if (normalizedModuleId.isEmpty) return false;
    return _enabledModuleIds.contains(normalizedModuleId);
  }

  Future<void> loadForTenant(
    String tenantId, {
    bool forceRefresh = false,
  }) async {
    final normalizedTenantId = tenantId.trim();

    if (normalizedTenantId.isEmpty) {
      _tenantId = null;
      _enabledModuleIds = const {};
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _tenantId == normalizedTenantId &&
        _error == null &&
        _enabledModuleIds.isNotEmpty) {
      return;
    }

    _tenantId = normalizedTenantId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final seedResult = await _service.ensureTenantModulesInitialized(
        tenantId: normalizedTenantId,
        source: 'module_access_provider',
      );

      final enabledIds = await _service.fetchEnabledModuleIds(
        normalizedTenantId,
        forceRefresh: forceRefresh ||
            seedResult.modulesCreated > 0 ||
            seedResult.modulesRepaired > 0,
        fallbackToActiveRegistryWhenUnconfigured:
            fallbackToActiveRegistryWhenUnconfigured,
      );

      _enabledModuleIds = enabledIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      debugPrint(
        'ModuleAccessProvider: tenant=$normalizedTenantId enabled=$_enabledModuleIds',
      );
    } catch (e, stackTrace) {
      _error = e.toString();

      debugPrint(
        'ModuleAccessProvider: failed to load modules for $normalizedTenantId: $e',
      );
      debugPrintStack(stackTrace: stackTrace);

      _enabledModuleIds = fallbackToActiveRegistryOnError
          ? ModuleRegistry.activeModules.map((module) => module.id).toSet()
          : const {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final currentTenantId = _tenantId;
    if (currentTenantId == null || currentTenantId.trim().isEmpty) return;
    await loadForTenant(currentTenantId, forceRefresh: true);
  }
}

class ModuleAccessProvider extends StatefulWidget {
  final String tenantId;
  final Widget child;
  final ModuleAccessController? controller;

  const ModuleAccessProvider({
    super.key,
    required this.tenantId,
    required this.child,
    this.controller,
  });

  static ModuleAccessController? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    final provider = listen
        ? context.dependOnInheritedWidgetOfExactType<_ModuleAccessScope>()
        : context.getInheritedWidgetOfExactType<_ModuleAccessScope>();

    return provider?.notifier;
  }

  static ModuleAccessController of(
    BuildContext context, {
    bool listen = true,
  }) {
    final controller = maybeOf(context, listen: listen);

    assert(
      controller != null,
      'ModuleAccessProvider.of() called with no ModuleAccessProvider in context.',
    );

    if (controller == null) {
      throw FlutterError.fromParts([
        ErrorSummary(
          'ModuleAccessProvider.of() called with no ModuleAccessProvider in context.',
        ),
        ErrorDescription(
          'Wrap the page, shell, route, or dialog with ModuleAccessProvider before calling ModuleAccessProvider.of(context).',
        ),
      ]);
    }

    return controller;
  }

  @override
  State<ModuleAccessProvider> createState() => _ModuleAccessProviderState();
}

class _ModuleAccessProviderState extends State<ModuleAccessProvider> {
  late ModuleAccessController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _setController(widget.controller);
    _loadTenantAfterBuild(forceRefresh: true);
  }

  @override
  void didUpdateWidget(covariant ModuleAccessProvider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }

      _setController(widget.controller);
      _loadTenantAfterBuild(forceRefresh: true);
      return;
    }

    if (oldWidget.tenantId != widget.tenantId) {
      _loadTenantAfterBuild(forceRefresh: true);
    }
  }

  void _setController(ModuleAccessController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? ModuleAccessController();
  }

  void _loadTenantAfterBuild({required bool forceRefresh}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.loadForTenant(
        widget.tenantId,
        forceRefresh: forceRefresh,
      );
    });
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ModuleAccessScope(
      notifier: _controller,
      child: widget.child,
    );
  }
}

class _ModuleAccessScope extends InheritedNotifier<ModuleAccessController> {
  const _ModuleAccessScope({
    required super.notifier,
    required super.child,
  });
}