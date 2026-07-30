// FILE PATH: lib/modules/settings/screen_settings_home.dart
import 'package:QUIK/modules/settings/coating_master/coating_master_screen.dart';
import 'package:QUIK/modules/settings/company_profile/company_profile_bank_screen.dart';
import 'package:QUIK/modules/settings/document_layout/document_layout_designer_screen.dart';
import 'package:QUIK/modules/settings/factory_master/factory_list_screen.dart';
import 'package:QUIK/modules/settings/inventory_masters/screen_inventory_masters.dart';
import 'package:QUIK/modules/settings/vertical_master/vertical_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

enum _SettingsSection { personal, workspace, access, system, coating, danger }

class ScreenSettingsHome extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String role;
  final String userEmail;
  final Map<String, dynamic> permissions;
  final String? industry;
  final VoidCallback? onOpenUsers;
  final VoidCallback? onOpenCompanyProfile;
  final VoidCallback? onOpenAuditLogs;

  const ScreenSettingsHome({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.role,
    required this.userEmail,
    this.permissions = const {},
    this.industry,
    this.onOpenUsers,
    this.onOpenCompanyProfile,
    this.onOpenAuditLogs,
  });

  @override
  State<ScreenSettingsHome> createState() => _ScreenSettingsHomeState();
}

class _ScreenSettingsHomeState extends State<ScreenSettingsHome> {
  _SettingsSection _activeSection = _SettingsSection.personal;

  bool get isAdmin {
    final role = widget.role.toLowerCase();
    return role == 'admin' ||
        role == 'company_super_admin' ||
        role == 'super_admin';
  }

  bool get isManager => widget.role.toLowerCase() == 'manager';

  bool get isAdminOrManager => isAdmin || isManager;
  bool get isExportImport => widget.industry == 'export_import';

  bool _hasPermission(String key) {
    if (isAdminOrManager) return true;
    return widget.permissions[key] == true;
  }

  // Users module should ALWAYS be visible based on permissions
  bool get canOpenUsers => isAdminOrManager || _hasPermission('userManagement');

  // Hide these explicitly for Export-Import
  bool get canOpenCompanyProfile =>
      !isExportImport && (isAdminOrManager || _hasPermission('companyProfile'));
  bool get canOpenAuditLogs =>
      !isExportImport && (isAdminOrManager || _hasPermission('auditLogs'));
  bool get canOpenRoles =>
      !isExportImport && (isAdminOrManager || _hasPermission('roles'));

  List<_NavItemData> get _navItems {
    return [
      const _NavItemData(
        section: _SettingsSection.personal,
        title: 'My Account',
        icon: Icons.person_outline,
      ),
      if (!isExportImport && (canOpenCompanyProfile || isAdminOrManager))
        const _NavItemData(
          section: _SettingsSection.workspace,
          title: 'Workspace',
          icon: Icons.apartment_outlined,
        ),
      if (canOpenUsers || canOpenRoles)
        const _NavItemData(
          section: _SettingsSection.access,
          title: 'Users & Access',
          icon: Icons.admin_panel_settings_outlined,
        ),
      if (!isExportImport && (canOpenAuditLogs || isAdminOrManager))
        const _NavItemData(
          section: _SettingsSection.system,
          title: 'System',
          icon: Icons.settings_suggest_outlined,
        ),
      if (!isExportImport && isAdminOrManager)
        const _NavItemData(
          section: _SettingsSection.coating,
          title: 'Coating Master',
          icon: Icons.layers_outlined,
        ),
      const _NavItemData(
        section: _SettingsSection.danger,
        title: 'Danger Zone',
        icon: Icons.warning_amber_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(compact),
            const SizedBox(height: 12),
            _buildTopSummaryRow(),
            const SizedBox(height: 12),
            Expanded(
              child: compact
                  ? Column(
                children: [
                  SizedBox(
                    height: 58,
                    child: _buildLeftNav(horizontal: true),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildRightPanel()),
                ],
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 250, child: _buildLeftNav()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRightPanel()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool compact) {
    final breadcrumb = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.apartment_outlined, size: 18, color: zMuted),
        const SizedBox(width: 8),
        const Flexible(
          child: Text(
            'Workspace',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: zMuted, fontWeight: FontWeight.w700),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right_rounded, size: 18, color: zMuted),
        ),
        const Text(
          'Settings',
          style: TextStyle(color: zText, fontWeight: FontWeight.w900),
        ),
      ],
    );
    final selector = Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business_outlined, size: 18, color: zBlue),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.companyName.trim().isEmpty
                  ? widget.companyId
                  : widget.companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: zText, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline_rounded, size: 14, color: zMuted),
        ],
      ),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          breadcrumb,
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: selector),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: breadcrumb),
        selector,
      ],
    );
  }

  Widget _buildTopSummaryRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Workspace',
                value: widget.companyName,
                icon: Icons.business_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Company ID',
                value: widget.companyId,
                icon: Icons.badge_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Role',
                value: _readableRole(widget.role),
                icon: Icons.shield_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Account',
                value: widget.userEmail,
                icon: Icons.person_outline,
              ),
            ),
          ],
        );
      },
    );
  }

  String _readableRole(String value) => value
      .trim()
      .toLowerCase()
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  Widget _buildLeftNav({bool horizontal = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView(
        scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
        children: _navItems.map((item) {
          final selected = _activeSection == item.section;

          return Padding(
            padding: EdgeInsets.only(
              bottom: horizontal ? 0 : 6,
              right: horizontal ? 6 : 0,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _activeSection = item.section),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFFF3E8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFFF8A34).withValues(alpha: 0.35)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 18,
                      color: selected ? const Color(0xFFEA6A00) : zMuted,
                    ),
                    const SizedBox(width: 10),
                    if (horizontal)
                      Text(
                        item.title,
                        style: TextStyle(
                          color: selected ? const Color(0xFFB94F00) : zText,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: selected ? const Color(0xFFB94F00) : zText,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRightPanel() {
    switch (_activeSection) {
      case _SettingsSection.personal:
        return _buildPersonalSection();
      case _SettingsSection.workspace:
        return _buildWorkspaceSection();
      case _SettingsSection.access:
        return _buildAccessSection();
      case _SettingsSection.system:
        return _buildSystemSection();
      case _SettingsSection.coating:
        return CoatingMasterScreen(tenantId: widget.companyId);
      case _SettingsSection.danger:
        return _buildDangerSection();
    }
  }

  Widget _buildPersonalSection() {
    return _SectionPanel(
      title: 'My Account',
      subtitle: 'Personal profile, password, and account preferences.',
      children: [
        _ActionTile(
          title: 'My Profile',
          subtitle:
          'View and update your profile and workspace registration details.',
          icon: Icons.person_outline,
          onTap: _showProfileDetails,
        ),
        _ActionTile(
          title: 'Change Password',
          subtitle: 'Securely update your login password.',
          icon: Icons.lock_reset_outlined,
          onTap: () => _showChangePasswordDialog(context),
        ),
        _ActionTile(
          title: 'Notification Center',
          subtitle:
          'Notification preferences are not configured yet. Coming soon.',
          icon: Icons.notifications_active_outlined,
          onTap: () => _showComingSoon('Notification Center'),
        ),
      ],
    );
  }

  Widget _buildWorkspaceSection() {
    return _SectionPanel(
      title: 'Workspace',
      subtitle: 'Company-level settings and workspace information.',
      children: [
        if (canOpenCompanyProfile)
          _ActionTile(
            title: 'Company Profile & Banking',
            subtitle:
            'Manage company identity, GST, PAN, address, billing information, and multiple bank accounts.',
            icon: Icons.apartment_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CompanyProfileBankScreen(
                  companyId: widget.companyId,
                  canEdit: isAdminOrManager,
                ),
              ),
            ),
          ),
        if (!isExportImport) ...[
          _ActionTile(
            title: 'Factories',
            subtitle:
            'Manage factories, plants, addresses, and GST registration details.',
            icon: Icons.factory_outlined,
            enabled: isAdminOrManager,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FactoryListScreen(
                  companyId: widget.companyId,
                  canAdd: isAdmin,
                ),
              ),
            ),
          ),
          _ActionTile(
            title: 'Verticals',
            subtitle: 'Manage business verticals and their linked factories.',
            icon: Icons.view_agenda_outlined,
            enabled: isAdminOrManager,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VerticalListScreen(
                  companyId: widget.companyId,
                  canAdd: isAdmin,
                ),
              ),
            ),
          ),
          _ActionTile(
            title: 'Inventory Masters',
            subtitle:
            'Configure item categories, subcategories, UOMs and measurement profiles.',
            icon: Icons.tune_outlined,
            enabled: isAdminOrManager,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => InventoryMastersScreen(
                  companyId: widget.companyId,
                  canEdit: isAdminOrManager,
                ),
              ),
            ),
          ),
          _ActionTile(
            title: 'Letter Head Layout',
            subtitle:
            'Configure the letterhead background, printable area, margins, header, and footer.',
            icon: Icons.description_outlined,
            enabled: isAdminOrManager,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DocumentLayoutDesignerScreen(
                  companyId: widget.companyId,
                  canEdit: isAdminOrManager,
                ),
              ),
            ),
          ),
          _ActionTile(
            title: 'Document Numbering',
            subtitle:
            'Control quotation, invoice, and order numbering formats.',
            icon: Icons.numbers_outlined,
            enabled: isAdminOrManager,
            onTap: () => _showComingSoon('Document Numbering'),
          ),
        ],
      ],
    );
  }

  // ignore: unused_element
  Widget _buildCompanyProfileCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final name = (data['companyName'] ?? widget.companyName)
            .toString()
            .trim();
        final gstin = (data['gstin'] ?? '').toString().trim();
        final location = [data['city'], data['state']]
            .map((value) => (value ?? '').toString().trim())
            .where((value) => value.isNotEmpty)
            .join(', ');
        final details = [
          if (name.isNotEmpty) name,
          if (gstin.isNotEmpty) 'GSTIN $gstin',
          if (location.isNotEmpty) location,
        ].join(' â€¢ ');
        return _ActionTile(
          title: 'Company Profile',
          subtitle: snapshot.hasError
              ? 'Company details could not be loaded.'
              : (details.isEmpty
              ? 'Optional company details are not configured.'
              : details),
          icon: Icons.apartment_outlined,
          onTap: snapshot.hasData
              ? () => _showCompanyProfileDialog(data)
              : null,
        );
      },
    );
  }

  void _showProfileDetails() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileValue(label: 'Account', value: widget.userEmail),
              _ProfileValue(label: 'Role', value: _readableRole(widget.role)),
              _ProfileValue(label: 'Workspace', value: widget.companyName),
              const SizedBox(height: 8),
              const Text(
                'Profile identity changes remain administrator-managed under Aman permissions.',
                style: TextStyle(color: zMuted, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCompanyProfileDialog(Map<String, dynamic> existing) async {
    const fields = <(String, String)>[
      ('companyName', 'Legal / Company Name'),
      ('gstin', 'GSTIN'),
      ('pan', 'PAN'),
      ('address', 'Registered Address'),
      ('city', 'City'),
      ('state', 'State'),
      ('pincode', 'Pincode'),
      ('email', 'Company Email'),
      ('phone', 'Phone'),
      ('website', 'Website'),
    ];
    final controllers = <String, TextEditingController>{
      for (final field in fields)
        field.$1: TextEditingController(
          text: (existing[field.$1] ?? '').toString(),
        ),
    };
    var saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text(
            'Workspace Profile',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final field in fields) ...[
                    TextField(
                      controller: controllers[field.$1],
                      decoration: InputDecoration(labelText: field.$2),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (error != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                final updates = <String, dynamic>{};
                for (final field in fields) {
                  final next = controllers[field.$1]!.text.trim();
                  final previous = (existing[field.$1] ?? '')
                      .toString()
                      .trim();
                  if (next.isNotEmpty && next != previous) {
                    updates[field.$1] = next;
                  }
                }
                if (updates.isEmpty) {
                  Navigator.pop(dialogContext);
                  return;
                }
                setLocalState(() {
                  saving = true;
                  error = null;
                });
                try {
                  updates['updatedAt'] = FieldValue.serverTimestamp();
                  updates['updatedBy'] =
                      FirebaseAuth.instance.currentUser?.uid;
                  await FirebaseFirestore.instance
                      .collection('companies')
                      .doc(widget.companyId)
                      .update(updates);
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Workspace profile updated successfully.',
                      ),
                    ),
                  );
                } on FirebaseException catch (exception) {
                  setLocalState(() {
                    saving = false;
                    error =
                        exception.message ??
                            'Workspace profile update failed.';
                  });
                } catch (_) {
                  setLocalState(() {
                    saving = false;
                    error = 'Workspace profile update failed.';
                  });
                }
              },
              child: saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Widget _buildAccessSection() {
    return _SectionPanel(
      title: 'Users & Access',
      subtitle: 'User management, permissions, and access control.',
      children: [
        if (canOpenUsers)
          _ActionTile(
            title: 'Users',
            subtitle: 'Manage active users, invitations, and team access.',
            icon: Icons.manage_accounts_outlined,
            onTap: widget.onOpenUsers,
          ),
        if (canOpenRoles)
          _ActionTile(
            title: 'Roles & Permissions',
            subtitle: 'Define role rights and module permissions.',
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => _showComingSoon('Roles & Permissions'),
          ),
        if (!isExportImport)
          _ActionTile(
            title: 'Access Scope',
            subtitle: 'Control future branch, department, and scope access.',
            icon: Icons.lock_open_outlined,
            enabled: isAdminOrManager,
            onTap: () => _showComingSoon('Access Scope'),
          ),
      ],
    );
  }

  Widget _buildSystemSection() {
    return _SectionPanel(
      title: 'System',
      subtitle: 'Logs, integrations, and workspace-level system controls.',
      children: [
        if (canOpenAuditLogs)
          _ActionTile(
            title: 'Audit Logs',
            subtitle: 'Review important actions and change history.',
            icon: Icons.fact_check_outlined,
            enabled: canOpenAuditLogs,
            onTap: widget.onOpenAuditLogs,
          ),
        _ActionTile(
          title: 'Coating Master',
          subtitle:
          'Manage HDG, Galvalume, AZ150, AZ350, ZM350 coating percentages.',
          icon: Icons.layers_outlined,
          enabled: isAdminOrManager,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CoatingMasterScreen(tenantId: widget.companyId),
            ),
          ),
        ),
        if (!isExportImport) ...[
          _ActionTile(
            title: 'Integrations',
            subtitle: 'Connect external systems and future APIs.',
            icon: Icons.hub_outlined,
            enabled: isAdminOrManager,
            onTap: () => _showComingSoon('Integrations'),
          ),
          _ActionTile(
            title: 'Security Policies',
            subtitle:
            'Future controls for session rules and account protection.',
            icon: Icons.security_outlined,
            enabled: isAdminOrManager,
            onTap: () => _showComingSoon('Security Policies'),
          ),
        ],
      ],
    );
  }

  Widget _buildDangerSection() {
    return _SectionPanel(
      title: 'Danger Zone',
      subtitle: 'Sensitive account actions. Use with caution.',
      children: [
        _ActionTile(
          title: 'Delete Account',
          subtitle:
          'Permanently delete your login and remove your root user profile.',
          icon: Icons.delete_forever_outlined,
          isDanger: true,
          onTap: () => _showDeleteDialog(context),
        ),
      ],
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title will be added next')));
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool saving = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> submit() async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                setLocalState(() {
                  errorText = 'All fields are required.';
                });
                return;
              }

              if (newPassword.length < 6) {
                setLocalState(() {
                  errorText = 'New password must be at least 6 characters.';
                });
                return;
              }

              if (newPassword != confirmPassword) {
                setLocalState(() {
                  errorText = 'New password and confirm password do not match.';
                });
                return;
              }

              try {
                setLocalState(() {
                  saving = true;
                  errorText = null;
                });

                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.email == null) {
                  throw FirebaseAuthException(
                    code: 'user-not-found',
                    message: 'No authenticated user found.',
                  );
                }

                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPassword,
                );

                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);

                if (!mounted) return;
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully.'),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                setLocalState(() {
                  saving = false;
                  errorText = _friendlyAuthError(e);
                });
              } catch (e) {
                setLocalState(() {
                  saving = false;
                  errorText = 'Failed to update password: $e';
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final passwordController = TextEditingController();

    bool deleting = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: !deleting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> submitDelete() async {
              final password = passwordController.text.trim();

              if (password.isEmpty) {
                setLocalState(() {
                  errorText = 'Password is required.';
                });
                return;
              }

              try {
                setLocalState(() {
                  deleting = true;
                  errorText = null;
                });

                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.email == null) {
                  throw FirebaseAuthException(
                    code: 'user-not-found',
                    message: 'No authenticated user found.',
                  );
                }

                final uid = user.uid;

                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: password,
                );

                await user.reauthenticateWithCredential(credential);

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .delete()
                    .catchError((_) {});

                await user.delete();

                if (!mounted) return;
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted successfully.'),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                setLocalState(() {
                  deleting = false;
                  errorText = _friendlyAuthError(e);
                });
              } catch (e) {
                setLocalState(() {
                  deleting = false;
                  errorText = 'Failed to delete account: $e';
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enter your password to permanently delete this account.',
                        style: TextStyle(
                          color: zMuted,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: deleting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: deleting ? null : submitDelete,
                  child: deleting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'The password you entered is incorrect.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'requires-recent-login':
        return 'Please log in again and retry this action.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}

class _ProfileValue extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: zMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Not configured' : value,
              style: const TextStyle(color: zText, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final _SettingsSection section;
  final String title;
  final IconData icon;

  const _NavItemData({
    required this.section,
    required this.title,
    required this.icon,
  });
}

class _SectionPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionPanel({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: zText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: zMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) => children[index],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDanger;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.enabled = true,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDanger ? Colors.red : zBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isDanger ? Colors.red.shade100 : zBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDanger ? const Color(0xFFFFF1F2) : zBlueSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: enabled ? 1 : 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDanger ? Colors.red : zText,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: zMuted,
                        fontSize: 12.6,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              enabled ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
              size: 16,
              color: enabled ? accent : zMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: zMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: zText,
              fontWeight: FontWeight.w900,
              fontSize: 13.2,
            ),
          ),
        ],
      ),
    );
  }
}
