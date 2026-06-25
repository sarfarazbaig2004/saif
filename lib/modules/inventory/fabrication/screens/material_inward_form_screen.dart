import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_model.dart';
import 'package:QUIK/modules/inventory/fabrication/models/raw_material_transaction_model.dart';
import 'package:QUIK/modules/inventory/fabrication/repositories/fabrication_inventory_repository.dart';

class MaterialInwardFormScreen extends StatefulWidget {
  final String tenantId;
  final bool purchaseView;

  const MaterialInwardFormScreen({
    super.key,
    required this.tenantId,
    this.purchaseView = false,
  });

  @override
  State<MaterialInwardFormScreen> createState() =>
      _MaterialInwardFormScreenState();
}

class _MaterialInwardFormScreenState extends State<MaterialInwardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _supplierName = TextEditingController();
  final _vendorInvoiceNo = TextEditingController();
  final _purchaseOrderNo = TextEditingController();
  final _vehicleNo = TextEditingController();
  final _challanNo = TextEditingController();
  final _plantName = TextEditingController(text: 'Plant 1');
  final _warehouseName = TextEditingController(text: 'Main Store');
  final _materialDescription = TextEditingController();
  final _grade = TextEditingController();
  final _lengthMm = TextEditingController();
  final _unitWeightKgPerM = TextEditingController();
  final _quantityKg = TextEditingController();
  final _quantityNos = TextEditingController();
  final _remarks = TextEditingController();

  DateTime _inwardDate = DateTime.now();
  bool _saving = false;
  RawMaterialModel? _selectedMaterial;
  _SelectedVendor? _selectedVendor;
  String _purchaseOrderId = '';

  String get _tenantId {
    final contextTenantId = context.tenant.selectedTenantId.trim();
    return contextTenantId.isNotEmpty
        ? contextTenantId
        : widget.tenantId.trim();
  }

  FabricationInventoryRepository get _repository =>
      FabricationInventoryRepository(tenantId: _tenantId);

  @override
  void initState() {
    super.initState();
    _quantityNos.addListener(_autoCalculateKg);
    _lengthMm.addListener(_autoCalculateKg);
    _unitWeightKgPerM.addListener(_autoCalculateKg);
  }

  @override
  void dispose() {
    _supplierName.dispose();
    _vendorInvoiceNo.dispose();
    _purchaseOrderNo.dispose();
    _vehicleNo.dispose();
    _challanNo.dispose();
    _plantName.dispose();
    _warehouseName.dispose();
    _materialDescription.dispose();
    _grade.dispose();
    _lengthMm.dispose();
    _unitWeightKgPerM.dispose();
    _quantityKg.dispose();
    _quantityNos.dispose();
    _remarks.dispose();
    super.dispose();
  }

  void _autoCalculateKg() {
    final qtyKg = double.tryParse(_quantityKg.text.trim()) ?? 0;
    if (qtyKg > 0) return;
    final nos = double.tryParse(_quantityNos.text.trim()) ?? 0;
    final length = double.tryParse(_lengthMm.text.trim()) ?? 0;
    final unitWeight = double.tryParse(_unitWeightKgPerM.text.trim()) ?? 0;
    if (nos <= 0 || length <= 0 || unitWeight <= 0) return;
    final kg = nos * (length / 1000) * unitWeight;
    _quantityKg.text = kg.toStringAsFixed(3);
  }

  void _applyMaterial(RawMaterialModel? material) {
    if (material == null) return;
    setState(() => _selectedMaterial = material);
    _materialDescription.text = material.descriptionThickness;
    _grade.text = material.gradeIs;
    _lengthMm.text = _formatNumber(material.length);
    _unitWeightKgPerM.text = _formatNumber(material.unitWeight);
    _autoCalculateKg();
  }

  Future<void> _pickVendor() async {
    final vendor = await showDialog<_SelectedVendor>(
      context: context,
      builder: (_) => _VendorPickerDialog(tenantId: _tenantId),
    );
    if (vendor == null) return;
    setState(() {
      _selectedVendor = vendor;
      _supplierName.text = vendor.name;
      if (_purchaseOrderNo.text.trim().isNotEmpty) {
        _purchaseOrderId = '';
        _purchaseOrderNo.clear();
      }
    });
  }

  Future<void> _pickPurchaseOrder() async {
    final purchaseOrder = await showDialog<_SelectedPurchaseOrder>(
      context: context,
      builder: (_) => _PurchaseOrderPickerDialog(
        tenantId: _tenantId,
        vendorId: _selectedVendor?.id ?? '',
        vendorName: _selectedVendor?.name ?? '',
      ),
    );
    if (purchaseOrder == null) return;
    setState(() {
      _purchaseOrderId = purchaseOrder.id;
      _purchaseOrderNo.text = purchaseOrder.poNo;
    });
  }

  Future<void> _pickMaterial(List<RawMaterialModel> materials) async {
    final material = await showDialog<RawMaterialModel>(
      context: context,
      builder: (_) => _RawMaterialPickerDialog(materials: materials),
    );
    if (material == null) return;
    _applyMaterial(material);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_tenantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing company workspace. Material inward was not saved.',
          ),
        ),
      );
      return;
    }

    if (_selectedVendor == null || _supplierName.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select an active vendor.')));
      return;
    }

    if (_selectedMaterial == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select Raw Material.')));
      return;
    }

    final quantityNos = double.tryParse(_quantityNos.text.trim()) ?? 0;
    final quantityKg = double.tryParse(_quantityKg.text.trim()) ?? 0;
    if (quantityNos <= 0 && quantityKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter Received Qty (nos) or Received Qty (kg).'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final material = _selectedMaterial;
      await _repository.saveInventoryTransaction(
        RawMaterialTransactionModel(
          transactionId: _repository.newTransactionId(),
          transactionType: RawMaterialTransactionType.inward,
          transactionDate: _inwardDate,
          materialId: material?.materialId ?? '',
          materialCode: material?.materialCode ?? '',
          materialDescription: _materialDescription.text.trim(),
          grade: _grade.text.trim(),
          length: double.tryParse(_lengthMm.text.trim()) ?? 0,
          unitWeight: double.tryParse(_unitWeightKgPerM.text.trim()) ?? 0,
          uom: material?.uom ?? 'Kg',
          category: material?.category ?? '',
          productFamily: material?.productFamily ?? '',
          plantName: _plantName.text.trim(),
          warehouseName: _warehouseName.text.trim(),
          quantityNos: quantityNos,
          quantityKg: quantityKg,
          referenceNo: _challanNo.text.trim(),
          partyOrProcess: _supplierName.text.trim(),
          vendorId: _selectedVendor?.id ?? '',
          vendorInvoiceNo: _vendorInvoiceNo.text.trim(),
          purchaseOrderId: _purchaseOrderId,
          purchaseOrderNo: _purchaseOrderNo.text.trim(),
          vehicleNo: _vehicleNo.text.trim(),
          workOrderId: '',
          heatNumber: '',
          batchNo: '',
          millCertificateUrl: '',
          qaReferenceId: '',
          remarks: _remarks.text.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.purchaseView
                ? 'GRN saved and stock updated'
                : 'Material inward saved and stock updated',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save receipt: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inwardDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _inwardDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.purchaseView
        ? 'New GRN / Material Receipt'
        : 'New Raw Material Inward';

    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving' : 'Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: StreamBuilder<List<RawMaterialModel>>(
            stream: _repository.watchRawMaterials(activeOnly: true),
            builder: (context, snapshot) {
              final materials = snapshot.data ?? const <RawMaterialModel>[];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: zBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _dateField(),
                        _vendorPicker(),
                        _field(_challanNo, 'Challan / GRN No', required: true),
                        _field(_vendorInvoiceNo, 'Vendor Invoice No.'),
                        _purchaseOrderPicker(),
                        _field(_vehicleNo, 'Vehicle No.'),
                        _field(_plantName, 'Plant', required: true),
                        _field(_warehouseName, 'Warehouse', required: true),
                        _materialPicker(materials),
                        _field(
                          _materialDescription,
                          'Description / Thickness',
                          width: 420,
                          required: true,
                          readOnly: true,
                        ),
                        _field(
                          _grade,
                          'Grade / IS',
                          required: true,
                          readOnly: true,
                        ),
                        _field(
                          _lengthMm,
                          'Length',
                          number: true,
                          readOnly: true,
                        ),
                        _field(
                          _unitWeightKgPerM,
                          'Unit Weight',
                          number: true,
                          readOnly: true,
                        ),
                        _field(
                          _quantityNos,
                          'Received Qty (nos)',
                          number: true,
                        ),
                        _field(
                          _quantityKg,
                          'Received Qty (kg)',
                          number: true,
                          required: true,
                        ),
                        _field(_remarks, 'Remarks', width: 420),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _materialPicker(List<RawMaterialModel> materials) {
    return SizedBox(
      width: 420,
      child: InkWell(
        onTap: materials.isEmpty ? null : () => _pickMaterial(materials),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Raw Material',
            suffixIcon: Icon(Icons.search),
            contentPadding: EdgeInsets.fromLTRB(12, 16, 44, 16),
          ),
          child: Text(
            _selectedMaterial == null
                ? 'Select Raw Material'
                : _selectedMaterial!.displayName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _selectedMaterial == null ? zMuted : zText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _vendorPicker() {
    return SizedBox(
      width: 300,
      child: InkWell(
        onTap: _pickVendor,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Vendor',
            errorText: _supplierName.text.trim().isEmpty ? null : null,
            suffixIcon: const Icon(Icons.search),
          ),
          child: Text(
            _supplierName.text.trim().isEmpty
                ? 'Select active vendor'
                : _supplierName.text.trim(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _supplierName.text.trim().isEmpty ? zMuted : zText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _purchaseOrderPicker() {
    return SizedBox(
      width: 300,
      child: InkWell(
        onTap: _pickPurchaseOrder,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Purchase Order',
            suffixIcon: Icon(Icons.search),
          ),
          child: Text(
            _purchaseOrderNo.text.trim().isEmpty
                ? 'Optional'
                : _purchaseOrderNo.text.trim(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _purchaseOrderNo.text.trim().isEmpty ? zMuted : zText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateField() {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Receipt Date'),
          child: Text(_formatDate(_inwardDate)),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    double width = 240,
    bool required = false,
    bool number = false,
    bool readOnly = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) =>
                  (value ?? '').trim().isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }

  String _formatDate(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(3);
  }
}

class _VendorPickerDialog extends StatefulWidget {
  final String tenantId;

  const _VendorPickerDialog({required this.tenantId});

  @override
  State<_VendorPickerDialog> createState() => _VendorPickerDialogState();
}

class _VendorPickerDialogState extends State<_VendorPickerDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _vendorsRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(widget.tenantId)
      .collection('vendors');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Vendor'),
      content: SizedBox(
        width: 560,
        height: 460,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search vendor',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _vendorsRef.orderBy('nameLower').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = (snapshot.data?.docs ?? [])
                      .where((doc) {
                        final data = doc.data();
                        if (data['isDeleted'] == true ||
                            data['isActive'] == false) {
                          return false;
                        }
                        final name = (data['name'] ?? '').toString();
                        final gstNo = (data['gstNo'] ?? '').toString();
                        if (_query.isEmpty) return true;
                        return name.toLowerCase().contains(_query) ||
                            gstNo.toLowerCase().contains(_query);
                      })
                      .toList(growable: false);

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No active vendors found.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final vendor = _SelectedVendor(
                        id: doc.id,
                        name: (data['name'] ?? '').toString(),
                        gstNo: (data['gstNo'] ?? '').toString(),
                      );
                      return ListTile(
                        leading: const Icon(Icons.business_outlined),
                        title: Text(vendor.name),
                        subtitle: vendor.gstNo.trim().isEmpty
                            ? null
                            : Text('GSTIN: ${vendor.gstNo}'),
                        onTap: () => Navigator.pop(context, vendor),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _RawMaterialPickerDialog extends StatefulWidget {
  final List<RawMaterialModel> materials;

  const _RawMaterialPickerDialog({required this.materials});

  @override
  State<_RawMaterialPickerDialog> createState() =>
      _RawMaterialPickerDialogState();
}

class _RawMaterialPickerDialogState extends State<_RawMaterialPickerDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materials = _filteredMaterials();

    return AlertDialog(
      title: const Text('Select Raw Material'),
      content: SizedBox(
        width: 620,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search material',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: materials.isEmpty
                  ? const Center(child: Text('No raw materials found.'))
                  : ListView.separated(
                      itemCount: materials.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final material = materials[index];
                        final subtitle = [
                          material.gradeIs,
                          if (material.length > 0)
                            '${_formatMaterialNumber(material.length)} mm',
                          if (material.unitWeight > 0)
                            '${_formatMaterialNumber(material.unitWeight)} kg/m',
                        ].where((value) => value.trim().isNotEmpty).join(' • ');

                        return ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(
                            material.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: subtitle.isEmpty ? null : Text(subtitle),
                          onTap: () => Navigator.pop(context, material),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  List<RawMaterialModel> _filteredMaterials() {
    final unique = <String, RawMaterialModel>{};
    for (final material in widget.materials) {
      unique.putIfAbsent(_materialKey(material), () => material);
    }

    final rows = unique.values
        .where((material) {
          if (_query.isEmpty) return true;
          return material.materialCode.toLowerCase().contains(_query) ||
              material.descriptionThickness.toLowerCase().contains(_query) ||
              material.gradeIs.toLowerCase().contains(_query);
        })
        .toList(growable: false);

    rows.sort((a, b) {
      final code = a.materialCode.compareTo(b.materialCode);
      if (code != 0) return code;
      final description = a.descriptionThickness.compareTo(
        b.descriptionThickness,
      );
      if (description != 0) return description;
      return a.gradeIs.compareTo(b.gradeIs);
    });
    return rows;
  }

  String _materialKey(RawMaterialModel material) {
    if (material.materialId.trim().isNotEmpty) return material.materialId;
    return [
      material.materialCode,
      material.descriptionThickness,
      material.gradeIs,
      material.length.toStringAsFixed(3),
      material.unitWeight.toStringAsFixed(3),
    ].map((value) => value.trim().toLowerCase()).join('|');
  }

  static String _formatMaterialNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(3);
  }
}

class _PurchaseOrderPickerDialog extends StatefulWidget {
  final String tenantId;
  final String vendorId;
  final String vendorName;

  const _PurchaseOrderPickerDialog({
    required this.tenantId,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<_PurchaseOrderPickerDialog> createState() =>
      _PurchaseOrderPickerDialogState();
}

class _PurchaseOrderPickerDialogState
    extends State<_PurchaseOrderPickerDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _purchaseOrdersRef =>
      FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.tenantId)
          .collection('purchase_orders');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Purchase Order'),
      content: SizedBox(
        width: 560,
        height: 460,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search purchase order',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _purchaseOrdersRef
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = (snapshot.data?.docs ?? [])
                      .where((doc) {
                        final data = doc.data();
                        if (data['isDeleted'] == true) return false;
                        final vendorId = (data['vendorId'] ?? '').toString();
                        final vendorName = (data['vendorName'] ?? '')
                            .toString();
                        if (widget.vendorId.trim().isNotEmpty &&
                            vendorId.trim().isNotEmpty &&
                            vendorId != widget.vendorId) {
                          return false;
                        }
                        if (widget.vendorId.trim().isEmpty &&
                            widget.vendorName.trim().isNotEmpty &&
                            vendorName.trim().isNotEmpty &&
                            vendorName.trim().toLowerCase() !=
                                widget.vendorName.trim().toLowerCase()) {
                          return false;
                        }
                        final poNo = (data['poNo'] ?? doc.id).toString();
                        if (_query.isEmpty) return true;
                        return poNo.toLowerCase().contains(_query) ||
                            vendorName.toLowerCase().contains(_query);
                      })
                      .toList(growable: false);

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No purchase orders found.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final purchaseOrder = _SelectedPurchaseOrder(
                        id: doc.id,
                        poNo: (data['poNo'] ?? doc.id).toString(),
                        vendorName: (data['vendorName'] ?? '').toString(),
                      );
                      return ListTile(
                        leading: const Icon(Icons.assignment_outlined),
                        title: Text(purchaseOrder.poNo),
                        subtitle: purchaseOrder.vendorName.trim().isEmpty
                            ? null
                            : Text(purchaseOrder.vendorName),
                        onTap: () => Navigator.pop(context, purchaseOrder),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SelectedVendor {
  final String id;
  final String name;
  final String gstNo;

  const _SelectedVendor({
    required this.id,
    required this.name,
    required this.gstNo,
  });
}

class _SelectedPurchaseOrder {
  final String id;
  final String poNo;
  final String vendorName;

  const _SelectedPurchaseOrder({
    required this.id,
    required this.poNo,
    required this.vendorName,
  });
}
