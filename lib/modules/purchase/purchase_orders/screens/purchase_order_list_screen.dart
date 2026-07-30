// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:QUIK/core/permissions/permission_catalogue.dart';
import 'package:QUIK/core/permissions/permission_scope.dart';
import 'package:QUIK/modules/inventory/item_master/screens_item_master_list.dart';
import 'package:QUIK/modules/purchase/purchase_orders/models/purchase_order_model.dart';
import 'package:QUIK/modules/purchase/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:QUIK/modules/purchase/purchase_orders/services/purchase_order_pdf_generator.dart';
import 'package:QUIK/modules/purchase/purchase_orders/services/purchase_order_upload_service.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  final String tenantId;
  final String currentUserUid;

  const PurchaseOrderListScreen({
    super.key,
    required this.tenantId,
    required this.currentUserUid,
  });

  @override
  State<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  String _searchText = '';
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  PurchaseOrderRepository get _repository =>
      PurchaseOrderRepository(tenantId: widget.tenantId);

  Future<void> _openForm({PurchaseOrderModel? order}) async {
    final permission = order == null
        ? PermissionKeys.purchaseOrdersCreate
        : PermissionKeys.purchaseOrdersEdit;
    if (!PermissionScope.require(context, permission)) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseOrderFormScreen(
          tenantId: widget.tenantId,
          currentUserUid: widget.currentUserUid,
          initialOrder: order,
        ),
      ),
    );
  }

  Future<void> _showPdf(PurchaseOrderModel order) async {
    if (!PermissionScope.require(
      context,
      PermissionKeys.purchaseOrdersDownloadPdf,
    )) {
      return;
    }
    try {
      final companyData = await PurchaseOrderPdfGenerator.fetchCompanyData(
        tenantId: widget.tenantId,
      );
      final bytes = await PurchaseOrderPdfGenerator.buildPdf(
        order: order,
        companyData: companyData,
      );
      await Printing.layoutPdf(
        name: '${order.poNumber}.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    }
  }

  Future<void> _updateStatus(PurchaseOrderModel order, String status) async {
    final permission = status == PurchaseOrderModel.statusApproved
        ? PermissionKeys.purchaseOrdersApprove
        : PermissionKeys.purchaseOrdersCancel;
    if (!PermissionScope.require(context, permission)) return;
    await _repository.updateStatus(
      purchaseOrderId: order.id,
      status: status,
      approvedByUid: widget.currentUserUid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final evaluator = PermissionScope.of(context);
    final canCreate = evaluator.hasPermission(
      PermissionKeys.purchaseOrdersCreate,
    );
    final canEdit = evaluator.hasPermission(PermissionKeys.purchaseOrdersEdit);
    final canPdf = evaluator.hasPermission(
      PermissionKeys.purchaseOrdersDownloadPdf,
    );
    final canApprove = evaluator.hasPermission(
      PermissionKeys.purchaseOrdersApprove,
    );
    final canCancel = evaluator.hasPermission(
      PermissionKeys.purchaseOrdersCancel,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: StreamBuilder<List<PurchaseOrderModel>>(
        stream: _repository.watchPurchaseOrders(),
        builder: (context, snapshot) {
          final orders = _filter(snapshot.data ?? const []);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(onNew: canCreate ? () => _openForm() : null),
              const SizedBox(height: 12),
              _FilterBar(
                searchText: _searchText,
                statusFilter: _statusFilter,
                typeFilter: _typeFilter,
                onSearchChanged: (value) => setState(() => _searchText = value),
                onStatusChanged: (value) =>
                    setState(() => _statusFilter = value ?? 'all'),
                onTypeChanged: (value) =>
                    setState(() => _typeFilter = value ?? 'all'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child:
                    snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : orders.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _PurchaseOrderCard(
                            order: order,
                            onEdit: canEdit
                                ? () => _openForm(order: order)
                                : null,
                            onPdf: canPdf ? () => _showPdf(order) : null,
                            onApprove:
                                canApprove &&
                                    order.status ==
                                        PurchaseOrderModel.statusDraft
                                ? () => _updateStatus(
                                    order,
                                    PurchaseOrderModel.statusApproved,
                                  )
                                : null,
                            onCancel:
                                canCancel &&
                                    order.status !=
                                        PurchaseOrderModel.statusCancelled
                                ? () => _updateStatus(
                                    order,
                                    PurchaseOrderModel.statusCancelled,
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<PurchaseOrderModel> _filter(List<PurchaseOrderModel> orders) {
    final query = _searchText.trim().toLowerCase();
    return orders
        .where((order) {
          if (_statusFilter != 'all' && order.status != _statusFilter) {
            return false;
          }
          if (_typeFilter != 'all' && order.purchaseType != _typeFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          final haystack =
              '${order.poNumber} ${order.vendorName} ${order.purchaseType} ${order.status}'
                  .toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }
}

class PurchaseOrderFormScreen extends StatefulWidget {
  final String tenantId;
  final String currentUserUid;
  final PurchaseOrderModel? initialOrder;

  const PurchaseOrderFormScreen({
    super.key,
    required this.tenantId,
    required this.currentUserUid,
    this.initialOrder,
  });

  @override
  State<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _poNumber = TextEditingController();
  final _vendorName = TextEditingController();
  final _vendorGst = TextEditingController();
  final _vendorAddress = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _paymentTerms = TextEditingController();
  final _remarks = TextEditingController();

  DateTime _poDate = DateTime.now();
  DateTime? _expectedDeliveryDate;
  String _vendorId = '';
  String _purchaseType = 'Raw Material';
  String _status = PurchaseOrderModel.statusDraft;
  bool _saving = false;
  bool _uploading = false;
  List<Map<String, dynamic>> _vendors = const [];
  final List<PurchaseOrderAttachmentModel> _attachments = [];
  final List<_LineDraft> _lines = [];

  bool get _isEdit => widget.initialOrder != null;

  PurchaseOrderRepository get _repository =>
      PurchaseOrderRepository(tenantId: widget.tenantId);

  @override
  void initState() {
    super.initState();
    final order = widget.initialOrder;
    if (order == null) {
      _poNumber.text = _repository.nextPoNumber();
      _lines.add(_LineDraft());
    } else {
      _poNumber.text = order.poNumber;
      _poDate = order.poDate;
      _expectedDeliveryDate = order.expectedDeliveryDate;
      _vendorId = order.vendorId;
      _vendorName.text = order.vendorName;
      _vendorGst.text = order.vendorGst;
      _vendorAddress.text = order.vendorAddress;
      _purchaseType =
          PurchaseOrderModel.purchaseTypes.contains(order.purchaseType)
          ? order.purchaseType
          : 'Raw Material';
      _deliveryAddress.text = order.deliveryAddress;
      _paymentTerms.text = order.paymentTerms;
      _remarks.text = order.remarks;
      _status = order.status;
      _attachments.addAll(order.attachments);
      _lines.addAll(order.items.map(_LineDraft.fromModel));
      if (_lines.isEmpty) _lines.add(_LineDraft());
    }
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    try {
      final vendors = await _repository.fetchVendors();
      if (!mounted) return;
      setState(() => _vendors = vendors);
    } catch (_) {
      if (!mounted) return;
      setState(() => _vendors = const []);
    }
  }

  @override
  void dispose() {
    _poNumber.dispose();
    _vendorName.dispose();
    _vendorGst.dispose();
    _vendorAddress.dispose();
    _deliveryAddress.dispose();
    _paymentTerms.dispose();
    _remarks.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _save({String? forcedStatus}) async {
    if (!_formKey.currentState!.validate()) return;

    final items = _lines
        .map((line) => line.toModel())
        .where((item) {
          return item.itemName.trim().isNotEmpty && item.quantity > 0;
        })
        .toList(growable: false);

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one PO item.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.initialOrder;
      final id = existing?.id ?? '';
      final status = forcedStatus ?? _status;
      final now = DateTime.now();
      final order = PurchaseOrderModel(
        id: id,
        poNumber: _poNumber.text.trim(),
        poDate: _poDate,
        vendorId: _vendorId,
        vendorName: _vendorName.text.trim(),
        vendorGst: _vendorGst.text.trim(),
        vendorAddress: _vendorAddress.text.trim(),
        purchaseType: _purchaseType,
        expectedDeliveryDate: _expectedDeliveryDate,
        deliveryAddress: _deliveryAddress.text.trim(),
        paymentTerms: _paymentTerms.text.trim(),
        status: status,
        remarks: _remarks.text.trim(),
        items: items,
        attachments: List.unmodifiable(_attachments),
        tenantId: widget.tenantId,
        companyId: widget.tenantId,
        createdByUid: existing?.createdByUid.isNotEmpty == true
            ? existing!.createdByUid
            : widget.currentUserUid,
        approvedByUid: status == PurchaseOrderModel.statusApproved
            ? widget.currentUserUid
            : (existing?.approvedByUid ?? ''),
        createdAt: existing?.createdAt,
        approvedAt: status == PurchaseOrderModel.statusApproved
            ? (existing?.approvedAt ?? now)
            : existing?.approvedAt,
      );

      await _repository.save(order);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == PurchaseOrderModel.statusApproved
                ? 'PO approved and saved.'
                : 'PO saved.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save PO: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadVendorQuotation() async {
    setState(() => _uploading = true);
    try {
      final result =
          await PurchaseOrderUploadService.pickAndUploadVendorQuotation(
            companyId: widget.tenantId,
            purchaseOrderId: widget.initialOrder?.id ?? _poNumber.text.trim(),
            uploadedByUid: widget.currentUserUid,
          );
      if (result == null) return;
      if (!mounted) return;
      setState(() => _attachments.add(result));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickDate({required bool expectedDate}) async {
    final initialDate = expectedDate
        ? (_expectedDeliveryDate ?? DateTime.now())
        : _poDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (expectedDate) {
        _expectedDeliveryDate = picked;
      } else {
        _poDate = picked;
      }
    });
  }

  Future<void> _pickMaterial(_LineDraft line) async {
    final material = await showDialog(
      context: context,
      builder: (_) => MaterialPickerDialog(tenantId: widget.tenantId),
    );
    if (material == null) return;
    setState(() {
      line.itemId = material.id;
      line.itemName.text = material.displayName;
      line.unit.text = material.unit;
      if (line.description.text.trim().isEmpty) {
        line.description.text = [
          material.materialType,
          material.materialGrade,
          material.materialShape,
        ].where((v) => v.toString().trim().isNotEmpty).join(' • ');
      }
    });
  }

  Future<void> _openAttachment(PurchaseOrderAttachmentModel attachment) async {
    final uri = Uri.tryParse(attachment.fileUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Purchase Order' : 'New Purchase Order'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : () => _save(),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _saving
                ? null
                : () => _save(forcedStatus: PurchaseOrderModel.statusApproved),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Approve'),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Vendor & PO Details',
              icon: Icons.business_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _poNumber,
                          decoration: const InputDecoration(
                            labelText: 'PO Number',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(expectedDate: false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'PO Date',
                            ),
                            child: Text(dateFormat.format(_poDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _purchaseType,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Type',
                          ),
                          items: PurchaseOrderModel.purchaseTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(
                            () => _purchaseType = value ?? 'Raw Material',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PopupMenuButton<String>(
                          tooltip: 'Select Vendor',
                          onSelected: (value) {
                            final vendor = _vendors
                                .cast<Map<String, dynamic>?>()
                                .firstWhere(
                                  (item) => item?['id'] == value,
                                  orElse: () => null,
                                );
                            setState(() {
                              _vendorId = value;
                              if (vendor != null) {
                                _vendorName.text = (vendor['name'] ?? '')
                                    .toString();
                                _vendorGst.text = (vendor['gstNo'] ?? '')
                                    .toString();
                                _vendorAddress.text = (vendor['address'] ?? '')
                                    .toString();
                              }
                            });
                          },
                          itemBuilder: (context) => _vendors.map((vendor) {
                            final id = (vendor['id'] ?? '').toString();
                            final name = (vendor['name'] ?? 'Vendor')
                                .toString();
                            return PopupMenuItem<String>(
                              value: id,
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Vendor',
                              hintText: 'Select Vendor',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              suffixIcon: Icon(Icons.keyboard_arrow_down),
                            ),
                            child: Text(
                              _vendorName.text.trim().isEmpty
                                  ? 'Select Vendor'
                                  : _vendorName.text.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _vendorName.text.trim().isEmpty
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _vendorName,
                          decoration: const InputDecoration(
                            labelText: 'Vendor Name',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _vendorGst,
                          decoration: const InputDecoration(
                            labelText: 'Vendor GST',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vendorAddress,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Address',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Related Vendor Quotation',
              icon: Icons.attach_file_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _uploading ? null : _uploadVendorQuotation,
                        icon: _uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file_outlined),
                        label: Text(
                          _uploading ? 'Uploading...' : 'Upload Quotation File',
                        ),
                      ),
                      const Text(
                        'PDF, image, Excel or Word file. This keeps vendor quote proof linked with PO.',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._attachments.map((attachment) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: const Color(0xFFE4E7EC)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                attachment.fileName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _openAttachment(attachment),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Open'),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () => setState(
                                () => _attachments.remove(attachment),
                              ),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Delivery & Terms',
              icon: Icons.local_shipping_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(expectedDate: true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Expected Delivery Date',
                            ),
                            child: Text(
                              _expectedDeliveryDate == null
                                  ? 'Select date'
                                  : dateFormat.format(_expectedDeliveryDate!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: PurchaseOrderModel.statusDraft,
                              child: Text('Draft'),
                            ),
                            DropdownMenuItem(
                              value: PurchaseOrderModel.statusApproved,
                              child: Text('Approved'),
                            ),
                            DropdownMenuItem(
                              value: PurchaseOrderModel.statusCancelled,
                              child: Text('Cancelled'),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => _status =
                                value ?? PurchaseOrderModel.statusDraft,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deliveryAddress,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _paymentTerms,
                    decoration: const InputDecoration(
                      labelText: 'Payment Terms',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarks,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Remarks'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Items / Services',
              icon: Icons.format_list_bulleted_outlined,
              trailing: TextButton.icon(
                onPressed: () => setState(() => _lines.add(_LineDraft())),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
              child: Column(
                children: [
                  ...List.generate(_lines.length, (index) {
                    final line = _lines[index];
                    return _LineEditor(
                      index: index,
                      line: line,
                      onChanged: () => setState(() {}),
                      onPickMaterial: () => _pickMaterial(line),
                      onRemove: _lines.length == 1
                          ? null
                          : () {
                              setState(() {
                                final removed = _lines.removeAt(index);
                                removed.dispose();
                              });
                            },
                    );
                  }),
                  const Divider(height: 26),
                  _TotalsBar(
                    items: _lines
                        .map((line) => line.toModel())
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final VoidCallback? onNew;

  const _HeaderCard({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.shopping_cart_checkout_outlined,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase Orders',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Level 1 PO flow: vendor, purchase type, item lines, vendor quotation upload and PDF generation.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add),
            label: const Text('Create PO'),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String searchText;
  final String statusFilter;
  final String typeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onTypeChanged;

  const _FilterBar({
    required this.searchText,
    required this.statusFilter,
    required this.typeFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search PO no, vendor, type...',
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: statusFilter,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(
                  value: PurchaseOrderModel.statusDraft,
                  child: Text('Draft'),
                ),
                DropdownMenuItem(
                  value: PurchaseOrderModel.statusApproved,
                  child: Text('Approved'),
                ),
                DropdownMenuItem(
                  value: PurchaseOrderModel.statusCancelled,
                  child: Text('Cancelled'),
                ),
              ],
              onChanged: onStatusChanged,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              value: typeFilter,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Types')),
                ...PurchaseOrderModel.purchaseTypes.map(
                  (type) => DropdownMenuItem(value: type, child: Text(type)),
                ),
              ],
              onChanged: onTypeChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrderModel order;
  final VoidCallback? onEdit;
  final VoidCallback? onPdf;
  final VoidCallback? onApprove;
  final VoidCallback? onCancel;

  const _PurchaseOrderCard({
    required this.order,
    required this.onEdit,
    required this.onPdf,
    this.onApprove,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_cart_checkout_outlined,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order.poNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              _StatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.vendorName.isEmpty ? 'Vendor not selected' : order.vendorName,
            style: const TextStyle(
              color: Color(0xFF475467),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MiniMetric(
                label: 'Date',
                value: dateFormat.format(order.poDate),
              ),
              _MiniMetric(label: 'Type', value: order.purchaseType),
              _MiniMetric(label: 'Items', value: '${order.items.length}'),
              _MiniMetric(
                label: 'Attachments',
                value: '${order.attachments.length}',
              ),
              _MiniMetric(
                label: 'Total',
                value:
                    'Rs ${NumberFormat('#,##0.00', 'en_IN').format(order.grandTotal)}',
              ),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...order.items.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${item.quantity} ${item.unit} × Rs ${item.rate.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('View / Edit'),
              ),
              OutlinedButton.icon(
                onPressed: onPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
              if (onApprove != null)
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Approve'),
                ),
              if (onCancel != null)
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LineEditor extends StatelessWidget {
  final int index;
  final _LineDraft line;
  final VoidCallback onChanged;
  final VoidCallback onPickMaterial;
  final VoidCallback? onRemove;

  const _LineEditor({
    required this.index,
    required this.line,
    required this.onChanged,
    required this.onPickMaterial,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '#${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: line.itemName,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    suffixIcon: IconButton(
                      tooltip: 'Pick from Material Master',
                      onPressed: onPickMaterial,
                      icon: const Icon(Icons.search),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: line.hsnSac,
                  decoration: const InputDecoration(labelText: 'HSN/SAC'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: line.unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: line.description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(controller: line.quantity, label: 'Qty'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(controller: line.rate, label: 'Rate'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(
                  controller: line.gstPercent,
                  label: 'GST %',
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 130,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Total'),
                  child: Text(
                    'Rs ${line.toModel().totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => onChanged(),
    );
  }
}

class _TotalsBar extends StatelessWidget {
  final List<PurchaseOrderItemModel> items;

  const _TotalsBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold<double>(
      0,
      (running, item) => running + item.amount,
    );
    final gst = items.fold<double>(
      0,
      (running, item) => running + item.gstAmount,
    );
    final total = items.fold<double>(
      0,
      (running, item) => running + item.totalAmount,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _TotalChip(label: 'Subtotal', value: subtotal),
        const SizedBox(width: 10),
        _TotalChip(label: 'GST', value: gst),
        const SizedBox(width: 10),
        _TotalChip(label: 'Grand Total', value: total, highlight: true),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final double value;
  final bool highlight;

  const _TotalChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFEAF2FF) : const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: Rs ${NumberFormat('#,##0.00', 'en_IN').format(value)}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFEAF2FF);
    Color fg = const Color(0xFF2563EB);
    if (status == PurchaseOrderModel.statusApproved) {
      bg = const Color(0xFFECFDF3);
      fg = const Color(0xFF027A48);
    } else if (status == PurchaseOrderModel.statusCancelled) {
      bg = const Color(0xFFFEF3F2);
      fg = const Color(0xFFB42318);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4E7EC)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_checkout_outlined,
              size: 42,
              color: Color(0xFF667085),
            ),
            SizedBox(height: 12),
            Text(
              'No purchase orders yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first PO. It will not increase stock until GRN / Material Inward is connected later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF667085), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineDraft {
  String itemId = '';
  final itemName = TextEditingController();
  final description = TextEditingController();
  final hsnSac = TextEditingController();
  final unit = TextEditingController(text: 'Nos');
  final quantity = TextEditingController(text: '1');
  final rate = TextEditingController(text: '0');
  final gstPercent = TextEditingController(text: '18');

  _LineDraft();

  factory _LineDraft.fromModel(PurchaseOrderItemModel model) {
    final draft = _LineDraft();
    draft.itemId = model.itemId;
    draft.itemName.text = model.itemName;
    draft.description.text = model.description;
    draft.hsnSac.text = model.hsnSac;
    draft.unit.text = model.unit;
    draft.quantity.text = _formatNumber(model.quantity);
    draft.rate.text = _formatNumber(model.rate);
    draft.gstPercent.text = _formatNumber(model.gstPercent);
    return draft;
  }

  PurchaseOrderItemModel toModel() {
    return PurchaseOrderItemModel(
      itemId: itemId,
      itemName: itemName.text.trim(),
      description: description.text.trim(),
      hsnSac: hsnSac.text.trim(),
      unit: unit.text.trim().isEmpty ? 'Nos' : unit.text.trim(),
      quantity: _toDouble(quantity.text),
      rate: _toDouble(rate.text),
      gstPercent: _toDouble(gstPercent.text),
    );
  }

  void dispose() {
    itemName.dispose();
    description.dispose();
    hsnSac.dispose();
    unit.dispose();
    quantity.dispose();
    rate.dispose();
    gstPercent.dispose();
  }
}

double _toDouble(String value) {
  final parsed = double.tryParse(value.replaceAll(',', '').trim());
  return parsed == null || parsed.isNaN ? 0 : parsed;
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
