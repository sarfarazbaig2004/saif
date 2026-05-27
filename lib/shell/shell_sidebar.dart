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
  final double width;
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
    this.width = 240,
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
      width: widget.width,
      color: zIconRail,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: zAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Q',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kAppName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Aman Infra Developer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client Workspace',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          kAppTagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ],
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
      child: _SidebarNavTile(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        selected: selected,
        onTap: () => widget.onSelectPage(ShellPage.dashboard),
      ),
    );
  }

  Widget _settingsNavItem() {
    final selected = widget.activePage == ShellPage.settingsGeneral;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: _SidebarNavTile(
        icon: Icons.settings_outlined,
        label: 'Settings',
        selected: selected,
        onTap: () => widget.onSelectPage(ShellPage.settingsGeneral),
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
            _SidebarNavTile(
              icon: group.icon,
              label: group.title,
              selected: hasActiveChild,
              trailing: Icon(
                expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                color: Colors.white60,
                size: 16,
              ),
              onTap: () {
                setState(() {
                  if (expanded) {
                    expandedGroups.remove(group.key);
                  } else {
                    expandedGroups.add(group.key);
                  }
                });
              },
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
      child: _SidebarNavTile(
        icon: page.icon,
        label: page.label,
        selected: selected,
        dense: true,
        trailing: page == ShellPage.salesInquiries && widget.canInquiries
            ? _inquiryBadge(selected: selected)
            : null,
        onTap: () => widget.onSelectPage(page),
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

class _SidebarNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool dense;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
    this.trailing,
  });

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final dense = widget.dense;
    final bg = selected
        ? (dense ? Colors.white : Colors.white.withValues(alpha: 0.11))
        : (_hovered
              ? Colors.white.withValues(alpha: 0.08)
              : (dense
                    ? Colors.white.withValues(alpha: 0.025)
                    : Colors.transparent));
    final fg = selected && dense ? zText : Colors.white;
    final muted = selected ? fg : Colors.white70;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(dense ? 8 : 10),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            _hovered && !selected ? 2 : 0,
            0,
            0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: dense ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(dense ? 8 : 10),
            border: Border.all(
              color: selected
                  ? (dense
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.16))
                  : Colors.white.withValues(alpha: _hovered ? 0.08 : 0.0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: dense ? 15.5 : 18,
                color: selected && dense ? zBlue : muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontWeight: selected
                        ? (dense ? FontWeight.w800 : FontWeight.w900)
                        : FontWeight.w600,
                    fontSize: dense ? 11.2 : 12,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 6),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
