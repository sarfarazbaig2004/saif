import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

class OperationalStatusCards extends StatelessWidget {
  const OperationalStatusCards({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.account_tree_outlined, 'Active Projects', 'Tracked'),
      (Icons.request_quote_outlined, 'Pending PO', 'Approval gated'),
      (Icons.local_shipping_outlined, 'Dispatch Due', 'Schedule controlled'),
      (Icons.receipt_long_outlined, 'Billing', 'Role-gated'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3.25,
      children: [
        for (final item in items)
          _StatusCard(icon: item.$1, label: item.$2, value: item.$3),
      ],
    );
  }
}

class EnterpriseTrustBadges extends StatelessWidget {
  const EnterpriseTrustBadges({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_user_outlined, 'Secure Workspace'),
      (Icons.admin_panel_settings_outlined, 'Role-Based Access'),
      (Icons.fact_check_outlined, 'Audit Ready'),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _TrustBadge(icon: items[i].$1, label: items[i].$2),
          ),
          if (i < items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class LoginVendorCredit extends StatelessWidget {
  const LoginVendorCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: zBlue, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: zText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: zMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: zMuted, size: 17),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: zMuted,
              fontSize: 10.5,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
