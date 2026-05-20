import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:QUIK/auth/login/login_screen.dart';
import 'package:QUIK/core/app/aman_app_config.dart';
import 'package:QUIK/core/inventory/providers/inventory_config_provider.dart';
import 'package:QUIK/core/inventory/services/inventory_config_service.dart';
import 'package:QUIK/core/modules/providers/module_access_provider.dart';
import 'package:QUIK/core/modules/services/tenant_module_service.dart';
import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/shell/quik_shell.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;

        if (user == null) {
          return LoginScreen();
        }

        return _UserProfileGate(firebaseUser: user);
      },
    );
  }
}

class _UserProfileGate extends StatefulWidget {
  final User firebaseUser;

  const _UserProfileGate({required this.firebaseUser});

  @override
  State<_UserProfileGate> createState() => _UserProfileGateState();
}

class _UserProfileGateState extends State<_UserProfileGate> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  String? _lastAppliedTenantId;
  bool _tenantContextUpdated = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfileWithRetry();
  }

  Future<void> _loadUserProfileWithRetry() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final uid = widget.firebaseUser.uid;

      for (int i = 0; i < 8; i++) {
        final doc = await firestore.collection('users').doc(uid).get();

        if (doc.exists && doc.data() != null) {
          final userData = _amanScopedUserData(doc.data()!);

          if (!mounted) return;

          setState(() {
            _data = userData;
            _loading = false;
            _error = null;
          });

          return;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'User profile not found in database.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Failed to load user profile: $e';
      });
    }
  }

  Map<String, dynamic> _amanScopedUserData(Map<String, dynamic> userData) {
    final email = (widget.firebaseUser.email ?? '').trim().toLowerCase();
    final roleOverride = _adminRoleForEmail(email);
    final companyId = (userData['companyId'] ?? '').toString();

    return <String, dynamic>{
      ...userData,
      'tenantId': companyId,
      'companyId': companyId,
      'companyName': userData['companyName'] ?? AmanAppConfig.companyName,
      if (roleOverride != null) 'role': roleOverride,
      if (roleOverride != null) 'isActive': true,
    };
  }

  String? _adminRoleForEmail(String email) {
    return null;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _logout, child: const Text('Logout')),
              ],
            ),
          ),
        ),
      );
    }

    final data = _data!;

    final isActive = data['isActive'] ?? true;
    if (isActive != true) {
      Future.microtask(() async {
        await FirebaseAuth.instance.signOut();
      });

      return const Scaffold(
        body: Center(
          child: Text('Your account is inactive. Please contact admin.'),
        ),
      );
    }

    final companyId = (data['companyId'] ?? '').toString().trim();

    if (companyId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Company ID missing in user profile.')),
      );
    }

    final allowedTenantIds = [companyId];
    final role = (data['role'] ?? 'sales').toString();
    final companyName = (data['companyName'] ?? AmanAppConfig.companyName)
        .toString();
    final permissions = Map<String, dynamic>.from(data['permissions'] ?? {});

    final userDisplayName =
        (data['fullName'] ??
                data['name'] ??
                data['employeeName'] ??
                data['displayName'] ??
                '')
            .toString();

    if (!_tenantContextUpdated || _lastAppliedTenantId != companyId) {
      _tenantContextUpdated = true;
      _lastAppliedTenantId = companyId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final tenantContext = context.read<TenantContext>();
        tenantContext.replaceAllowedTenants(allowedTenantIds);
        tenantContext.setTenantNames({companyId: companyName});
        tenantContext.selectTenant(companyId);
      });
    }

    return _TenantModuleBackfillGate(
      companyId: companyId,
      child: ModuleAccessProvider(
        tenantId: companyId,
        controller: context.read<ModuleAccessController>(),
        child: InventoryConfigProvider(
          tenantId: companyId,
          child: Builder(
            builder: (moduleContext) {
              return QuikShell(
                userEmail: widget.firebaseUser.email ?? '',
                userUid: widget.firebaseUser.uid,
                companyId: companyId,
                companyName: companyName,
                role: role,
                permissions: permissions,
                userDisplayName: userDisplayName,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TenantModuleBackfillGate extends StatefulWidget {
  final String companyId;
  final Widget child;

  const _TenantModuleBackfillGate({
    required this.companyId,
    required this.child,
  });

  @override
  State<_TenantModuleBackfillGate> createState() =>
      _TenantModuleBackfillGateState();
}

class _TenantModuleBackfillGateState extends State<_TenantModuleBackfillGate> {
  final TenantModuleService _tenantModuleService = TenantModuleService();
  final InventoryConfigService _inventoryConfigService =
      InventoryConfigService();

  String? _initializedCompanyId;

  @override
  void initState() {
    super.initState();
    _ensureBackfilled();
  }

  @override
  void didUpdateWidget(covariant _TenantModuleBackfillGate oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.companyId != widget.companyId) {
      _ensureBackfilled();
    }
  }

  Future<void> _ensureBackfilled() async {
    final companyId = widget.companyId.trim();

    if (companyId.isEmpty || _initializedCompanyId == companyId) {
      if (mounted) {}
      return;
    }

    try {
      await _tenantModuleService.ensureTenantModulesInitialized(
        tenantId: companyId,
        source: 'auth_backfill',
      );

      await _inventoryConfigService.ensureDefaultProfileFromCompany(
        tenantId: companyId,
        source: 'auth_backfill',
      );
    } catch (e) {
      debugPrint(
        'TenantModuleBackfillGate: tenant startup backfill failed for $companyId: $e',
      );
    }

    if (!mounted || widget.companyId.trim() != companyId) return;

    setState(() {
      _initializedCompanyId = companyId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
