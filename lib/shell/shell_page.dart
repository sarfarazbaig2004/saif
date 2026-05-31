import 'package:flutter/material.dart';

enum ShellPage {
  dashboard,
  platformTenantModules,

  // CRM
  crmCustomers,
  crmContacts,
  crmVisits,
  crmCommunication,

  // Sales
  salesInquiries,
  salesQuotations,
  salesOrders,
  service,
  salesFollowUps,
  salesTasks,
  salesMeetings,

  // Customer PO
  customerPoList,

  // Projects & Job Cards
  projectsList,

  // Planning & Scheduling
  planningDashboard,
  schedulingCalendar,

  // Engineering
  engineeringDrawings,
  engineeringBomBoq,

  // Purchase
  purchaseVendors,
  purchaseVendorOffers,
  purchasePurchaseOrders,
  purchaseOrders,
  purchaseGrn,
  purchaseLedger,
  purchaseRequisitions,

  // Inventory
  inventoryProducts,
  inventoryMaterialMaster,
  inventoryStockSummary,
  inventoryStockIn,
  inventoryStockOut,
  inventoryWarehouse,
  inventoryLowStock,
  inventoryRawMaterialStock,
  inventoryMaterialInward,
  inventoryMaterialIssue,

  // Dispatch
  dispatchReady,
  dispatchChallans,
  dispatchShipmentTracking,
  dispatchDelivered,

  // Production
  productionItems,
  productionProcesses,
  productionWorkCenters,
  productionBom,
  productionBoq,
  productionJobCards,
  productionContractorJobs,
  productionGalvanizing,
  productionInspections,
  productionEntries,
  productionMaterialRequirements,

  // HR
  hrHome,

  // Finance
  financeProforma,
  financeTaxInvoice,
  financeTaxInvoiceCreate,
  financeExportInvoiceCreate,
  financePaymentsReceived,
  financeOutstanding,
  financeExpenses,

  // Reports
  reportsSales,
  reportsInquiry,
  reportsCustomer,
  reportsProduct,
  reportsPayment,

  // Admin
  adminUsers,
  adminRoles,
  adminModules,
  adminInventoryProfile,
  adminComplianceLegal,
  adminCompanyProfile,
  adminBranches,
  adminAuditLogs,
  adminJoinRequests,

  // Settings
  settingsGeneral,
}

extension ShellPageX on ShellPage {
  String get label {
    switch (this) {
      case ShellPage.dashboard:
        return 'Dashboard';
      case ShellPage.platformTenantModules:
        return 'AMAN Modules';

      case ShellPage.salesInquiries:
        return 'Inquiries';
      case ShellPage.salesQuotations:
        return 'Quotations';
      case ShellPage.salesOrders:
        return 'Sales Orders';
      case ShellPage.service:
        return 'Service';
      case ShellPage.salesFollowUps:
        return 'Follow-ups';
      case ShellPage.salesTasks:
        return 'Tasks';
      case ShellPage.salesMeetings:
        return 'Meetings';

      case ShellPage.crmCustomers:
        return 'Customers';
      case ShellPage.crmContacts:
        return 'Contacts';
      case ShellPage.crmVisits:
        return 'Customer Visits';
      case ShellPage.crmCommunication:
        return 'Communication History';

      case ShellPage.customerPoList:
        return 'Customer POs';
      case ShellPage.projectsList:
        return 'Projects';
      case ShellPage.planningDashboard:
        return 'Planning Board';
      case ShellPage.schedulingCalendar:
        return 'Master Schedule';
      case ShellPage.engineeringDrawings:
        return 'Drawings & Specs';
      case ShellPage.engineeringBomBoq:
        return 'BOM & BOQ';

      case ShellPage.purchaseVendors:
        return 'Vendors';
      case ShellPage.purchaseVendorOffers:
        return 'Vendor Offers';
      case ShellPage.purchasePurchaseOrders:
        return 'Purchase Orders';
      case ShellPage.purchaseOrders:
        return 'Purchase Bills';
      case ShellPage.purchaseGrn:
        return 'GRN / Material Receipt';
      case ShellPage.purchaseLedger:
        return 'Vendor Ledger';
      case ShellPage.purchaseRequisitions:
        return 'Purchase Requisitions';

      case ShellPage.inventoryProducts:
        return 'Raw Materials';
      case ShellPage.inventoryMaterialMaster:
        return 'Material Master';
      case ShellPage.inventoryStockSummary:
        return 'Raw Material Stock Summary';
      case ShellPage.inventoryStockIn:
        return 'Raw Material Inward';
      case ShellPage.inventoryStockOut:
        return 'Raw Material Issue';
      case ShellPage.inventoryWarehouse:
        return 'Warehouse';
      case ShellPage.inventoryLowStock:
        return 'Low Stock Alerts';
      case ShellPage.inventoryRawMaterialStock:
        return 'Raw Material Stock Summary';
      case ShellPage.inventoryMaterialInward:
        return 'Raw Material Inward';
      case ShellPage.inventoryMaterialIssue:
        return 'Raw Material Issue';

      case ShellPage.dispatchReady:
        return 'Ready for Dispatch';
      case ShellPage.dispatchChallans:
        return 'Dispatch Challans';
      case ShellPage.dispatchShipmentTracking:
        return 'Shipment Tracking';
      case ShellPage.dispatchDelivered:
        return 'Delivered Orders';

      case ShellPage.productionItems:
        return 'Items';
      case ShellPage.productionProcesses:
        return 'Processes';
      case ShellPage.productionWorkCenters:
        return 'Work Centers';
      case ShellPage.productionBom:
        return 'BOM';
      case ShellPage.productionBoq:
        return 'BOQ';
      case ShellPage.productionJobCards:
        return 'Job Cards';
      case ShellPage.productionContractorJobs:
        return 'Contractor Job Work';
      case ShellPage.productionGalvanizing:
        return 'Galvanizing';
      case ShellPage.productionInspections:
        return 'Inspections';
      case ShellPage.productionEntries:
        return 'Production Entries';
      case ShellPage.productionMaterialRequirements:
        return 'Material Requirements';

      case ShellPage.hrHome:
        return 'HR';

      case ShellPage.financeProforma:
        return 'Proforma Invoice';
      case ShellPage.financeTaxInvoice:
        return 'Invoice';
      case ShellPage.financeTaxInvoiceCreate:
        return 'Create Tax Invoice';
      case ShellPage.financeExportInvoiceCreate:
        return 'Create Export Invoice';
      case ShellPage.financePaymentsReceived:
        return 'Payments Received';
      case ShellPage.financeOutstanding:
        return 'Outstanding';
      case ShellPage.financeExpenses:
        return 'Expense Entries';

      case ShellPage.reportsSales:
        return 'Sales Report';
      case ShellPage.reportsInquiry:
        return 'Inquiry Report';
      case ShellPage.reportsCustomer:
        return 'Customer Report';
      case ShellPage.reportsProduct:
        return 'Product Report';
      case ShellPage.reportsPayment:
        return 'Payment Report';

      case ShellPage.adminUsers:
        return 'Users';
      case ShellPage.adminRoles:
        return 'Roles & Permissions';
      case ShellPage.adminModules:
        return 'Company Modules';
      case ShellPage.adminInventoryProfile:
        return 'Inventory Profile';
      case ShellPage.adminComplianceLegal:
        return 'Compliance & Legal';
      case ShellPage.adminCompanyProfile:
        return 'Company Profile';
      case ShellPage.adminBranches:
        return 'Branches';
      case ShellPage.adminAuditLogs:
        return 'Audit Logs';
      case ShellPage.adminJoinRequests:
        return 'Join Requests';

      case ShellPage.settingsGeneral:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case ShellPage.dashboard:
        return Icons.home_outlined;
      case ShellPage.platformTenantModules:
        return Icons.admin_panel_settings_outlined;
      case ShellPage.salesInquiries:
        return Icons.campaign_outlined;
      case ShellPage.salesQuotations:
        return Icons.receipt_long_outlined;
      case ShellPage.salesOrders:
        return Icons.shopping_bag_outlined;
      case ShellPage.service:
        return Icons.build_outlined;
      case ShellPage.salesFollowUps:
        return Icons.event_repeat_outlined;
      case ShellPage.salesTasks:
        return Icons.task_alt_outlined;
      case ShellPage.salesMeetings:
        return Icons.groups_outlined;
      case ShellPage.crmCustomers:
        return Icons.people_outline;
      case ShellPage.crmContacts:
        return Icons.contact_phone_outlined;
      case ShellPage.crmVisits:
        return Icons.location_on_outlined;
      case ShellPage.crmCommunication:
        return Icons.chat_bubble_outline;

      case ShellPage.customerPoList:
        return Icons.request_quote_outlined;
      case ShellPage.projectsList:
        return Icons.account_tree_outlined;
      case ShellPage.planningDashboard:
        return Icons.schema_outlined;
      case ShellPage.schedulingCalendar:
        return Icons.calendar_month_outlined;
      case ShellPage.engineeringDrawings:
        return Icons.architecture_outlined;
      case ShellPage.engineeringBomBoq:
        return Icons.calculate_outlined;

      case ShellPage.purchaseVendors:
        return Icons.business_outlined;
      case ShellPage.purchaseVendorOffers:
        return Icons.attach_file_outlined;
      case ShellPage.purchasePurchaseOrders:
        return Icons.shopping_cart_checkout_outlined;
      case ShellPage.purchaseOrders:
        return Icons.shopping_cart_outlined;
      case ShellPage.purchaseGrn:
        return Icons.inventory_outlined;
      case ShellPage.purchaseLedger:
        return Icons.menu_book_outlined;
      case ShellPage.purchaseRequisitions:
        return Icons.assignment_returned_outlined;
      case ShellPage.inventoryProducts:
        return Icons.inventory_2_outlined;
      case ShellPage.inventoryMaterialMaster:
        return Icons.category_outlined;
      case ShellPage.inventoryStockSummary:
        return Icons.bar_chart_outlined;
      case ShellPage.inventoryStockIn:
        return Icons.move_to_inbox_outlined;
      case ShellPage.inventoryStockOut:
        return Icons.outbox_outlined;
      case ShellPage.inventoryWarehouse:
        return Icons.warehouse_outlined;
      case ShellPage.inventoryLowStock:
        return Icons.warning_amber_outlined;
      case ShellPage.inventoryRawMaterialStock:
        return Icons.category_outlined;
      case ShellPage.inventoryMaterialInward:
        return Icons.move_to_inbox_outlined;
      case ShellPage.inventoryMaterialIssue:
        return Icons.outbox_outlined;
      case ShellPage.dispatchReady:
        return Icons.inventory_2_outlined;
      case ShellPage.dispatchChallans:
        return Icons.local_shipping_outlined;
      case ShellPage.dispatchShipmentTracking:
        return Icons.route_outlined;
      case ShellPage.dispatchDelivered:
        return Icons.done_all_outlined;

      case ShellPage.productionItems:
        return Icons.widgets_outlined;
      case ShellPage.productionProcesses:
        return Icons.account_tree_outlined;
      case ShellPage.productionWorkCenters:
        return Icons.precision_manufacturing_outlined;
      case ShellPage.productionBom:
        return Icons.schema_outlined;
      case ShellPage.productionBoq:
        return Icons.calculate_outlined;
      case ShellPage.productionJobCards:
        return Icons.assignment_outlined;
      case ShellPage.productionContractorJobs:
        return Icons.engineering_outlined;
      case ShellPage.productionGalvanizing:
        return Icons.hot_tub_outlined;
      case ShellPage.productionInspections:
        return Icons.fact_check_outlined;
      case ShellPage.productionEntries:
        return Icons.factory_outlined;
      case ShellPage.productionMaterialRequirements:
        return Icons.inventory_2_outlined;
      case ShellPage.hrHome:
        return Icons.badge_outlined;
      case ShellPage.financeProforma:
        return Icons.request_quote_outlined;
      case ShellPage.financeTaxInvoice:
        return Icons.description_outlined;
      case ShellPage.financeTaxInvoiceCreate:
        return Icons.receipt_long_outlined;
      case ShellPage.financeExportInvoiceCreate:
        return Icons.public_outlined;
      case ShellPage.financePaymentsReceived:
        return Icons.payments_outlined;
      case ShellPage.financeOutstanding:
        return Icons.account_balance_wallet_outlined;
      case ShellPage.financeExpenses:
        return Icons.receipt_outlined;
      case ShellPage.reportsSales:
        return Icons.show_chart_outlined;
      case ShellPage.reportsInquiry:
        return Icons.insights_outlined;
      case ShellPage.reportsCustomer:
        return Icons.people_alt_outlined;
      case ShellPage.reportsProduct:
        return Icons.widgets_outlined;
      case ShellPage.reportsPayment:
        return Icons.pie_chart_outline;
      case ShellPage.adminUsers:
        return Icons.manage_accounts_outlined;
      case ShellPage.adminRoles:
        return Icons.admin_panel_settings_outlined;
      case ShellPage.adminModules:
        return Icons.widgets_outlined;
      case ShellPage.adminInventoryProfile:
        return Icons.tune_outlined;
      case ShellPage.adminComplianceLegal:
        return Icons.gavel_outlined;
      case ShellPage.adminCompanyProfile:
        return Icons.apartment_outlined;
      case ShellPage.adminBranches:
        return Icons.account_tree_outlined;
      case ShellPage.adminAuditLogs:
        return Icons.fact_check_outlined;
      case ShellPage.adminJoinRequests:
        return Icons.how_to_reg_outlined;
      case ShellPage.settingsGeneral:
        return Icons.settings_outlined;
    }
  }
}
