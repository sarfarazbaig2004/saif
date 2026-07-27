import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:QUIK/auth/login/login_workspace_preview.dart';
import 'package:QUIK/core/theme/app_theme.dart';

class LoginBrandPanel extends StatelessWidget {
  const LoginBrandPanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: Color(0xFF16202B)),
      if (!compact)
        const Positioned.fill(child: LoginDashboardBackdrop())
      else
        const Positioned.fill(child: _CompactBrandBackdrop()),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF111820).withValues(alpha: compact ? 0.86 : 0.9),
                const Color(0xFF17212B).withValues(alpha: compact ? 0.68 : 0.7),
                const Color(
                  0xFF253444,
                ).withValues(alpha: compact ? 0.52 : 0.46),
              ],
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.04),
                Colors.black.withValues(alpha: 0.24),
              ],
            ),
          ),
        ),
      ),
      if (!compact)
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth < 760 ? 44 : 72,
                54,
                40,
                52,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BrandHeader(),
                  Spacer(flex: 2),
                  _HeroCopy(),
                  Spacer(),
                  _FeatureFooter(),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class _CompactBrandBackdrop extends StatelessWidget {
  const _CompactBrandBackdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF172333), Color(0xFF2E455C)],
      ),
    ),
    child: Center(
      child: Opacity(
        opacity: 0.12,
        child: Image.asset(
          'assets/images/logo.png',
          width: 360,
          fit: BoxFit.contain,
        ),
      ),
    ),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
      const SizedBox(width: 18),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUIK ERP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
              shadows: [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 14,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          SizedBox(height: 9),
          Text(
            'Modern Business Management Platform',
            style: TextStyle(
              color: Color(0xFFD3D9E1),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 1280 ? 46.0 : 56.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 710),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Run Your Entire\nBusiness From\nOne Platform',
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              height: 1.02,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.2,
              shadows: const [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(0, 5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'CRM, Inventory, Finance, Service Management and Analytics in one '
            'connected workspace.',
            style: TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ModulePill(label: 'CRM'),
              _ModulePill(label: 'Inventory'),
              _ModulePill(label: 'Finance'),
              _ModulePill(label: 'Service'),
              _ModulePill(label: 'Analytics'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModulePill extends StatelessWidget {
  const _ModulePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _FeatureFooter extends StatelessWidget {
  const _FeatureFooter();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 5,
        height: 36,
        decoration: BoxDecoration(
          color: zAccent,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      const SizedBox(width: 14),
      const Text(
        'Intelligent CRM & Pipeline Workflows',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
