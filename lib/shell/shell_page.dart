enum ShellPage {
  dashboard,

  platformTenantModules,

  salesInquiries,
  salesQuotations,
  salesOrders,
  service,
  salesFollowUps,
  salesTasks,
  salesMeetings,

  crmCustomers,
  crmContacts,
  crmVisits,
  crmCommunication,

  purchaseVendors,
  purchaseVendorOffers,
  purchasePurchaseOrders,
  purchaseOrders,
  purchaseGrn,
  purchaseLedger,

  inventoryProducts,
  inventoryStockSummary,
  inventoryStockIn,
  inventoryStockOut,
  inventoryWarehouse,
  inventoryLowStock,
  inventoryRawMaterialStock,
  inventoryMaterialInward,
  inventoryMaterialIssue,

  dispatchReady,
  dispatchChallans,
  dispatchShipmentTracking,
  dispatchDelivered,

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

  hrHome,

  financeProforma,
  financeTaxInvoice,
  financeTaxInvoiceCreate,
  financeExportInvoiceCreate,
  financePaymentsReceived,
  financeOutstanding,
  financeExpenses,

  reportsSales,
  reportsInquiry,
  reportsCustomer,
  reportsProduct,
  reportsPayment,

  adminUsers,
  adminRoles,
  adminModules,
  adminInventoryProfile,
  adminComplianceLegal,
  adminCompanyProfile,
  adminBranches,
  adminAuditLogs,

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

      case ShellPage.inventoryProducts:
        return 'Raw Materials';
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

      case ShellPage.settingsGeneral:
        return 'Settings';
    }
  }
}
