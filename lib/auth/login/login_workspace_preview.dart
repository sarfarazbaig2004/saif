import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

class AbstractWorkspacePreview extends StatelessWidget {
  const AbstractWorkspacePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zAppBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(),
          SizedBox(height: 16),
          _IndustrialWorkflow(),
          SizedBox(height: 14),
          _ControlStrip(),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Text(
          'Industrial Workflow',
          style: TextStyle(
            color: zText,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        Spacer(),
        _StatusBadge(label: 'Controlled Access'),
      ],
    );
  }
}

class _IndustrialWorkflow extends StatelessWidget {
  const _IndustrialWorkflow();

  @override
  Widget build(BuildContext context) {
    const stages = [
      ('Tender', true),
      ('Engineering', true),
      ('Fabrication', true),
      ('Galvanizing', false),
      ('Dispatch', false),
      ('Site Billing', false),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          _StagePill(label: stages[i].$1, active: stages[i].$2),
          if (i < stages.length - 1) const _StageConnector(),
        ],
      ],
    );
  }
}

class _StagePill extends StatefulWidget {
  final String label;
  final bool active;

  const _StagePill({required this.label, required this.active});

  @override
  State<_StagePill> createState() => _StagePillState();
}

class _StagePillState extends State<_StagePill> {
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: widget.active
              ? const Color(0xFFFFF7ED)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.active
                ? const Color(0xFFF97316)
                : const Color(0xFFCBD5E1),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.active ? zBlue : const Color(0xFF475569),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StageConnector extends StatelessWidget {
  const _StageConnector();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.arrow_forward_ios_rounded,
      size: 12,
      color: Color(0xFF94A3B8),
    );
  }
}

class _ControlStrip extends StatelessWidget {
  const _ControlStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _ControlTile(icon: Icons.event_note, label: 'Projects'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ControlTile(
            icon: Icons.solar_power_outlined,
            label: 'Solar Structures',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ControlTile(
            icon: Icons.cell_tower_outlined,
            label: 'Tower Fabrication',
          ),
        ),
      ],
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ControlTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: zBlue, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: zText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: zMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
