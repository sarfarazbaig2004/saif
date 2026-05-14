import 'package:QUIK/core/modules/models/app_module.dart';

class ModuleIds {
  static const String dashboard = 'dashboard';
  static const String crm = 'crm';
  static const String sales = 'sales';
  static const String customerPo = 'customer_po';
  static const String projectsJobCards = 'projects_job_cards';
  static const String planningScheduling = 'planning_scheduling';
  static const String engineering = 'engineering';
  static const String inventoryStore = 'inventory_store';
  static const String purchase = 'purchase';
  static const String production = 'production';
  static const String contractorJobWork = 'contractor_job_work';
  static const String galvanizing = 'galvanizing';
  static const String inspectionQa = 'inspection_qa';
  static const String dispatch = 'dispatch';
  static const String hrAdmin = 'hr_admin';
  static const String finance = 'finance';
  static const String reports = 'reports';
  static const String administration = 'administration';
  static const String settings = 'settings';

  // Temporary compatibility for old files.
  // Remove these after replacing old references in the project.
  static const String inventory = inventoryStore;
  static const String hr = hrAdmin;
  static const String iot = 'iot';

  const ModuleIds._();
}

class ModuleRegistry {
  static const List<AppModule> modules = [
    AppModule(
      id: ModuleIds.dashboard,
      displayName: 'Dashboard',
      baseRoute: '/dashboard',
      iconKey: 'dashboard',
      sortOrder: 10,
    ),
    AppModule(
      id: ModuleIds.crm,
      displayName: 'CRM',
      baseRoute: '/crm',
      iconKey: 'groups',
      sortOrder: 20,
    ),
    AppModule(
      id: ModuleIds.sales,
      displayName: 'Sales',
      baseRoute: '/sales',
      iconKey: 'point_of_sale',
      sortOrder: 30,
    ),
    AppModule(
      id: ModuleIds.customerPo,
      displayName: 'Customer PO',
      baseRoute: '/customer-po',
      iconKey: 'description',
      sortOrder: 40,
    ),
    AppModule(
      id: ModuleIds.projectsJobCards,
      displayName: 'Projects & Job Cards',
      baseRoute: '/projects-job-cards',
      iconKey: 'work',
      sortOrder: 50,
    ),
    AppModule(
      id: ModuleIds.planningScheduling,
      displayName: 'Planning & Scheduling',
      baseRoute: '/planning-scheduling',
      iconKey: 'event_note',
      sortOrder: 60,
    ),
    AppModule(
      id: ModuleIds.engineering,
      displayName: 'Engineering',
      baseRoute: '/engineering',
      iconKey: 'architecture',
      sortOrder: 70,
    ),
    AppModule(
      id: ModuleIds.inventoryStore,
      displayName: 'Inventory & Store',
      baseRoute: '/inventory-store',
      iconKey: 'inventory_2',
      sortOrder: 80,
    ),
    AppModule(
      id: ModuleIds.purchase,
      displayName: 'Purchase',
      baseRoute: '/purchase',
      iconKey: 'shopping_cart',
      sortOrder: 90,
    ),
    AppModule(
      id: ModuleIds.production,
      displayName: 'Production',
      baseRoute: '/production',
      iconKey: 'precision_manufacturing',
      sortOrder: 100,
    ),
    AppModule(
      id: ModuleIds.contractorJobWork,
      displayName: 'Contractor Job Work',
      baseRoute: '/contractor-job-work',
      iconKey: 'engineering',
      sortOrder: 110,
    ),
    AppModule(
      id: ModuleIds.galvanizing,
      displayName: 'Galvanizing',
      baseRoute: '/galvanizing',
      iconKey: 'factory',
      sortOrder: 120,
    ),
    AppModule(
      id: ModuleIds.inspectionQa,
      displayName: 'Inspection / QA',
      baseRoute: '/inspection-qa',
      iconKey: 'fact_check',
      sortOrder: 130,
    ),
    AppModule(
      id: ModuleIds.dispatch,
      displayName: 'Dispatch',
      baseRoute: '/dispatch',
      iconKey: 'local_shipping',
      sortOrder: 140,
    ),
    AppModule(
      id: ModuleIds.hrAdmin,
      displayName: 'HR & Administration',
      baseRoute: '/hr-admin',
      iconKey: 'badge',
      sortOrder: 150,
    ),
    AppModule(
      id: ModuleIds.finance,
      displayName: 'Finance',
      baseRoute: '/finance',
      iconKey: 'account_balance_wallet',
      sortOrder: 160,
    ),
    AppModule(
      id: ModuleIds.reports,
      displayName: 'Reports',
      baseRoute: '/reports',
      iconKey: 'bar_chart',
      sortOrder: 170,
    ),
    AppModule(
      id: ModuleIds.administration,
      displayName: 'Administration',
      baseRoute: '/administration',
      iconKey: 'admin_panel_settings',
      sortOrder: 180,
    ),
    AppModule(
      id: ModuleIds.settings,
      displayName: 'Settings',
      baseRoute: '/settings',
      iconKey: 'settings',
      sortOrder: 190,
    ),
  ];

  static final Map<String, AppModule> byId = {
    for (final module in modules) module.id: module,
  };

  static List<AppModule> get activeModules {
    final active = modules.where((module) => module.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return active;
  }

  static AppModule? findById(String moduleId) => byId[moduleId];

  const ModuleRegistry._();
}