import 'package:flutter/material.dart';

import 'package:QUIK/auth/login/login_brand_metrics.dart';
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
            SizedBox(height: 16),
            OperationalStatusCards(),
            SizedBox(height: 16),
            EnterpriseTrustBadges(),
            SizedBox(height: 14),
            LoginVendorCredit(),
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

class _ModulePill extends StatefulWidget {
  final IconData icon;
  final String label;

  const _ModulePill({required this.icon, required this.label});

  @override
  State<_ModulePill> createState() => _ModulePillState();
}

class _ModulePillState extends State<_ModulePill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -1.5 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 17, color: zBlue),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                color: zText,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
