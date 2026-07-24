import 'package:QUIK/core/modules/module_registry.dart';

/// A stable permission action. [id] is persisted; [displayName] is UI-only.
class PermissionActionDefinition {
  final String id;
  final String displayName;
  final String description;
  final bool requiresView;

  const PermissionActionDefinition({
    required this.id,
    required this.displayName,
    required this.description,
    this.requiresView = true,
  });
}

class PermissionSubmoduleDefinition {
  final String moduleId;
  final String id;
  final String displayName;
  final String description;
  final int order;
  final List<PermissionActionDefinition> actions;
  final List<String> routeIds;
  final bool needsReview;

  const PermissionSubmoduleDefinition({
    required this.moduleId,
    required this.id,
    required this.displayName,
    required this.description,
    required this.order,
    required this.actions,
    this.routeIds = const [],
    this.needsReview = false,
  });

  String keyFor(String actionId) => '$moduleId.$id.$actionId';
  String get viewKey => keyFor(PermissionActionIds.view);
}

class PermissionModuleDefinition {
  final String id;
  final String displayName;
  final String description;
  final int order;
  final String iconKey;
  final List<PermissionSubmoduleDefinition> submodules;

  const PermissionModuleDefinition({
    required this.id,
    required this.displayName,
    required this.description,
    required this.order,
    required this.iconKey,
    required this.submodules,
  });
}

class PermissionActionIds {
  static const view = 'view';
  static const create = 'create';
  static const edit = 'edit';
  static const delete = 'delete';
  static const export = 'export';
  static const downloadPdf = 'download_pdf';
  static const printPdf = 'print_pdf';
  static const approve = 'approve';
  static const reject = 'reject';
  static const cancel = 'cancel';

  const PermissionActionIds._();
}

class PermissionKeys {
  static const dashboardView = 'dashboard.overview.view';

  static const crmCustomersView = 'crm.customers.view';
  static const crmCustomersCreate = 'crm.customers.create';
  static const crmCustomersEdit = 'crm.customers.edit';
  static const crmCustomersDelete = 'crm.customers.delete';

  static const salesInquiriesView = 'sales.inquiries.view';
  static const salesInquiriesCreate = 'sales.inquiries.create';
  static const salesInquiriesEdit = 'sales.inquiries.edit';
  static const salesInquiriesDelete = 'sales.inquiries.delete';
  static const salesInquiriesAssign = 'sales.inquiries.assign';
  static const salesInquiriesConvert = 'sales.inquiries.convert_to_quotation';
  static const salesInquiriesCreateCosting =
      'sales.inquiries.create_costing_sheet';

  static const salesQuotationsView = 'sales.quotations.view';
  static const salesQuotationsCreate = 'sales.quotations.create';
  static const salesQuotationsEdit = 'sales.quotations.edit';
  static const salesQuotationsDelete = 'sales.quotations.delete';
  static const salesQuotationsApprove = 'sales.quotations.approve';
  static const salesQuotationsReject = 'sales.quotations.reject';
  static const salesQuotationsConvert =
      'sales.quotations.convert_to_customer_po';
  static const salesQuotationsResetConversion =
      'sales.quotations.reset_conversion';
  static const salesQuotationsRevise = 'sales.quotations.create_revision';
  static const salesQuotationsCancel = 'sales.quotations.cancel';
  static const salesQuotationsDownloadPdf = 'sales.quotations.download_pdf';

  static const purchaseOrdersView = 'purchase.purchase_orders.view';
  static const purchaseOrdersCreate = 'purchase.purchase_orders.create';
  static const purchaseOrdersEdit = 'purchase.purchase_orders.edit';
  static const purchaseOrdersApprove = 'purchase.purchase_orders.approve';
  static const purchaseOrdersCancel = 'purchase.purchase_orders.cancel';
  static const purchaseOrdersDownloadPdf =
      'purchase.purchase_orders.download_pdf';

  static const dispatchReadyView = 'dispatch.ready.view';
  static const dispatchReadyCreate = 'dispatch.ready.create';
  static const dispatchTrackingView = 'dispatch.tracking.view';
  static const dispatchDeliveredView = 'dispatch.delivered.view';

  static const adminUsersView = 'administration.users.view';
  static const adminUsersInvite = 'administration.users.invite';
  static const adminUsersEdit = 'administration.users.edit';
  static const adminUsersActivateDeactivate =
      'administration.users.activate_deactivate';
  static const adminUsersArchiveRestore =
      'administration.users.archive_restore';
  static const adminUsersManagePermissions =
      'administration.users.manage_permissions';
  static const adminUsersCancelInvite = 'administration.users.cancel_invite';

  const PermissionKeys._();
}

const _view = PermissionActionDefinition(
  id: 'view',
  displayName: 'View',
  description: 'Open and read this area.',
  requiresView: false,
);

PermissionActionDefinition _action(String id, String name, String description) {
  return PermissionActionDefinition(
    id: id,
    displayName: name,
    description: description,
  );
}

List<PermissionActionDefinition> _crud({bool delete = true}) => [
  _view,
  _action('create', 'Create', 'Create a new record.'),
  _action('edit', 'Edit', 'Change an existing record.'),
  if (delete) _action('delete', 'Delete', 'Delete an existing record.'),
];

PermissionSubmoduleDefinition _sub({
  required String moduleId,
  required String id,
  required String name,
  required int order,
  required List<PermissionActionDefinition> actions,
  List<String> routes = const [],
  String? description,
  bool needsReview = false,
}) {
  return PermissionSubmoduleDefinition(
    moduleId: moduleId,
    id: id,
    displayName: name,
    description: description ?? 'Access $name.',
    order: order,
    actions: actions,
    routeIds: routes,
    needsReview: needsReview,
  );
}

/// The only catalogue used by invite/edit UI and runtime permission checks.
class AmanPermissionCatalogue {
  static final List<PermissionModuleDefinition> modules = [
    PermissionModuleDefinition(
      id: ModuleIds.dashboard,
      displayName: 'Dashboard',
      description: 'Workspace dashboard and operational summaries.',
      order: 10,
      iconKey: 'dashboard',
      submodules: [
        _sub(
          moduleId: ModuleIds.dashboard,
          id: 'overview',
          name: 'Dashboard',
          order: 10,
          actions: [_view],
          routes: ['dashboard'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.crm,
      displayName: 'CRM',
      description: 'Customers and nested relationship records.',
      order: 20,
      iconKey: 'groups',
      submodules: [
        _sub(
          moduleId: ModuleIds.crm,
          id: 'customers',
          name: 'Customers',
          order: 10,
          actions: _crud(),
          routes: ['crmCustomers'],
        ),
        _sub(
          moduleId: ModuleIds.crm,
          id: 'contacts',
          name: 'Contacts',
          order: 20,
          actions: _crud(),
          routes: ['crmContacts'],
        ),
        _sub(
          moduleId: ModuleIds.crm,
          id: 'addresses',
          name: 'Addresses',
          order: 30,
          actions: _crud(),
        ),
        _sub(
          moduleId: ModuleIds.crm,
          id: 'follow_ups',
          name: 'Customer Follow-ups',
          order: 40,
          actions: _crud(),
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.sales,
      displayName: 'Sales',
      description: 'Inquiry, quotation, order, and sales activity workflows.',
      order: 30,
      iconKey: 'point_of_sale',
      submodules: [
        _sub(
          moduleId: ModuleIds.sales,
          id: 'inquiries',
          name: 'Inquiries',
          order: 10,
          routes: ['salesInquiries'],
          actions: [
            ..._crud(),
            _action('assign', 'Assign', 'Assign an inquiry to an employee.'),
            _action(
              'convert_to_quotation',
              'Convert to Quotation',
              'Create a quotation from an inquiry.',
            ),
            _action(
              'create_costing_sheet',
              'Create Costing Sheet',
              'Create a costing sheet from an inquiry.',
            ),
          ],
        ),
        _sub(
          moduleId: ModuleIds.sales,
          id: 'quotations',
          name: 'Quotations',
          order: 20,
          routes: ['salesQuotations'],
          actions: [
            ..._crud(),
            _action('approve', 'Approve', 'Approve a quotation.'),
            _action('reject', 'Reject', 'Reject a quotation.'),
            _action(
              'convert_to_customer_po',
              'Convert to Customer PO',
              'Convert an approved quotation to a customer PO.',
            ),
            _action(
              'reset_conversion',
              'Reset Conversion',
              'Reset the linked customer PO conversion.',
            ),
            _action(
              'create_revision',
              'Create Revision',
              'Create a quotation revision.',
            ),
            _action('cancel', 'Cancel', 'Cancel a quotation.'),
            _action(
              'download_pdf',
              'Download PDF',
              'Generate or download the quotation PDF.',
            ),
          ],
        ),
        _sub(
          moduleId: ModuleIds.sales,
          id: 'sales_orders',
          name: 'Sales Orders',
          order: 30,
          routes: ['salesOrders'],
          actions: [
            ..._crud(),
            _action('approve', 'Approve', 'Approve a sales order.'),
            _action('reject', 'Reject', 'Reject a sales order.'),
            _action(
              'update_dispatch',
              'Update Dispatch',
              'Update sales-order dispatch status.',
            ),
            _action('cancel', 'Cancel', 'Cancel a sales order.'),
            _action(
              'upload_po',
              'Upload PO',
              'Upload or replace the customer PO.',
            ),
            _action(
              'create_proforma',
              'Create Proforma',
              'Create a proforma invoice.',
            ),
            _action(
              'download_pdf',
              'Download PDF',
              'Generate the sales-order PDF.',
            ),
          ],
        ),
        _sub(
          moduleId: ModuleIds.sales,
          id: 'follow_ups',
          name: 'Follow-ups',
          order: 40,
          actions: [_view],
          routes: ['salesFollowUps'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.sales,
          id: 'tasks',
          name: 'Tasks',
          order: 50,
          actions: [_view],
          routes: ['salesTasks'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.sales,
          id: 'meetings',
          name: 'Meetings',
          order: 60,
          actions: [_view],
          routes: ['salesMeetings'],
          needsReview: true,
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.customerPo,
      displayName: 'Customer PO',
      description: 'Customer purchase-order workflow.',
      order: 40,
      iconKey: 'description',
      submodules: [
        _sub(
          moduleId: ModuleIds.customerPo,
          id: 'orders',
          name: 'Customer POs',
          order: 10,
          routes: ['customerPoList'],
          actions: [
            ..._crud(),
            _action('amend', 'Amend', 'Create an amendment.'),
            _action(
              'duplicate',
              'Duplicate',
              'Duplicate an existing customer PO.',
            ),
            _action(
              'upload_pdf',
              'Upload PDF',
              'Upload the customer PO document.',
            ),
            _action(
              'download_pdf',
              'Download PDF',
              'Download the customer PO document.',
            ),
            _action(
              'create_job_card',
              'Create Job Card',
              'Create a job card from a customer PO.',
            ),
          ],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.projectsJobCards,
      displayName: 'Projects & Job Cards',
      description: 'Project overview and manufacturing job cards.',
      order: 50,
      iconKey: 'work',
      submodules: [
        _sub(
          moduleId: ModuleIds.projectsJobCards,
          id: 'projects',
          name: 'Projects',
          order: 10,
          actions: [_view],
          routes: ['projectsList'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.projectsJobCards,
          id: 'job_cards',
          name: 'Job Cards',
          order: 20,
          routes: ['productionJobCards'],
          actions: [
            _view,
            _action('create', 'Create', 'Create a job card.'),
            _action('edit', 'Edit', 'Edit a job card.'),
            _action(
              'update_status',
              'Update Status',
              'Change job-card status.',
            ),
            _action(
              'check_inventory',
              'Check Inventory',
              'Check material availability.',
            ),
            _action(
              'generate_material_requirement',
              'Generate Material Requirement',
              'Generate material requirements.',
            ),
          ],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.planningScheduling,
      displayName: 'Planning & Scheduling',
      description: 'Planning and scheduling placeholders.',
      order: 60,
      iconKey: 'event_note',
      submodules: [
        _sub(
          moduleId: ModuleIds.planningScheduling,
          id: 'planning_board',
          name: 'Planning Board',
          order: 10,
          actions: [_view],
          routes: ['planningDashboard'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.planningScheduling,
          id: 'master_schedule',
          name: 'Master Schedule',
          order: 20,
          actions: [_view],
          routes: ['schedulingCalendar'],
          needsReview: true,
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.engineering,
      displayName: 'Engineering',
      description: 'Drawings, specifications, BOM, and BOQ engineering work.',
      order: 70,
      iconKey: 'architecture',
      submodules: [
        _sub(
          moduleId: ModuleIds.engineering,
          id: 'drawings',
          name: 'Drawings & Specs',
          order: 10,
          actions: [_view],
          routes: ['engineeringDrawings'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.engineering,
          id: 'bom_boq',
          name: 'BOM & BOQ',
          order: 20,
          actions: [
            ..._crud(),
            _action(
              'create_revision',
              'Create Revision',
              'Create an engineering BOM revision.',
            ),
          ],
          routes: ['engineeringBomBoq'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.inventoryStore,
      displayName: 'Inventory & Store',
      description: 'Material masters, stock, inward, issue, and alerts.',
      order: 80,
      iconKey: 'inventory_2',
      submodules: [
        _sub(
          moduleId: ModuleIds.inventoryStore,
          id: 'material_master',
          name: 'Item / Material Master',
          order: 10,
          actions: _crud(),
          routes: ['inventoryProducts', 'inventoryMaterialMaster'],
        ),
        _sub(
          moduleId: ModuleIds.inventoryStore,
          id: 'stock_summary',
          name: 'Stock Summary',
          order: 20,
          actions: [_view],
          routes: [
            'inventoryStockSummary',
            'inventoryWarehouse',
            'inventoryRawMaterialStock',
          ],
        ),
        _sub(
          moduleId: ModuleIds.inventoryStore,
          id: 'material_inward',
          name: 'Material Inward',
          order: 30,
          actions: [
            _view,
            _action('create', 'Create Inward', 'Record received material.'),
          ],
          routes: ['inventoryStockIn', 'inventoryMaterialInward'],
        ),
        _sub(
          moduleId: ModuleIds.inventoryStore,
          id: 'material_issue',
          name: 'Material Issue',
          order: 40,
          actions: [
            _view,
            _action('create', 'Create Issue', 'Issue raw material.'),
          ],
          routes: ['inventoryStockOut', 'inventoryMaterialIssue'],
        ),
        _sub(
          moduleId: ModuleIds.inventoryStore,
          id: 'low_stock',
          name: 'Low Stock Alerts',
          order: 50,
          actions: [_view],
          routes: ['inventoryLowStock'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.purchase,
      displayName: 'Purchase',
      description: 'Vendors, requisitions, offers, orders, bills, and GRN.',
      order: 90,
      iconKey: 'shopping_cart',
      submodules: [
        _sub(
          moduleId: ModuleIds.purchase,
          id: 'vendors',
          name: 'Vendors',
          order: 10,
          actions: [
            ..._crud(),
            _action(
              'manage_contacts',
              'Manage Contacts',
              'Manage vendor contacts.',
            ),
          ],
          routes: ['purchaseVendors'],
        ),
        _sub(
          moduleId: ModuleIds.purchase,
          id: 'requisitions',
          name: 'Purchase Requisitions',
          order: 20,
          actions: [
            _view,
            _action(
              'create_from_material_requirement',
              'Create from MR',
              'Create a purchase requisition from material requirements.',
            ),
          ],
          routes: ['purchaseRequisitions'],
        ),
        _sub(
          moduleId: ModuleIds.purchase,
          id: 'vendor_offers',
          name: 'Vendor Offers',
          order: 30,
          actions: [
            ..._crud(),
            _action(
              'convert_to_purchase_order',
              'Convert to PO',
              'Convert an offer to a purchase order.',
            ),
          ],
          routes: ['purchaseVendorOffers'],
        ),
        _sub(
          moduleId: ModuleIds.purchase,
          id: 'purchase_orders',
          name: 'Purchase Orders',
          order: 40,
          actions: [
            _view,
            _action('create', 'Create', 'Create a purchase order.'),
            _action('edit', 'Edit', 'Edit a purchase order.'),
            _action('approve', 'Approve', 'Approve a purchase order.'),
            _action('cancel', 'Cancel', 'Cancel a purchase order.'),
            _action('download_pdf', 'PDF', 'Generate the purchase-order PDF.'),
          ],
          routes: ['purchasePurchaseOrders'],
        ),
        _sub(
          moduleId: ModuleIds.purchase,
          id: 'purchase_bills',
          name: 'Purchase Bills',
          order: 50,
          actions: _crud(delete: false),
          routes: ['purchaseOrders'],
        ),
        _sub(
          moduleId: ModuleIds.purchase,
          id: 'grn',
          name: 'GRN / Material Receipt',
          order: 60,
          actions: [
            _view,
            _action('create', 'Create GRN', 'Create a goods receipt.'),
          ],
          routes: ['purchaseGrn'],
        ),
        _sub(
          moduleId: ModuleIds.purchase,
          id: 'vendor_ledger',
          name: 'Vendor Ledger',
          order: 70,
          actions: [_view],
          routes: ['purchaseLedger'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.production,
      displayName: 'Production',
      description: 'Production masters, BOM/BOQ, requirements, and entries.',
      order: 100,
      iconKey: 'precision_manufacturing',
      submodules: [
        _sub(
          moduleId: ModuleIds.production,
          id: 'items',
          name: 'Items',
          order: 10,
          actions: _crud(delete: false),
          routes: ['productionItems'],
        ),
        _sub(
          moduleId: ModuleIds.production,
          id: 'processes',
          name: 'Processes',
          order: 20,
          actions: _crud(delete: false),
          routes: ['productionProcesses'],
        ),
        _sub(
          moduleId: ModuleIds.production,
          id: 'work_centers',
          name: 'Work Centers',
          order: 30,
          actions: _crud(delete: false),
          routes: ['productionWorkCenters'],
        ),
        _sub(
          moduleId: ModuleIds.production,
          id: 'bom',
          name: 'BOM',
          order: 40,
          actions: _crud(delete: false),
          routes: ['productionBom'],
        ),
        _sub(
          moduleId: ModuleIds.production,
          id: 'boq',
          name: 'BOQ',
          order: 50,
          actions: [
            ..._crud(delete: false),
            _action('print_pdf', 'Print / PDF', 'Print or generate a BOQ PDF.'),
          ],
          routes: ['productionBoq'],
        ),
        _sub(
          moduleId: ModuleIds.production,
          id: 'material_requirements',
          name: 'Material Requirements',
          order: 60,
          actions: [
            _view,
            _action(
              'create_purchase_requisition',
              'Create PR',
              'Create a purchase requisition.',
            ),
          ],
          routes: ['productionMaterialRequirements'],
        ),
        _sub(
          moduleId: ModuleIds.production,
          id: 'entries',
          name: 'Production Entries',
          order: 70,
          actions: [
            ..._crud(delete: false),
            _action(
              'print_pdf',
              'Print / PDF',
              'Print the production register.',
            ),
          ],
          routes: ['productionEntries'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.contractorJobWork,
      displayName: 'Contractor Job Work',
      description: 'Issue and receive contractor work.',
      order: 110,
      iconKey: 'engineering',
      submodules: [
        _sub(
          moduleId: ModuleIds.contractorJobWork,
          id: 'jobs',
          name: 'Contractor Jobs',
          order: 10,
          actions: [
            _view,
            _action('issue', 'Issue', 'Issue work to a contractor.'),
            _action('receive', 'Receive', 'Receive contractor work.'),
            _action(
              'update_status',
              'Update Status',
              'Update contractor-job status.',
            ),
          ],
          routes: ['productionContractorJobs'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.galvanizing,
      displayName: 'Galvanizing',
      description: 'Send and receive galvanizing jobs.',
      order: 120,
      iconKey: 'factory',
      submodules: [
        _sub(
          moduleId: ModuleIds.galvanizing,
          id: 'jobs',
          name: 'Galvanizing Jobs',
          order: 10,
          actions: [
            _view,
            _action('send', 'Send', 'Send work to the galvanizing vendor.'),
            _action('receive', 'Receive', 'Receive galvanized work.'),
            _action('update_status', 'Update Status', 'Update job status.'),
            _action('close', 'Close', 'Close a galvanizing job.'),
          ],
          routes: ['productionGalvanizing'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.inspectionQa,
      displayName: 'Inspection / QA',
      description: 'Inspection results and dispatch clearance.',
      order: 130,
      iconKey: 'fact_check',
      submodules: [
        _sub(
          moduleId: ModuleIds.inspectionQa,
          id: 'inspections',
          name: 'Inspections',
          order: 10,
          actions: [
            _view,
            _action('create', 'Create', 'Create an inspection entry.'),
            _action(
              'update_status',
              'Update Status',
              'Update inspection status.',
            ),
            _action(
              'approve',
              'Approve',
              'Approve inspected quantity or status.',
            ),
            _action('reject', 'Reject', 'Reject inspected quantity or status.'),
            _action(
              'clear_dispatch',
              'Clear Dispatch',
              'Approve dispatch clearance.',
            ),
          ],
          routes: ['productionInspections'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.dispatch,
      displayName: 'Dispatch',
      description: 'Dispatch preparation, challans, tracking, and delivery.',
      order: 140,
      iconKey: 'local_shipping',
      submodules: [
        _sub(
          moduleId: ModuleIds.dispatch,
          id: 'ready',
          name: 'Ready for Dispatch',
          order: 10,
          actions: [
            _view,
            _action('create', 'Create Dispatch', 'Create a dispatch record.'),
          ],
          routes: ['dispatchReady'],
        ),
        _sub(
          moduleId: ModuleIds.dispatch,
          id: 'challans',
          name: 'Dispatch Challans',
          order: 20,
          actions: [
            _view,
            _action('create', 'Create', 'Create a dispatch challan.'),
          ],
          routes: ['dispatchChallans'],
        ),
        _sub(
          moduleId: ModuleIds.dispatch,
          id: 'tracking',
          name: 'Shipment Tracking',
          order: 30,
          actions: [
            _view,
            _action(
              'update_status',
              'Update Status',
              'Update shipment tracking status.',
            ),
          ],
          routes: ['dispatchShipmentTracking'],
        ),
        _sub(
          moduleId: ModuleIds.dispatch,
          id: 'delivered',
          name: 'Delivered Orders',
          order: 40,
          actions: [
            _view,
            _action(
              'mark_delivered',
              'Mark Delivered',
              'Mark a dispatch as delivered.',
            ),
          ],
          routes: ['dispatchDelivered'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.hrAdmin,
      displayName: 'HR',
      description: 'Employees, attendance, and wage entries.',
      order: 150,
      iconKey: 'badge',
      submodules: [
        _sub(
          moduleId: ModuleIds.hrAdmin,
          id: 'employees',
          name: 'Employees',
          order: 10,
          actions: [
            _view,
            _action('create', 'Add Employee', 'Add an HR employee record.'),
          ],
          routes: ['hrHome'],
        ),
        _sub(
          moduleId: ModuleIds.hrAdmin,
          id: 'attendance',
          name: 'Attendance',
          order: 20,
          actions: [
            _view,
            _action('mark', 'Mark Attendance', 'Record employee attendance.'),
          ],
          routes: ['hrHome'],
        ),
        _sub(
          moduleId: ModuleIds.hrAdmin,
          id: 'wages',
          name: 'Wages',
          order: 30,
          actions: [
            _view,
            _action('create', 'Add Wage', 'Create a wage entry.'),
          ],
          routes: ['hrHome'],
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.finance,
      displayName: 'Finance',
      description: 'Proforma, invoicing, receipts, outstanding, and expenses.',
      order: 160,
      iconKey: 'account_balance_wallet',
      submodules: [
        _sub(
          moduleId: ModuleIds.finance,
          id: 'proforma',
          name: 'Proforma Invoice',
          order: 10,
          actions: [
            ..._crud(),
            _action('approve', 'Approve', 'Approve a proforma.'),
            _action('reject', 'Reject', 'Reject a proforma.'),
            _action('cancel', 'Cancel', 'Cancel a proforma.'),
            _action(
              'create_revision',
              'Create Revision',
              'Create a proforma revision.',
            ),
            _action(
              'convert_to_invoice',
              'Convert to Invoice',
              'Convert a proforma to an invoice.',
            ),
            _action('download_pdf', 'Download PDF', 'Generate a proforma PDF.'),
          ],
          routes: ['financeProforma'],
        ),
        _sub(
          moduleId: ModuleIds.finance,
          id: 'invoices',
          name: 'Invoices',
          order: 20,
          actions: [
            _view,
            _action('create', 'Create', 'Create an invoice.'),
            _action('edit', 'Edit', 'Edit an invoice.'),
            _action('cancel', 'Cancel', 'Cancel an invoice.'),
            _action(
              'record_payment',
              'Record Payment',
              'Record payment against an invoice.',
            ),
            _action(
              'preview_pdf',
              'Preview PDF',
              'Preview the invoice document.',
            ),
          ],
          routes: [
            'financeTaxInvoice',
            'financeTaxInvoiceCreate',
            'financeExportInvoiceCreate',
          ],
        ),
        _sub(
          moduleId: ModuleIds.finance,
          id: 'payments_received',
          name: 'Payments Received',
          order: 30,
          actions: _crud(),
          routes: ['financePaymentsReceived'],
        ),
        _sub(
          moduleId: ModuleIds.finance,
          id: 'outstanding',
          name: 'Outstanding',
          order: 40,
          actions: [
            _view,
            _action(
              'record_payment',
              'Record Payment',
              'Record payment for an outstanding invoice.',
            ),
            _action(
              'preview_invoice',
              'Preview Invoice',
              'Preview the related invoice.',
            ),
          ],
          routes: ['financeOutstanding'],
        ),
        _sub(
          moduleId: ModuleIds.finance,
          id: 'expenses',
          name: 'Expense Entries',
          order: 50,
          actions: [_view],
          routes: ['financeExpenses'],
          needsReview: true,
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.reports,
      displayName: 'Reports',
      description: 'Operational reports and exports.',
      order: 170,
      iconKey: 'bar_chart',
      submodules: [
        _sub(
          moduleId: ModuleIds.reports,
          id: 'sales',
          name: 'Sales Report',
          order: 10,
          actions: [
            _view,
            _action('export', 'Export', 'Export the sales report.'),
          ],
          routes: ['reportsSales'],
        ),
        _sub(
          moduleId: ModuleIds.reports,
          id: 'inquiry',
          name: 'Inquiry Report',
          order: 20,
          actions: [_view],
          routes: ['reportsInquiry'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.reports,
          id: 'customer',
          name: 'Customer Report',
          order: 30,
          actions: [_view],
          routes: ['reportsCustomer'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.reports,
          id: 'product',
          name: 'Product Report',
          order: 40,
          actions: [_view],
          routes: ['reportsProduct'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.reports,
          id: 'payment',
          name: 'Payment Report',
          order: 50,
          actions: [_view],
          routes: ['reportsPayment'],
          needsReview: true,
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.administration,
      displayName: 'Administration',
      description: 'Users, compliance, company controls, and audit.',
      order: 180,
      iconKey: 'admin_panel_settings',
      submodules: [
        _sub(
          moduleId: ModuleIds.administration,
          id: 'users',
          name: 'Users',
          order: 10,
          actions: [
            _view,
            _action('invite', 'Invite', 'Create an employee invite.'),
            _action('edit', 'Edit', 'Edit a user profile.'),
            _action(
              'activate_deactivate',
              'Activate / Deactivate',
              'Change active status.',
            ),
            _action(
              'archive_restore',
              'Archive / Restore',
              'Archive or restore a user.',
            ),
            _action(
              'manage_permissions',
              'Manage Permissions',
              'Change direct permissions.',
            ),
            _action(
              'cancel_invite',
              'Cancel Invite',
              'Cancel a pending invite.',
            ),
            _action('export', 'Export', 'Export the user list.'),
          ],
          routes: ['adminUsers'],
        ),
        _sub(
          moduleId: ModuleIds.administration,
          id: 'roles',
          name: 'Roles & Permissions',
          order: 20,
          actions: [_view],
          routes: ['adminRoles'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.administration,
          id: 'compliance',
          name: 'Compliance & Legal',
          order: 30,
          actions: [
            _view,
            _action('upload', 'Upload', 'Upload a compliance document.'),
            _action('edit', 'Edit Metadata', 'Edit document metadata.'),
            _action(
              'create_revision',
              'New Revision',
              'Create a document revision.',
            ),
            _action(
              'approve_revision',
              'Approve Revision',
              'Approve a QMS revision.',
            ),
            _action('archive', 'Archive', 'Archive or obsolete a document.'),
            _action('delete', 'Delete', 'Delete a compliance document.'),
            _action('download', 'Download', 'Download a document.'),
          ],
          routes: ['adminComplianceLegal'],
        ),
        _sub(
          moduleId: ModuleIds.administration,
          id: 'company_profile',
          name: 'Company Profile',
          order: 40,
          actions: [_view],
          routes: ['adminCompanyProfile'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.administration,
          id: 'branches',
          name: 'Branches',
          order: 50,
          actions: [_view],
          routes: ['adminBranches'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.administration,
          id: 'audit_logs',
          name: 'Audit Logs',
          order: 60,
          actions: [_view],
          routes: ['adminAuditLogs'],
          needsReview: true,
        ),
        _sub(
          moduleId: ModuleIds.administration,
          id: 'join_requests',
          name: 'Join Requests',
          order: 70,
          actions: [_view],
          routes: ['adminJoinRequests'],
          needsReview: true,
        ),
      ],
    ),
    PermissionModuleDefinition(
      id: ModuleIds.settings,
      displayName: 'Settings',
      description: 'Workspace settings and supported masters.',
      order: 190,
      iconKey: 'settings',
      submodules: [
        _sub(
          moduleId: ModuleIds.settings,
          id: 'workspace',
          name: 'Workspace Settings',
          order: 10,
          actions: [_view, _action('edit', 'Edit', 'Edit workspace settings.')],
          routes: ['settingsGeneral'],
        ),
        _sub(
          moduleId: ModuleIds.settings,
          id: 'factories',
          name: 'Factory Master',
          order: 20,
          actions: _crud(delete: false),
        ),
        _sub(
          moduleId: ModuleIds.settings,
          id: 'verticals',
          name: 'Vertical Master',
          order: 30,
          actions: _crud(delete: false),
        ),
        _sub(
          moduleId: ModuleIds.settings,
          id: 'coatings',
          name: 'Coating Master',
          order: 40,
          actions: _crud(delete: false),
        ),
        _sub(
          moduleId: ModuleIds.settings,
          id: 'company_profile',
          name: 'Company Profile & Banking',
          order: 50,
          actions: [
            _view,
            _action('edit', 'Edit', 'Edit company and banking details.'),
          ],
        ),
        _sub(
          moduleId: ModuleIds.settings,
          id: 'document_layout',
          name: 'Document Layout',
          order: 60,
          actions: [_view, _action('edit', 'Edit', 'Edit document layout.')],
        ),
      ],
    ),
  ];

  static final List<PermissionSubmoduleDefinition> submodules = [
    for (final module in modules) ...module.submodules,
  ];

  static final List<String> orderedKeys = [
    for (final module in modules)
      for (final submodule in module.submodules)
        for (final action in submodule.actions) submodule.keyFor(action.id),
  ];

  static final Set<String> knownKeys = orderedKeys.toSet();

  static final Map<String, PermissionModuleDefinition> moduleById = {
    for (final module in modules) module.id: module,
  };

  static final Map<String, PermissionSubmoduleDefinition> submoduleByPrefix = {
    for (final submodule in submodules)
      '${submodule.moduleId}.${submodule.id}': submodule,
  };

  static final Map<String, String> routeViewPermission = {
    for (final submodule in submodules)
      for (final routeId in submodule.routeIds) routeId: submodule.viewKey,
  };

  static PermissionSubmoduleDefinition? submoduleForKey(String key) {
    final parts = key.split('.');
    if (parts.length != 3) return null;
    return submoduleByPrefix['${parts[0]}.${parts[1]}'];
  }

  static String? viewKeyFor(String key) => submoduleForKey(key)?.viewKey;

  const AmanPermissionCatalogue._();
}
