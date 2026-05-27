import 'package:flutter/material.dart';

import 'package:QUIK/auth/login/login_workspace_preview.dart';
import 'package:QUIK/core/theme/app_theme.dart';

class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 38, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BrandCopy(),
            SizedBox(height: 24),
            AbstractWorkspacePreview(),
            SizedBox(height: 18),
            _ModuleSignals(),
            SizedBox(height: 18),
            _TrustLayer(),
            SizedBox(height: 18),
            _SecurityCompliance(),
          ],
        ),
      ),
    );
  }
}

class _BrandCopy extends StatelessWidget {
  const _BrandCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enterprise ERP for Infrastructure, Fabrication and Industrial Operations',
          style: TextStyle(
            fontSize: 32,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: zText,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Manage projects, inventory, production and finance from a single '
          'secure enterprise workspace for Aman Infra teams.',
          style: TextStyle(
            fontSize: 15,
            height: 1.65,
            color: zMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ModuleSignals extends StatelessWidget {
  const _ModuleSignals();

  @override
  Widget build(BuildContext context) {
    const modules = [
      (Icons.solar_power_outlined, 'Solar Structures'),
      (Icons.cell_tower_outlined, 'Transmission Lines'),
      (Icons.precision_manufacturing_outlined, 'Tower Fabrication'),
      (Icons.factory_outlined, 'Galvanizing'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in modules) _ModulePill(icon: item.$1, label: item.$2),
      ],
    );
  }
}

class _ModulePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ModulePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: zBlue),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: zText,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustLayer extends StatelessWidget {
  const _TrustLayer();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_user_outlined, 'Secure Workspace'),
      (Icons.admin_panel_settings_outlined, 'Role-Based Access'),
      (Icons.fact_check_outlined, 'Audit Ready'),
      (Icons.cloud_done_outlined, 'Cloud Enabled'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items) _TrustPill(icon: item.$1, label: item.$2),
      ],
    );
  }
}

class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: zMuted),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: zMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityCompliance extends StatelessWidget {
  const _SecurityCompliance();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SECURITY & COMPLIANCE',
          style: TextStyle(
            color: zMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 8),
        _ComplianceLine('• Role-Based Access Control'),
        _ComplianceLine('• Audit Ready Logs'),
        _ComplianceLine('• Secure Cloud Workspace'),
        _ComplianceLine('• Production & Inventory Control'),
        SizedBox(height: 10),
        Text(
          'QUIK ERP by Genzprotech',
          style: TextStyle(
            color: zMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Enterprise Infrastructure ERP Platform',
          style: TextStyle(
            color: zMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _ComplianceLine extends StatelessWidget {
  final String text;

  const _ComplianceLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: zMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
    );
  }
}
