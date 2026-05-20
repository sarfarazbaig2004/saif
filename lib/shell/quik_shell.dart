import 'package:QUIK/shell/sidebar_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/inventory/providers/inventory_config_provider.dart';
import 'package:QUIK/core/modules/module_registry.dart';
import 'package:QUIK/core/modules/providers/module_access_provider.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/administration/inventory/screen_inventory_profile_settings.dart';
import 'package:QUIK/modules/administration/compliance/screens/compliance_legal_screen.dart';
import 'package:QUIK/modules/administration/modules/screen_company_modules.dart';
import 'package:QUIK/modules/administration/users/screen_user_management.dart';
import 'package:QUIK/modules/crm/customers/screens_customer_list.dart';
import 'package:QUIK/modules/dashboard/dashboard_screen.dart';
import 'package:QUIK/modules/dispatch/screens/dispatch_list_screen.dart';
import 'package:QUIK/modules/inventory/fabrication/screens/material_inward_screen.dart';
import 'package:QUIK/modules/inventory/fabrication/screens/material_issue_screen.dart';
import 'package:QUIK/modules/inventory/fabrication/screens/raw_material_master_screen.dart';
import 'package:QUIK/modules/inventory/fabrication/screens/raw_material_low_stock_screen.dart';
import 'package:QUIK/modules/inventory/fabrication/screens/raw_material_stock_screen.dart';
import 'package:QUIK/modules/purchase/fabrication/screens/purchase_bill_screen.dart';
import 'package:QUIK/modules/purchase/miraj/screens/vendor_ledger_screen.dart';
import 'package:QUIK/modules/purchase/miraj/screens/vendor_master_screen.dart';
import 'package:QUIK/modules/purchase/miraj/screens/vendor_offer_screen.dart';
import 'package:QUIK/modules/purchase/miraj/screens/vendor_purchase_order_screen.dart';
import 'package:QUIK/modules/sales/inquiries/screens_inquiry_list.dart';
import 'package:QUIK/modules/sales/quotations/screens_quotation_list.dart';
import 'package:QUIK/modules/settings/screen_settings_home.dart';
import 'package:QUIK/modules/sales/sales_orders/screens_sales_order_list.dart';
import 'package:QUIK/modules/customer_po/screens/customer_po_list_screen.dart';
import 'package:QUIK/modules/projects/screens/projects_list_screen.dart';
import 'package:QUIK/modules/service/screens_service_home.dart';

// Finance Sub-Modules
import 'package:QUIK/modules/finance/invoice/screens/invoice_list_screen.dart';
import 'package:QUIK/modules/finance/invoice/screens/export_invoice_screen.dart';
import 'package:QUIK/modules/finance/invoice/screens/tax_invoice_screen.dart';
import 'package:QUIK/modules/finance/proforma_invoice/proforma_list_screen.dart';

// Payments & Outstanding Sub-Modules
import 'package:QUIK/modules/finance/payments_received/screens/payments_list_screen.dart';
import 'package:QUIK/modules/finance/outstanding/screens/outstanding_screen.dart';
import 'package:QUIK/modules/hr/screens/hr_home_screen.dart';
import 'package:QUIK/modules/production/bom/screens/bom_list_screen.dart';
import 'package:QUIK/modules/production/boq/screens/boq_list_screen.dart';
import 'package:QUIK/modules/production/contractor_jobs/screens/contractor_job_list_screen.dart';
import 'package:QUIK/modules/production/execution/screens/production_entry_list_screen.dart';
import 'package:QUIK/modules/production/galvanizing/screens/galvanizing_job_list_screen.dart';
import 'package:QUIK/modules/production/inspections/screens/inspection_list_screen.dart';
import 'package:QUIK/modules/production/job_cards/screens/job_card_list_screen.dart';
import 'package:QUIK/modules/production/masters/screens/item_list_screen.dart';
import 'package:QUIK/modules/production/masters/screens/process_list_screen.dart';
import 'package:QUIK/modules/production/masters/screens/work_center_list_screen.dart';
import 'package:QUIK/modules/reports/sales_report/sales_report_screen.dart';
import 'package:QUIK/shell/shell_page.dart';
import 'package:QUIK/shell/shell_sidebar.dart';

class QuikShell extends StatefulWidget {
  final String userEmail;
  final String userUid;
  final String companyId;
  final String companyName;
  final String role;
  final Map<String, dynamic> permissions;
  final String? userDisplayName;
  final String? industry;

  const QuikShell({
    super.key,
    required this.userEmail,
    required this.userUid,
    required this.companyId,
    required this.companyName,
    required this.role,
    required this.permissions,
    this.userDisplayName,
    this.industry,
  });

  @override
  State<QuikShell> createState() => _QuikShellState();
}

class _QuikShellState extends State<QuikShell> {
  ShellPage activePage = ShellPage.dashboard;

  String? _resolvedIndustry;

  // Live State tracked securely via Firestore streams
  String _currentRole = 'viewer';
  Map<String, dynamic> _currentPermissions = {};
  List<SidebarGroup<ShellPage>> _currentSidebarGroups = [];

  @override
  void initState() {
    super.initState();
    _resolvedIndustry = widget.industry;

    if (_resolvedIndustry == null || _resolvedIndustry!.isEmpty) {
      _fetchIndustry();
    } else {}
  }

  Future<void> _fetchIndustry() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final raw =
            (data['industryType'] ??
                    data['businessCategory'] ??
                    data['industry'] ??
                    '')
                .toString()
                .toLowerCase();

        if (raw.contains('export') && raw.contains('import')) {
          _resolvedIndustry = 'export_import';
        } else {
          _resolvedIndustry = raw;
        }
      } else {
        _resolvedIndustry = 'unknown';
      }
    } catch (e) {
      _resolvedIndustry = 'unknown';
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool get isAdminOrManager {
    final r = _currentRole;
    return r == 'owner' ||
        r == 'software_super_admin' ||
        r == 'company_super_admin' ||
        r == 'founder' ||
        r == 'ceo' ||
        r == 'superadmin' ||
        r == 'admin' ||
        r == 'manager';
  }

  bool get _canViewComplianceLegal {
    if (isAdminOrManager) return true;
    return _currentRole == 'finance' ||
        _currentRole == 'hr' ||
        _currentRole == 'production' ||
        _currentRole == 'qa' ||
        _hasPermission('administration', 'complianceLegal');
  }

  bool get _isMirajTenant {
    final name = widget.companyName.toLowerCase();
    final id = widget.companyId.toLowerCase();
    return name.contains('miraj') || id.contains('miraj');
  }

  bool _hasPermission(
    String module,
    String submodule, {
    String action = 'view',
  }) {
    if (isAdminOrManager) return true;

    final moduleData = _currentPermissions[module];
    if (moduleData is Map && moduleData.containsKey(submodule)) {
      final subData = moduleData[submodule];
      if (subData is Map) {
        return subData[action] == true;
      }
      return subData == true;
    }

    if (_currentPermissions.containsKey(submodule)) {
      final legacySubData = _currentPermissions[submodule];
      if (legacySubData is Map) {
        return legacySubData[action] == true;
      }
      return legacySubData == true && action == 'view';
    }

    if (_currentPermissions.containsKey('$module.$submodule')) {
      return _currentPermissions['$module.$submodule'] == true &&
          action == 'view';
    }

    return false;
  }

  bool get canInquiries {
    if (_resolvedIndustry == 'export_import') return false;
    return _hasPermission('sales', 'inquiries');
  }

  bool _canViewPage(ShellPage page) {
    if (_resolvedIndustry == 'export_import') {
      if (page == ShellPage.salesInquiries ||
          page == ShellPage.salesQuotations ||
          page == ShellPage.reportsInquiry) {
        return false;
      }
    }

    if (_isProductionPage(page) && !_isModuleEnabled(ModuleIds.production)) {
      return false;
    }

    if (_isDispatchPage(page) && !_isModuleEnabled(ModuleIds.dispatch)) {
      return false;
    }

    if (_isPurchasePage(page) && !_isModuleEnabled(ModuleIds.purchase)) {
      return false;
    }

    if (page == ShellPage.hrHome && !_isModuleEnabled(ModuleIds.hrAdmin)) {
      return false;
    }

    if (page == ShellPage.platformTenantModules) {
      return false;
    }

    if (page == ShellPage.adminModules ||
        page == ShellPage.adminInventoryProfile) {
      return false;
    }

    if (isAdminOrManager) return true;

    if (_isGeneralInventoryPage(page) &&
        _isFabricationInventory &&
        !_isFabricationInventoryCompatiblePage(page)) {
      return false;
    }

    if (_isFabricationOnlyInventoryPage(page) && !_isFabricationInventory) {
      return false;
    }

    switch (page) {
      case ShellPage.dashboard:
        return true;
      case ShellPage.platformTenantModules:
        return false;
      case ShellPage.settingsGeneral:
        return true;

      // New Modules
      case ShellPage.customerPoList:
      case ShellPage.projectsList:
      case ShellPage.planningDashboard:
      case ShellPage.schedulingCalendar:
      case ShellPage.engineeringDrawings:
      case ShellPage.engineeringBomBoq:
        return true; // Let them see the placeholder landing page if module is on

      // Sales
      case ShellPage.salesInquiries:
        return _hasPermission('sales', 'inquiries');
      case ShellPage.salesQuotations:
        return _hasPermission('sales', 'quotations');
      case ShellPage.salesOrders:
        return _hasPermission('sales', 'salesOrder');
      case ShellPage.salesFollowUps:
        return _hasPermission('sales', 'followUps');
      case ShellPage.salesTasks:
        return _hasPermission('sales', 'tasks');
      case ShellPage.salesMeetings:
        return _hasPermission('sales', 'meetings');
      // Service
      case ShellPage.service:
        return true;
      // CRM
      case ShellPage.crmCustomers:
        return _hasPermission('crm', 'customers');
      case ShellPage.crmContacts:
        return _hasPermission('crm', 'contacts');
      case ShellPage.crmVisits:
        return _hasPermission('crm', 'customerVisits');
      case ShellPage.crmCommunication:
        return _hasPermission('crm', 'communicationHistory');
      // Purchase
      case ShellPage.purchaseVendors:
        return _hasPermission('purchase', 'vendors');
      case ShellPage.purchaseVendorOffers:
        return _isMirajTenant &&
            (_hasPermission('purchase', 'vendorOffers') ||
                _hasPermission('purchase', 'vendors') ||
                _hasPermission('purchase', 'purchaseOrders'));
      case ShellPage.purchasePurchaseOrders:
        return _isMirajTenant && _hasPermission('purchase', 'purchaseOrders');
      case ShellPage.purchaseOrders:
        return _hasPermission('purchase', 'purchaseOrders');
      case ShellPage.purchaseGrn:
        return _hasPermission('purchase', 'grnMaterialReceipt');
      case ShellPage.purchaseLedger:
        return _isMirajTenant &&
            (_hasPermission('purchase', 'vendorLedger') ||
                _hasPermission('purchase', 'vendors') ||
                _hasPermission('purchase', 'purchaseOrders'));
      // Inventory
      case ShellPage.inventoryProducts:
        return _hasPermission('inventory', 'products');
      case ShellPage.inventoryStockSummary:
        return _hasPermission('inventory', 'stockSummary');
      case ShellPage.inventoryStockIn:
        return _hasPermission('inventory', 'stockIn');
      case ShellPage.inventoryStockOut:
        return _hasPermission('inventory', 'stockOut');
      case ShellPage.inventoryWarehouse:
        return _hasPermission('inventory', 'warehouse');
      case ShellPage.inventoryLowStock:
        return _hasPermission('inventory', 'lowStockAlerts');
      case ShellPage.inventoryRawMaterialStock:
      case ShellPage.inventoryMaterialInward:
      case ShellPage.inventoryMaterialIssue:
        return _hasPermission('inventory', 'products');
      // Dispatch
      case ShellPage.dispatchReady:
      case ShellPage.dispatchChallans:
      case ShellPage.dispatchShipmentTracking:
      case ShellPage.dispatchDelivered:
        return _isModuleEnabled(ModuleIds.dispatch) &&
            _hasPermission('dispatch', _dispatchPermissionKey(page));
      // Production
      case ShellPage.productionItems:
      case ShellPage.productionProcesses:
      case ShellPage.productionWorkCenters:
      case ShellPage.productionBom:
      case ShellPage.productionBoq:
      case ShellPage.productionJobCards:
      case ShellPage.productionContractorJobs:
      case ShellPage.productionGalvanizing:
      case ShellPage.productionInspections:
      case ShellPage.productionEntries:
        return _isModuleEnabled(ModuleIds.production);
      case ShellPage.hrHome:
        return _hasPermission('hr', 'employees') ||
            _hasPermission('hr', 'attendance') ||
            _hasPermission('hr', 'wages');
      // Finance
      case ShellPage.financeProforma:
        return _hasPermission('finance', 'proformaInvoice');
      case ShellPage.financeTaxInvoice:
      case ShellPage.financeTaxInvoiceCreate:
      case ShellPage.financeExportInvoiceCreate:
        return _hasPermission('finance', 'taxInvoice');
      case ShellPage.financePaymentsReceived:
        return _hasPermission('finance', 'paymentReceived');
      case ShellPage.financeOutstanding:
        return _hasPermission('finance', 'outstanding');
      case ShellPage.financeExpenses:
        return _hasPermission('finance', 'expenseEntries');
      // Reports
      case ShellPage.reportsSales:
        return _hasPermission('reports', 'salesReport');
      case ShellPage.reportsInquiry:
        return _hasPermission('reports', 'inquiryReport');
      case ShellPage.reportsCustomer:
        return _hasPermission('reports', 'customerReport');
      case ShellPage.reportsProduct:
        return _hasPermission('reports', 'productReport');
      case ShellPage.reportsPayment:
        return _hasPermission('reports', 'paymentReport');
      // Administration
      case ShellPage.adminUsers:
        return _hasPermission('administration', 'users');
      case ShellPage.adminRoles:
        return _hasPermission('administration', 'rolesPermissions');
      case ShellPage.adminModules:
        return false;
      case ShellPage.adminInventoryProfile:
        return false;
      case ShellPage.adminComplianceLegal:
        return _canViewComplianceLegal;
      case ShellPage.adminCompanyProfile:
        return _hasPermission('administration', 'companyProfile');
      case ShellPage.adminBranches:
        return _hasPermission('administration', 'branches');
      case ShellPage.adminAuditLogs:
        return _hasPermission('administration', 'auditLogs');
    }
  }

  bool _isProductionPage(ShellPage page) {
    return page == ShellPage.productionItems ||
        page == ShellPage.productionProcesses ||
        page == ShellPage.productionWorkCenters ||
        page == ShellPage.productionBom ||
        page == ShellPage.productionBoq ||
        page == ShellPage.productionJobCards ||
        page == ShellPage.productionContractorJobs ||
        page == ShellPage.productionGalvanizing ||
        page == ShellPage.productionInspections ||
        page == ShellPage.productionEntries;
  }

  bool _isDispatchPage(ShellPage page) {
    return page == ShellPage.dispatchReady ||
        page == ShellPage.dispatchChallans ||
        page == ShellPage.dispatchShipmentTracking ||
        page == ShellPage.dispatchDelivered;
  }

  bool _isPurchasePage(ShellPage page) {
    return page == ShellPage.purchaseVendors ||
        page == ShellPage.purchaseVendorOffers ||
        page == ShellPage.purchasePurchaseOrders ||
        page == ShellPage.purchaseOrders ||
        page == ShellPage.purchaseGrn ||
        page == ShellPage.purchaseLedger;
  }

  String _dispatchPermissionKey(ShellPage page) {
    switch (page) {
      case ShellPage.dispatchReady:
        return 'readyForDispatch';
      case ShellPage.dispatchChallans:
        return 'dispatchChallans';
      case ShellPage.dispatchShipmentTracking:
        return 'shipmentTracking';
      case ShellPage.dispatchDelivered:
        return 'deliveredOrders';
      default:
        return 'readyForDispatch';
    }
  }

  bool get _isFabricationInventory {
    return InventoryConfigProvider.of(context).isFabricationInventory;
  }

  bool _isGeneralInventoryPage(ShellPage page) {
    return page == ShellPage.inventoryProducts ||
        page == ShellPage.inventoryStockSummary ||
        page == ShellPage.inventoryStockIn ||
        page == ShellPage.inventoryStockOut ||
        page == ShellPage.inventoryWarehouse ||
        page == ShellPage.inventoryLowStock;
  }

  bool _isFabricationInventoryCompatiblePage(ShellPage page) {
    return page == ShellPage.inventoryProducts ||
        page == ShellPage.inventoryStockSummary ||
        page == ShellPage.inventoryStockIn ||
        page == ShellPage.inventoryStockOut ||
        page == ShellPage.inventoryWarehouse ||
        page == ShellPage.inventoryLowStock ||
        page == ShellPage.inventoryRawMaterialStock ||
        page == ShellPage.inventoryMaterialInward ||
        page == ShellPage.inventoryMaterialIssue;
  }

  bool _isFabricationOnlyInventoryPage(ShellPage page) {
    return page == ShellPage.inventoryRawMaterialStock ||
        page == ShellPage.inventoryMaterialInward ||
        page == ShellPage.inventoryMaterialIssue;
  }

  List<ShellPage> get _inventorySidebarPages {
    if (_isFabricationInventory) {
      return const [
        ShellPage.inventoryProducts,
        ShellPage.inventoryRawMaterialStock,
        ShellPage.inventoryMaterialInward,
        ShellPage.inventoryMaterialIssue,
        ShellPage.inventoryWarehouse,
        ShellPage.inventoryLowStock,
      ];
    }

    return const [
      ShellPage.inventoryProducts,
      ShellPage.inventoryStockSummary,
      ShellPage.inventoryStockIn,
      ShellPage.inventoryStockOut,
      ShellPage.inventoryWarehouse,
      ShellPage.inventoryLowStock,
    ];
  }

  List<SidebarGroup<ShellPage>> get _allSidebarGroups {
    if (_resolvedIndustry == 'export_import') {
      return [
        SidebarGroup(
          key: ModuleIds.crm,
          title: 'CRM',
          icon: Icons.people_alt_outlined,
          children: [ShellPage.crmCustomers],
        ),
        SidebarGroup(
          key: ModuleIds.inventoryStore,
          title: 'Inventory',
          icon: Icons.inventory_2_outlined,
          children: _inventorySidebarPages,
        ),
        SidebarGroup(
          key: ModuleIds.hrAdmin,
          title: 'HR',
          icon: Icons.badge_outlined,
          children: [ShellPage.hrHome],
        ),
        SidebarGroup(
          key: ModuleIds.finance,
          title: 'Finance',
          icon: Icons.account_balance_wallet_outlined,
          children: [
            ShellPage.financeProforma,
            ShellPage.financeTaxInvoice,
            ShellPage.financePaymentsReceived,
            ShellPage.financeOutstanding,
            ShellPage.financeExpenses,
          ],
        ),
        SidebarGroup(
          key: ModuleIds.reports,
          title: 'Reports',
          icon: Icons.assessment_outlined,
          children: [
            ShellPage.reportsSales,
            ShellPage.reportsCustomer,
            ShellPage.reportsPayment,
          ],
        ),
        SidebarGroup(
          key: ModuleIds.administration,
          title: 'Administration',
          icon: Icons.admin_panel_settings_outlined,
          children: [
            ShellPage.adminUsers,
            ShellPage.adminModules,
            ShellPage.adminInventoryProfile,
            ShellPage.adminComplianceLegal,
          ],
        ),
      ];
    }

    // NEW 19-MODULE LAYOUT DEFAULT
    return [
      const SidebarGroup<ShellPage>(
        key: ModuleIds.crm,
        title: 'CRM',
        icon: Icons.people_alt_outlined,
        children: [
          ShellPage.crmCustomers,
          // ShellPage.crmContacts,      // moved into customer detail
          // ShellPage.crmVisits,        // moved into customer detail
          // ShellPage.crmCommunication, // moved into customer detail
        ],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.sales,
        title: 'Sales',
        icon: Icons.trending_up_outlined,
        children: [
          ShellPage.salesInquiries,
          ShellPage.salesQuotations,
          // ShellPage.salesOrders, // temporarily hidden
          ShellPage.salesFollowUps,
          ShellPage.salesTasks,
          ShellPage.salesMeetings,
        ],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.customerPo,
        title: 'Customer PO',
        icon: Icons.request_quote_outlined,
        children: [ShellPage.customerPoList],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.projectsJobCards,
        title: 'Projects & Job Cards',
        icon: Icons.assignment_outlined,
        children: [ShellPage.projectsList, ShellPage.productionJobCards],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.planningScheduling,
        title: 'Planning & Scheduling',
        icon: Icons.calendar_month_outlined,
        children: [ShellPage.planningDashboard, ShellPage.schedulingCalendar],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.engineering,
        title: 'Engineering',
        icon: Icons.architecture_outlined,
        children: [ShellPage.engineeringDrawings, ShellPage.engineeringBomBoq],
      ),
      SidebarGroup<ShellPage>(
        key: ModuleIds.inventoryStore,
        title: 'Inventory & Store',
        icon: Icons.inventory_2_outlined,
        children: _inventorySidebarPages,
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.purchase,
        title: 'Purchase',
        icon: Icons.shopping_cart_outlined,
        children: [
          ShellPage.purchaseVendors,
          ShellPage.purchaseVendorOffers,
          ShellPage.purchasePurchaseOrders,
          ShellPage.purchaseOrders,
          ShellPage.purchaseGrn,
          ShellPage.purchaseLedger,
        ],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.production,
        title: 'Production',
        icon: Icons.precision_manufacturing_outlined,
        children: [
          ShellPage.productionItems,
          ShellPage.productionProcesses,
          ShellPage.productionWorkCenters,
          ShellPage.productionBom,
          ShellPage.productionBoq,
          ShellPage.productionEntries,
        ],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.contractorJobWork,
        title: 'Contractor Job Work',
        icon: Icons.engineering_outlined,
        children: [ShellPage.productionContractorJobs],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.galvanizing,
        title: 'Galvanizing',
        icon: Icons.factory_outlined,
        children: [ShellPage.productionGalvanizing],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.inspectionQa,
        title: 'Inspection / QA',
        icon: Icons.fact_check_outlined,
        children: [ShellPage.productionInspections],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.dispatch,
        title: 'Dispatch',
        icon: Icons.local_shipping_outlined,
        children: [
          ShellPage.dispatchReady,
          ShellPage.dispatchChallans,
          ShellPage.dispatchShipmentTracking,
          ShellPage.dispatchDelivered,
        ],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.hrAdmin,
        title: 'HR',
        icon: Icons.badge_outlined,
        children: [ShellPage.hrHome],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.finance,
        title: 'Finance',
        icon: Icons.account_balance_wallet_outlined,
        children: [
          ShellPage.financeProforma,
          ShellPage.financeTaxInvoice,
          ShellPage.financePaymentsReceived,
          ShellPage.financeOutstanding,
          ShellPage.financeExpenses,
        ],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.reports,
        title: 'Reports',
        icon: Icons.assessment_outlined,
        children: [
          ShellPage.reportsSales,
          ShellPage.reportsInquiry,
          ShellPage.reportsCustomer,
          ShellPage.reportsProduct,
          ShellPage.reportsPayment,
        ],
      ),
      const SidebarGroup<ShellPage>(
        key: ModuleIds.administration,
        title: 'Administration',
        icon: Icons.admin_panel_settings_outlined,
        children: [
          ShellPage.adminUsers,
          ShellPage.adminRoles,
          ShellPage.adminComplianceLegal,
          ShellPage.adminCompanyProfile,
          ShellPage.adminBranches,
          ShellPage.adminAuditLogs,
        ],
      ),
    ];
  }

  List<SidebarGroup<ShellPage>> _computeSidebarGroups() {
    final allGroups = _allSidebarGroups;
    final filtered = <SidebarGroup<ShellPage>>[];

    for (var group in allGroups) {
      if (!_isSidebarGroupModuleEnabled(group.key)) {
        continue;
      }

      final allowedChildren = group.children
          .where((page) => _canViewPage(page))
          .toList();

      if (allowedChildren.isNotEmpty) {
        filtered.add(
          SidebarGroup(
            key: group.key,
            title: group.title,
            icon: group.icon,
            children: allowedChildren,
          ),
        );
      }
    }

    return filtered;
  }

  String? _moduleIdForSidebarGroup(String groupKey) {
    // New setup uses ModuleIds.xxx exactly for keys
    return groupKey;
  }

  bool _isModuleEnabled(String moduleId) {
    if (isAdminOrManager) {
      return true;
    }

    final moduleAccess = ModuleAccessProvider.maybeOf(context, listen: false);

    if (moduleAccess == null) {
      return true;
    }

    return moduleAccess.isModuleEnabled(moduleId);
  }

  bool _isSidebarGroupModuleEnabled(String groupKey) {
    final moduleId = _moduleIdForSidebarGroup(groupKey);
    if (moduleId == null) return true;

    return _isModuleEnabled(moduleId);
  }

  void _noAccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission to access this module'),
      ),
    );
  }

  void _selectPage(ShellPage page) {
    if (!_canViewPage(page)) {
      _noAccess();
      return;
    }

    setState(() => activePage = page);
  }

  bool _isImplementedPage(ShellPage page) {
    // Note: The new placeholder pages are INTENTIONALLY excluded here
    // so they trigger your beautiful "Module Overview" fallback UI.
    switch (page) {
      case ShellPage.dashboard:
      case ShellPage.platformTenantModules:
      case ShellPage.salesInquiries:
      case ShellPage.crmCustomers:
      case ShellPage.customerPoList:
      case ShellPage.projectsList:
      case ShellPage.purchaseVendors:
      case ShellPage.purchaseVendorOffers:
      case ShellPage.purchasePurchaseOrders:
      case ShellPage.purchaseLedger:
      case ShellPage.purchaseOrders:
      case ShellPage.purchaseGrn:
      case ShellPage.inventoryProducts:
      case ShellPage.inventoryStockSummary:
      case ShellPage.inventoryStockIn:
      case ShellPage.inventoryStockOut:
      case ShellPage.inventoryWarehouse:
      case ShellPage.inventoryLowStock:
      case ShellPage.inventoryRawMaterialStock:
      case ShellPage.inventoryMaterialInward:
      case ShellPage.inventoryMaterialIssue:
      case ShellPage.dispatchReady:
      case ShellPage.dispatchChallans:
      case ShellPage.dispatchShipmentTracking:
      case ShellPage.dispatchDelivered:
      case ShellPage.salesQuotations:
      case ShellPage.adminUsers:
      case ShellPage.adminModules:
      case ShellPage.adminInventoryProfile:
      case ShellPage.adminComplianceLegal:
      case ShellPage.settingsGeneral:
      case ShellPage.financeProforma:
      case ShellPage.financeTaxInvoice:
      case ShellPage.financeTaxInvoiceCreate:
      case ShellPage.financeExportInvoiceCreate:
      case ShellPage.financePaymentsReceived:
      case ShellPage.financeOutstanding:
      case ShellPage.productionItems:
      case ShellPage.productionProcesses:
      case ShellPage.productionWorkCenters:
      case ShellPage.productionBom:
      case ShellPage.productionBoq:
      case ShellPage.productionJobCards:
      case ShellPage.productionContractorJobs:
      case ShellPage.productionGalvanizing:
      case ShellPage.productionInspections:
      case ShellPage.productionEntries:
      case ShellPage.hrHome:
      case ShellPage.reportsSales:
        return true;
      default:
        return false;
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  String _activeSectionTitle() {
    if (activePage == ShellPage.dashboard) return 'Dashboard';
    if (activePage == ShellPage.settingsGeneral) return 'Settings';
    if (activePage == ShellPage.financeTaxInvoiceCreate) {
      return 'Finance • Create Tax Invoice';
    }
    if (activePage == ShellPage.financeExportInvoiceCreate) {
      return 'Finance • Create Export Invoice';
    }

    if (_currentSidebarGroups.any(
      (group) => group.children.contains(activePage),
    )) {
      final group = _currentSidebarGroups.firstWhere(
        (g) => g.children.contains(activePage),
      );
      return '${group.title} • ${activePage.label}';
    }

    return activePage.label;
  }

  String _resolvedEmployeeName() {
    final fromDisplayName = (widget.userDisplayName ?? '').trim();
    if (fromDisplayName.isNotEmpty) return fromDisplayName;

    final emailPrefix = widget.userEmail.split('@').first.trim();
    if (emailPrefix.isNotEmpty) return emailPrefix;

    return 'User';
  }

  String _dashboardWelcomeText() {
    if (isAdminOrManager) {
      return 'Welcome ${widget.companyName}';
    }
    return 'Welcome ${_resolvedEmployeeName()}';
  }

  Widget _buildTopHeader() {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: zBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _activeSectionTitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: zText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockedWorkspaceBody() {
    return Scaffold(
      backgroundColor: zCanvasBg,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: zBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person_outlined, size: 32, color: zMuted),
                const SizedBox(height: 12),
                const Text(
                  'Workspace access unavailable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: zText,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your company workspace access is inactive, archived, or deleted. Please contact your administrator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: zMuted,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Do not block ERP shell while industry/company metadata is loading.
    // Shell must open first; industry-dependent data can hydrate later.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userUid)
          .snapshots(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting &&
            !userSnap.hasData) {
          return const Scaffold(
            backgroundColor: zCanvasBg,
            body: Center(child: CircularProgressIndicator(color: zBlue)),
          );
        }

        final companyUserData = userSnap.data?.data() ?? <String, dynamic>{};

        _currentRole = (companyUserData['role'] ?? widget.role)
            .toString()
            .trim()
            .toLowerCase();

        final dynamic rawPermissions = companyUserData['permissions'];
        _currentPermissions = rawPermissions is Map
            ? Map<String, dynamic>.from(rawPermissions)
            : widget.permissions;

        final bool isDeleted = companyUserData['isDeleted'] == true;
        final bool isActive = companyUserData.containsKey('isActive')
            ? companyUserData['isActive'] == true
            : true;

        if (isDeleted || !isActive) {
          return _blockedWorkspaceBody();
        }

        _currentSidebarGroups = _computeSidebarGroups();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_canViewPage(activePage)) {
            setState(() => activePage = ShellPage.dashboard);
          }
        });

        return Scaffold(
          backgroundColor: zCanvasBg,
          body: Row(
            children: [
              ShellSidebar(
                activePage: activePage,
                sidebarGroups: _currentSidebarGroups,
                canInquiries: canInquiries,
                companyId: widget.companyId,
                userUid: widget.userUid,
                currentRole: _currentRole,
                showSettings: _isModuleEnabled(ModuleIds.settings),
                onSelectPage: _selectPage,
                onLogout: _logout,
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(),
                    Expanded(child: _buildActiveBody()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveBody() {
    if (!_canViewPage(activePage)) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: DashboardScreen(
          companyId: widget.companyId,
          userName: widget.companyName,
          currentUserId: widget.userUid,
          permissions: _currentPermissions,
          role: _currentRole,
        ),
      );
    }

    switch (activePage) {
      case ShellPage.dashboard:
      case ShellPage.platformTenantModules:
        return DashboardScreen(
          companyId: widget.companyId,
          userName: widget.companyName,
          currentUserId: widget.userUid,
          permissions: _currentPermissions,
          role: _currentRole,
        );

      case ShellPage.salesInquiries:
        return const Padding(
          padding: EdgeInsets.all(10),
          child: ScreensInquiryList(),
        );

      case ShellPage.service:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ServiceHomeScreen(),
        );

      case ShellPage.crmCustomers:
        return const Padding(
          padding: EdgeInsets.all(10),
          child: ScreensCustomerList(),
        );

      case ShellPage.inventoryProducts:
        return Padding(
          padding: EdgeInsets.all(10),
          child: RawMaterialMasterScreen(tenantId: widget.companyId),
        );

      case ShellPage.inventoryStockSummary:
      case ShellPage.inventoryWarehouse:
      case ShellPage.inventoryRawMaterialStock:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: FabricationRawMaterialStockScreen(tenantId: widget.companyId),
        );

      case ShellPage.inventoryStockIn:
      case ShellPage.inventoryMaterialInward:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: FabricationMaterialInwardScreen(tenantId: widget.companyId),
        );

      case ShellPage.inventoryStockOut:
      case ShellPage.inventoryMaterialIssue:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: FabricationMaterialIssueScreen(tenantId: widget.companyId),
        );

      case ShellPage.inventoryLowStock:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: RawMaterialLowStockScreen(tenantId: widget.companyId),
        );

      case ShellPage.purchaseVendors:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: MirajVendorMasterScreen(
            tenantId: widget.companyId,
            currentUserUid: widget.userUid,
          ),
        );

      case ShellPage.purchaseOrders:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: FabricationPurchaseBillScreen(tenantId: widget.companyId),
        );

      case ShellPage.purchaseVendorOffers:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: MirajVendorOfferScreen(
            tenantId: widget.companyId,
            currentUserUid: widget.userUid,
          ),
        );

      case ShellPage.purchasePurchaseOrders:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: MirajVendorPurchaseOrderScreen(tenantId: widget.companyId),
        );

      case ShellPage.purchaseLedger:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: MirajVendorLedgerScreen(tenantId: widget.companyId),
        );

      case ShellPage.purchaseGrn:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: FabricationMaterialInwardScreen(
            tenantId: widget.companyId,
            purchaseView: true,
          ),
        );

      case ShellPage.dispatchReady:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: DispatchListScreen(
            tenantId: widget.companyId,
            mode: DispatchListMode.ready,
          ),
        );

      case ShellPage.dispatchChallans:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: DispatchListScreen(
            tenantId: widget.companyId,
            mode: DispatchListMode.challans,
          ),
        );

      case ShellPage.dispatchShipmentTracking:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: DispatchListScreen(
            tenantId: widget.companyId,
            mode: DispatchListMode.shipmentTracking,
          ),
        );

      case ShellPage.dispatchDelivered:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: DispatchListScreen(
            tenantId: widget.companyId,
            mode: DispatchListMode.delivered,
          ),
        );

      case ShellPage.salesQuotations:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ScreensQuotationList(
            userId: (widget.userUid.hashCode).abs() % 1000000,
          ),
        );

      case ShellPage.salesOrders:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: SalesOrderListScreen(companyId: widget.companyId),
        );

      case ShellPage.adminUsers:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ScreenUserManagement(
            companyId: widget.companyId,
            currentUid: widget.userUid,
          ),
        );

      case ShellPage.adminModules:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ScreenCompanyModules(
            companyId: widget.companyId,
            companyName: widget.companyName,
          ),
        );

      case ShellPage.adminInventoryProfile:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ScreenInventoryProfileSettings(
            companyId: widget.companyId,
            companyName: widget.companyName,
          ),
        );

      case ShellPage.adminComplianceLegal:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ComplianceLegalScreen(
            tenantId: widget.companyId,
            currentUserUid: widget.userUid,
            currentUserEmail: widget.userEmail,
            currentRole: _currentRole,
          ),
        );

      case ShellPage.financeProforma:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ProformaListScreen(companyId: widget.companyId),
        );

      case ShellPage.financeTaxInvoice:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: InvoiceListScreen(
            companyId: widget.companyId,
            userUid: widget.userUid,
            onSelectTax: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaxInvoiceScreen(
                    companyId: widget.companyId,
                    userUid: widget.userUid,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              );
            },
            onSelectExport: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExportInvoiceScreen(
                    companyId: widget.companyId,
                    userUid: widget.userUid,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              );
            },
          ),
        );

      case ShellPage.financePaymentsReceived:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: PaymentsListScreen(
            companyId: widget.companyId,
            userUid: widget.userUid,
          ),
        );

      case ShellPage.financeOutstanding:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: OutstandingScreen(
            companyId: widget.companyId,
            userUid: widget.userUid,
          ),
        );

      case ShellPage.productionItems:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ProductionItemListScreen(tenantId: widget.companyId),
        );

      case ShellPage.productionProcesses:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ProcessListScreen(tenantId: widget.companyId),
        );

      case ShellPage.productionWorkCenters:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: WorkCenterListScreen(tenantId: widget.companyId),
        );

      case ShellPage.productionBom:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: BomListScreen(tenantId: widget.companyId),
        );

      case ShellPage.productionBoq:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: BoqListScreen(tenantId: widget.companyId),
        );

      case ShellPage.productionJobCards:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: JobCardListScreen(tenantId: widget.companyId),
        );

      case ShellPage.productionContractorJobs:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: ContractorJobListScreen(tenantId: widget.companyId),
        );

      case ShellPage.productionGalvanizing:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: GalvanizingJobListScreen(tenantId: widget.companyId),
        );

      case ShellPage.productionInspections:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: InspectionListScreen(tenantId: widget.companyId),
        );

      case ShellPage.productionEntries:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ProductionEntryListScreen(tenantId: widget.companyId),
        );

      case ShellPage.hrHome:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: HrHomeScreen(tenantId: widget.companyId),
        );

      case ShellPage.reportsSales:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: SalesReportScreen(companyId: widget.companyId),
        );

      case ShellPage.settingsGeneral:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ScreenSettingsHome(
            companyId: widget.companyId,
            companyName: widget.companyName,
            role: _currentRole,
            userEmail: widget.userEmail,
            permissions: _currentPermissions,
            industry: _resolvedIndustry,
            onOpenUsers: () => _selectPage(ShellPage.adminUsers),
            onOpenCompanyProfile: () =>
                _selectPage(ShellPage.adminCompanyProfile),
            onOpenAuditLogs: () => _selectPage(ShellPage.adminAuditLogs),
          ),
        );

      case ShellPage.customerPoList:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: CustomerPoListScreen(companyId: widget.companyId),
        );

      case ShellPage.projectsList:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ProjectsListScreen(companyId: widget.companyId),
        );

      default:
        // This acts as the fallback landing page for Customer PO, Projects, etc.
        return Padding(
          padding: const EdgeInsets.all(10),
          child: _moduleLandingPage(activePage),
        );
    }
  }

  Widget _moduleLandingPage(ShellPage page) {
    final bool implemented = _isImplementedPage(page);
    final bool allowed = _canViewPage(page);

    String sectionName = 'Workspace';
    for (final group in _currentSidebarGroups) {
      if (group.children.contains(page)) {
        sectionName = group.title;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          page.label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: zText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$sectionName module inside ${widget.companyName}',
          style: const TextStyle(
            color: zMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _overviewCard(
                title: 'Module Status',
                value: allowed
                    ? (implemented ? 'Ready to open' : 'Planned')
                    : 'Restricted',
                icon: allowed
                    ? (implemented
                          ? Icons.check_circle_outline
                          : Icons.construction_outlined)
                    : Icons.lock_outline,
                tint: allowed
                    ? (implemented ? zSuccessSoft : zBlueSoft)
                    : const Color(0xFFFFF1F2),
                iconColor: allowed
                    ? (implemented ? zSuccess : zBlue)
                    : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _overviewCard(
                title: 'Action',
                value: implemented ? 'Open module' : 'Coming soon',
                icon: implemented
                    ? Icons.open_in_new
                    : Icons.rocket_launch_outlined,
                tint: zOrangeSoft,
                iconColor: zOrange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _overviewCard(
                title: 'Department',
                value: sectionName,
                icon: Icons.apartment_outlined,
                tint: zPurpleSoft,
                iconColor: zPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: zBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Module Overview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: zText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _moduleDescription(page),
                        style: const TextStyle(
                          color: zMuted,
                          height: 1.55,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _moduleTags(
                          page,
                        ).map((e) => _moduleTag(e)).toList(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: _quickPanel(
                        title: 'Recommended Subfeatures',
                        lines: _moduleRecommendations(page),
                        icon: Icons.auto_awesome_outlined,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _quickPanel(
                        title: 'Implementation Note',
                        lines: [
                          implemented
                              ? 'This module is already connected to an existing screen.'
                              : 'This is a safe placeholder module.',
                          'You can connect Firestore collections later.',
                          'No current feature is removed from your app.',
                        ],
                        icon: Icons.build_circle_outlined,
                      ),
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

  List<String> _moduleTags(ShellPage page) {
    switch (page) {
      case ShellPage.salesInquiries:
        return ['Leads', 'Assignments', 'Follow-ups', 'Pipeline'];
      case ShellPage.salesQuotations:
        return ['Price', 'Proposal', 'Customer', 'Approval'];
      case ShellPage.crmCustomers:
        return ['Accounts', 'Contacts', 'History', 'Relationships'];
      case ShellPage.inventoryProducts:
        return ['Master', 'Grade', 'Length', 'Stock'];
      case ShellPage.adminUsers:
        return ['Access', 'Permissions', 'Roles', 'Team'];
      case ShellPage.settingsGeneral:
        return ['Company', 'Security', 'Users', 'Audit'];
      default:
        return ['Professional', 'AMAN', 'Production', 'ERP'];
    }
  }

  String _moduleDescription(ShellPage page) {
    switch (page) {
      case ShellPage.salesInquiries:
        return 'Track leads and incoming inquiries, assign them to team members, monitor status, and prepare them for quotation and order conversion.';
      case ShellPage.salesQuotations:
        return 'Generate and manage quotations for your sales team. This connects your existing quotation workflow into the AMAN Infra ERP module structure.';
      case ShellPage.crmCustomers:
        return 'Manage customer master records, view customer relationship data, and keep your CRM organized around actual business accounts.';
      case ShellPage.inventoryProducts:
        return 'Manage raw material master data used by inward, issue, and transaction-backed stock summaries.';
      case ShellPage.adminUsers:
        return 'Handle user management, role-based access, and team structure for each company workspace.';
      case ShellPage.settingsGeneral:
        return 'Manage workspace preferences, company controls, users, security, notifications, integrations, and audit-related options from one professional ERP settings hub.';
      default:
        return 'This module is part of the dedicated AMAN Infra ERP workspace and keeps its records inside the AMAN company data boundary.';
    }
  }

  List<String> _moduleRecommendations(ShellPage page) {
    switch (page) {
      case ShellPage.purchaseOrders:
        return [
          'Vendor selection',
          'Supplier bill number',
          'Bill amount',
          'Bill status',
          'Linked GRN entry',
        ];
      case ShellPage.inventoryStockSummary:
        return [
          'Current stock by item',
          'Warehouse balance',
          'Low stock alerts',
          'Stock movement history',
        ];
      case ShellPage.dispatchChallans:
        return [
          'Dispatch challan no.',
          'Vehicle details',
          'Packing list',
          'Delivery status',
        ];
      case ShellPage.financeOutstanding:
        return [
          'Customer ageing',
          'Pending payments',
          'Reminder schedule',
          'Collection dashboard',
        ];
      case ShellPage.adminCompanyProfile:
        return [
          'GST / VAT details',
          'Address and branches',
          'Branding',
          'Default numbering formats',
        ];
      case ShellPage.settingsGeneral:
        return [
          'Company profile',
          'Users and permissions',
          'Security and access',
          'Audit and integrations',
        ];
      default:
        return [
          'Summary card',
          'Search and filters',
          'List screen',
          'Add / edit form',
        ];
    }
  }

  Widget _moduleTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: zBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: zText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _overviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color tint,
    required Color iconColor,
  }) {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: zMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: zText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickPanel({
    required String title,
    required List<String> lines,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
              Icon(icon, color: zBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: zText,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: lines
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.circle, size: 5, color: zBlue),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e,
                              style: const TextStyle(
                                color: zMuted,
                                fontSize: 11.5,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _homeDashboardLive() {
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = dateOnly(DateTime.now());

    final canShowInquiryDashboard = canInquiries;
    final welcomeText = _dashboardWelcomeText();

    final inquiryStream = canShowInquiryDashboard
        ? FirebaseFirestore.instance
              .collection('companies')
              .doc(widget.companyId)
              .collection('inquiries')
              .where('assignedToUid', isEqualTo: widget.userUid)
              .snapshots()
        : null;

    if (!canShowInquiryDashboard) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            welcomeText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: zText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _KpiBox(
                  title: 'Sales Modules',
                  value: '6',
                  icon: Icons.trending_up_outlined,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _KpiBox(
                  title: 'CRM Modules',
                  value: '4',
                  icon: Icons.people_outline,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _KpiBox(
                  title: 'Inventory Modules',
                  value: '6',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _KpiBox(
                  title: 'Reports',
                  value: '5',
                  icon: Icons.assessment_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: const [
                Expanded(
                  child: _Panel(
                    title: 'Workspace Structure',
                    emptyText: 'AMAN Infra ERP modules are ready in sidebar',
                    emptyIcon: Icons.dashboard_customize_outlined,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _Panel(
                    title: 'Next Build Suggestion',
                    emptyText:
                        'Start with Follow-ups, Stock Summary and Vendors',
                    emptyIcon: Icons.rocket_launch_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: inquiryStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Dashboard error: ${snap.error}'));
        }

        int total = 0;
        int openDeals = 0;
        int untouched = 0;
        int followupsToday = 0;

        if (snap.hasData) {
          final docs = snap.data!.docs;
          total = docs.length;

          for (final doc in docs) {
            final data = doc.data();

            final status = (data['status'] ?? '').toString().trim();
            final lastNote = (data['lastFollowUpNote'] ?? '').toString().trim();

            if (status == 'Open' || status == 'Quotation Pending') {
              openDeals++;
            }

            if (status == 'Open' && lastNote.isEmpty) {
              untouched++;
            }

            final next = data['nextFollowUpDate'];
            if (next is Timestamp) {
              final dt = dateOnly(next.toDate());
              if (dt == today) {
                followupsToday++;
              }
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              welcomeText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: zText,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _KpiBox(
                    title: 'Open Deals',
                    value: '$openDeals',
                    icon: Icons.folder_open_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiBox(
                    title: 'Untouched',
                    value: '$untouched',
                    icon: Icons.mark_email_unread_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiBox(
                    title: 'Follow-ups Today',
                    value: '$followupsToday',
                    icon: Icons.event_repeat_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiBox(
                    title: 'My Inquiries',
                    value: '$total',
                    icon: Icons.insights_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: const [
                  Expanded(
                    child: _Panel(
                      title: 'My Open Tasks',
                      emptyText: 'No open tasks',
                      emptyIcon: Icons.task_alt,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _Panel(
                      title: 'My Meetings',
                      emptyText: 'No meetings scheduled',
                      emptyIcon: Icons.event_available,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _KpiBox({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: zMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: zMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: zText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String emptyText;
  final IconData emptyIcon;

  const _Panel({
    required this.title,
    required this.emptyText,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: zBorder)),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: zText,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(emptyIcon, color: zMuted, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: zMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
