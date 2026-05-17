import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:QUIK/shell/shell_page.dart';
import 'package:QUIK/shell/sidebar_group.dart';
import 'package:QUIK/core/theme/app_theme.dart';

class ShellSidebar extends StatefulWidget {
  final ShellPage activePage;
  final List<SidebarGroup<ShellPage>> sidebarGroups;
  final bool canInquiries;
  final String companyId;
  final String userUid;
  final String currentRole;
  final bool showSettings;
  final void Function(ShellPage) onSelectPage;
  final VoidCallback onLogout;

  const ShellSidebar({
    super.key,
    required this.activePage,
    required this.sidebarGroups,
    required this.canInquiries,
    required this.companyId,
    required this.userUid,
    required this.currentRole,
    required this.showSettings,
    required this.onSelectPage,
    required this.onLogout,
  });

  @override
  State<ShellSidebar> createState() => _ShellSidebarState();
}

class _ShellSidebarState extends State<ShellSidebar> {
  final Set<String> expandedGroups = {};

  bool _groupContainsActive(SidebarGroup group) {
    return group.children.contains(widget.activePage);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: zIconRail,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    kAppName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    kAppTagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF243041), height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                children: [
                  _dashboardNavItem(),
                  const SizedBox(height: 6),
                  ...widget.sidebarGroups.map(_groupWidget),
                  if (widget.showSettings) ...[
                    const SizedBox(height: 6),
                    const Divider(color: Color(0xFF243041)),
                    _settingsNavItem(),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: widget.onLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        widget.currentRole.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardNavItem() {
    final selected = widget.activePage == ShellPage.dashboard;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.onSelectPage(ShellPage.dashboard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.dashboard_outlined,
                size: 18,
                color: selected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsNavItem() {
    final selected = widget.activePage == ShellPage.settingsGeneral;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.onSelectPage(ShellPage.settingsGeneral),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 18,
                color: selected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupWidget(SidebarGroup group) {
    final bool expanded = expandedGroups.contains(group.key);
    final bool hasActiveChild = _groupContainsActive(group);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: hasActiveChild
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border.all(
            color: hasActiveChild
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  if (expanded) {
                    expandedGroups.remove(group.key);
                  } else {
                    expandedGroups.add(group.key);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      group.icon,
                      size: 18,
                      color: hasActiveChild ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        group.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasActiveChild ? Colors.white : Colors.white70,
                          fontWeight: hasActiveChild
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: Colors.white60,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: Column(
                  children: group.children
                      .map((page) => _subNavItem(page as ShellPage))
                      .toList(),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subNavItem(ShellPage page) {
    final bool selected =
        widget.activePage == page ||
        (page == ShellPage.financeTaxInvoice &&
            (widget.activePage == ShellPage.financeExportInvoiceCreate ||
                widget.activePage == ShellPage.financeTaxInvoiceCreate));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onSelectPage(page),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(
                page.icon,
                size: 16,
                color: selected ? zBlue : Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  page.label,
                  style: TextStyle(
                    color: selected ? zText : Colors.white70,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ),
              if (page == ShellPage.salesInquiries && widget.canInquiries)
                _inquiryBadge(selected: selected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inquiryBadge({required bool selected}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('inquiries')
          .where('assignedToUid', isEqualTo: widget.userUid)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: selected ? zBlueSoft : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? zBlue.withValues(alpha: 0.14)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: selected ? zBlue : Colors.white,
            ),
          ),
        );
      },
    );
  }
}
