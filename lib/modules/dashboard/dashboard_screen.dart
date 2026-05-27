// FILE: lib/modules/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/core/app/aman_app_config.dart';
import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/dashboard/dashboard_charts.dart';
import 'package:QUIK/modules/dashboard/dashboard_service.dart';
import 'package:QUIK/modules/dashboard/dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final String companyId;
  final String userName;
  final String currentUserId;
  final Map<String, dynamic> permissions;
  final String role;

  const DashboardScreen({
    super.key,
    required this.companyId,
    required this.userName,
    required this.currentUserId,
    required this.permissions,
    required this.role,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardService _service;
  String _activeTenantId = '';

  @override
  void initState() {
    super.initState();
    _setTenant(widget.companyId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final tenantId = context.watchTenant.selectedTenantId.trim();
    if (tenantId.isNotEmpty && tenantId != _activeTenantId) {
      _setTenant(tenantId);
    }
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.companyId != oldWidget.companyId) {
      _setTenant(widget.companyId);
    }
  }

  void _setTenant(String tenantId) {
    final cleanTenantId = tenantId.trim();
    if (cleanTenantId.isEmpty) return;

    _activeTenantId = cleanTenantId;
    _service = DashboardService(companyId: _activeTenantId);
  }

  bool get _isAdminRole {
    final role = widget.role.trim().toLowerCase();

    return {
      'admin',
      'owner',
      'ceo',
      'manager',
      'superadmin',
      'company_super_admin',
      'software_super_admin',
      'founder',
    }.contains(role);
  }

  bool hasPermission(String module, String submodule) {
    if (_isAdminRole) return true;

    final moduleData = widget.permissions[module];

    if (moduleData is Map && moduleData.containsKey(submodule)) {
      final value = moduleData[submodule];

      if (value is Map) {
        return value['view'] == true;
      }

      return value == true;
    }

    return false;
  }

  String get _workspaceDisplayName {
    final tenantId = _activeTenantId.toLowerCase();

    if (tenantId == 'aman-infra' || tenantId.contains('aman')) {
      return AmanAppConfig.workspaceName;
    }

    final cleanName = widget.userName.trim();
    return cleanName.isNotEmpty ? cleanName : 'ERP Workspace';
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTenantId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Select a company workspace to view dashboard data.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: zAppBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _withSpacing(_dashboardSections(context)),
        ),
      ),
    );
  }

  List<Widget> _dashboardSections(BuildContext context) {
    final sections = <Widget>[
      _buildHeader(),
      if (_buildKpiSection() != null) _buildKpiSection()!,
      if (_buildChartSection() != null) _buildChartSection()!,
      if (_buildCrmSection() != null) _buildCrmSection()!,
      if (_buildTasksActivitiesSection() != null)
        _buildTasksActivitiesSection()!,
      if (_buildTransactionsSection() != null) _buildTransactionsSection()!,
      if (_buildQuickActionsSection(context) != null)
        _buildQuickActionsSection(context)!,
      if (_buildAlertsSection() != null) _buildAlertsSection()!,
      const SizedBox(height: 20),
    ];

    return sections;
  }

  List<Widget> _withSpacing(List<Widget> widgets) {
    final spaced = <Widget>[];

    for (var i = 0; i < widgets.length; i++) {
      spaced.add(widgets[i]);
      if (i < widgets.length - 1) {
        spaced.add(const SizedBox(height: 20));
      }
    }

    return spaced;
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: zBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: zBlueSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apartment_rounded, color: zAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _workspaceDisplayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: zText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'QUIK ERP operational overview for production, finance, inventory, purchase and team activity.',
                      style: TextStyle(fontSize: 14, color: zMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildKpiSection() {
    final showRevenue = hasPermission('finance', 'taxInvoice');
    final showOutstanding = hasPermission('finance', 'outstanding');
    final showQuotes = hasPermission('sales', 'quotations');
    final showConversion = hasPermission('sales', 'inquiries');

    if (!showRevenue && !showOutstanding && !showQuotes && !showConversion) {
      return null;
    }

    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Overview'),
        const SizedBox(height: 16),
        StreamBuilder<DashboardKpiData>(
          stream: _service.streamKpiData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!;
            final kpis = <Widget>[
              if (showRevenue)
                KpiCard(
                  title: 'Total Revenue',
                  value: formatter.format(data.totalRevenue),
                  icon: Icons.account_balance_wallet_outlined,
                  color: zAccent,
                  trendText: 'Live Data',
                  isPositive: true,
                ),
              if (showOutstanding)
                KpiCard(
                  title: 'Outstanding',
                  value: formatter.format(data.totalOutstanding),
                  icon: Icons.access_time_rounded,
                  color: const Color(0xFFF59E0B),
                  trendText: 'Pending Collections',
                  isPositive: false,
                ),
              if (showQuotes)
                KpiCard(
                  title: 'Active Quotes',
                  value: data.activeQuotes.toString(),
                  icon: Icons.description_outlined,
                  color: const Color(0xFF8B5CF6),
                  trendText: 'In Pipeline',
                  isPositive: true,
                ),
              if (showConversion)
                KpiCard(
                  title: 'Conversion Rate',
                  value: '${data.conversionRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF10B981),
                  trendText: 'Avg Performance',
                  isPositive: true,
                ),
            ];

            return _responsiveWrap(kpis);
          },
        ),
      ],
    );
  }

  Widget? _buildChartSection() {
    final showSalesChart =
        hasPermission('sales', 'quotations') ||
        hasPermission('sales', 'inquiries') ||
        hasPermission('finance', 'taxInvoice');

    final showPaymentChart = hasPermission('finance', 'paymentReceived');

    if (!showSalesChart && !showPaymentChart) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Analytics'),
        const SizedBox(height: 16),
        StreamBuilder<DashboardChartData>(
          stream: _service.streamChartData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!;

            final salesChart = DashboardCard(
              title: 'Sales Overview',
              child: SizedBox(
                height: 280,
                child: SalesBarChart(monthlySales: data.monthlySales),
              ),
            );

            final paymentChart = DashboardCard(
              title: 'Payment Analytics',
              child: SizedBox(
                height: 280,
                child: PaymentPieChart(
                  paidAmount: data.paidAmount,
                  pendingAmount: data.pendingAmount,
                ),
              ),
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;

                if (showSalesChart && showPaymentChart) {
                  return isWide
                      ? Row(
                          children: [
                            Expanded(flex: 3, child: salesChart),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: paymentChart),
                          ],
                        )
                      : Column(
                          children: [
                            salesChart,
                            const SizedBox(height: 16),
                            paymentChart,
                          ],
                        );
                }

                return showSalesChart ? salesChart : paymentChart;
              },
            );
          },
        ),
      ],
    );
  }

  Widget? _buildCrmSection() {
    if (!hasPermission('crm', 'customers')) return null;

    const kpiStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: Color(0xFF0F172A),
      letterSpacing: -0.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'CRM Overview'),
        const SizedBox(height: 16),
        StreamBuilder<DashboardCrmData>(
          stream: _service.streamCrmData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!;
            return _responsiveWrap([
              DashboardCard(
                title: 'Open Deals',
                child: Text(data.openDeals.toString(), style: kpiStyle),
              ),
              DashboardCard(
                title: 'Follow-ups Today',
                child: Text(data.followUpsToday.toString(), style: kpiStyle),
              ),
              DashboardCard(
                title: 'New Inquiries',
                child: Text(data.newInquiries.toString(), style: kpiStyle),
              ),
            ]);
          },
        ),
      ],
    );
  }

  Widget? _buildTasksActivitiesSection() {
    final showTasks = hasPermission('sales', 'tasks');
    final showActivities = hasPermission('sales', 'followUps');

    if (!showTasks && !showActivities) return null;

    final activities = DashboardCard(
      title: 'Recent Activities',
      child: _staticList(
        itemCount: 3,
        itemBuilder: (_) =>
            const ActivityItem(text: 'System synchronization successful.'),
      ),
    );

    final tasks = DashboardCard(
      title: 'Pending Tasks',
      child: _staticList(
        itemCount: 3,
        itemBuilder: (_) =>
            const TaskItem(text: 'Check pending invoices and follow-ups.'),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Tasks & Activities'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            if (showTasks && showActivities) {
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: activities),
                        const SizedBox(width: 16),
                        Expanded(child: tasks),
                      ],
                    )
                  : Column(
                      children: [activities, const SizedBox(height: 16), tasks],
                    );
            }

            return showActivities ? activities : tasks;
          },
        ),
      ],
    );
  }

  Widget? _buildTransactionsSection() {
    if (!hasPermission('finance', 'paymentReceived')) return null;

    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );

    return StreamBuilder<List<DashboardTransaction>>(
      stream: _service.streamRecentTransactions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final transactions = snapshot.data!;

        if (transactions.isEmpty) {
          return const DashboardCard(
            title: 'Recent Transactions',
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent transactions found.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          );
        }

        return DashboardCard(
          title: 'Recent Transactions',
          trailing: TextButton(onPressed: () {}, child: const Text('View All')),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final txn = transactions[index];

              return TransactionItem(
                title: txn.title,
                subtitle: txn.subtitle,
                amount: '+ ${formatter.format(txn.amount)}',
                isPositive: txn.isPositive,
                status: txn.status,
              );
            },
          ),
        );
      },
    );
  }

  Widget? _buildQuickActionsSection(BuildContext context) {
    final actions = <Widget>[
      if (hasPermission('sales', 'inquiries'))
        ActionCard(
          icon: Icons.campaign_rounded,
          label: 'Add Inquiry',
          onTap: () => _openPlaceholder(context, 'Add Inquiry'),
        ),
      if (hasPermission('sales', 'quotations'))
        ActionCard(
          icon: Icons.receipt_long_outlined,
          label: 'Create Quotation',
          onTap: () => _openPlaceholder(context, 'Create Quotation'),
        ),
      if (hasPermission('finance', 'taxInvoice'))
        ActionCard(
          icon: Icons.add_card_rounded,
          label: 'New Invoice',
          onTap: () => _openPlaceholder(context, 'New Invoice'),
        ),
      if (hasPermission('finance', 'paymentReceived'))
        ActionCard(
          icon: Icons.receipt_long_rounded,
          label: 'Record Payment',
          onTap: () => _openPlaceholder(context, 'Record Payment'),
        ),
      if (hasPermission('crm', 'customers'))
        ActionCard(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Add Customer',
          onTap: () => _openPlaceholder(context, 'Add Customer'),
        ),
    ];

    if (actions.isEmpty) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 16),
        _responsiveWrap(actions),
      ],
    );
  }

  Widget? _buildAlertsSection() {
    if (!hasPermission('inventory', 'lowStockAlerts')) return null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF97316),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'System Alert: Dashboard connected to live Firestore data successfully.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Review')),
        ],
      ),
    );
  }

  Widget _responsiveWrap(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var columns = width > 1000 ? 4 : (width > 650 ? 2 : 1);

        if (children.length < columns) columns = children.length;
        if (columns == 0) return const SizedBox.shrink();

        const spacing = 16.0;
        final cardWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: cardWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _staticList({
    required int itemCount,
    required Widget Function(int index) itemBuilder,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) =>
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
      itemBuilder: (_, index) => itemBuilder(index),
    );
  }

  void _openPlaceholder(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Center(child: Text('Module Screen Placeholder')),
        ),
      ),
    );
  }
}
