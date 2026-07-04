// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:QUIK/core/utils/file_upload_limits.dart';

class MirajVendorOfferScreen extends StatefulWidget {
  final String tenantId;
  final String currentUserUid;

  const MirajVendorOfferScreen({
    super.key,
    required this.tenantId,
    required this.currentUserUid,
  });

  @override
  State<MirajVendorOfferScreen> createState() => _MirajVendorOfferScreenState();
}

class _MirajVendorOfferScreenState extends State<MirajVendorOfferScreen> {
  final _searchController = TextEditingController();

  CollectionReference<Map<String, dynamic>> get _offersRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(widget.tenantId)
      .collection('vendor_offers');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MirajVendorOfferFormScreen(
              tenantId: widget.tenantId,
              currentUserUid: widget.currentUserUid,
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Offer'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _offersRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          final searchText = _searchController.text.trim().toLowerCase();

          final docs = snapshot.data?.docs ?? [];

          final filteredDocs = docs.where((doc) {
            if (searchText.isEmpty) return true;

            final data = doc.data();

            final searchableText = [
              data['vendorName'],
              data['subject'],
              data['offerNo'],
              data['status'],
            ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

            return searchableText.contains(searchText);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PurchaseHeader(
                title: 'Vendor Offers',
                subtitle:
                    'Upload vendor quotations, review item rates, and convert accepted offers into purchase orders.',
                icon: Icons.attach_file_outlined,
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search vendor offers...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child:
                    snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : docs.isEmpty
                    ? const _EmptyPurchaseState(
                        icon: Icons.description_outlined,
                        title: 'No vendor offers yet',
                        message:
                            'Add supplier quotations here. An offer attachment is required before saving.',
                      )
                    : filteredDocs.isEmpty
                    ? const _EmptyPurchaseState(
                        icon: Icons.search_off_outlined,
                        title: 'No matching offers',
                        message:
                            'Try searching by vendor name, subject, offer number, or status.',
                      )
                    : ListView.separated(
                        itemCount: filteredDocs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data();
                          return _VendorOfferCard(
                            tenantId: widget.tenantId,
                            offerId: doc.id,
                            data: data,
                            currentUserUid: widget.currentUserUid,
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
}

class MirajVendorOfferFormScreen extends StatefulWidget {
  final String tenantId;
  final String currentUserUid;
  final String? offerId;
  final Map<String, dynamic>? initialData;

  const MirajVendorOfferFormScreen({
    super.key,
    required this.tenantId,
    required this.currentUserUid,
    this.offerId,
    this.initialData,
  });

  @override
  State<MirajVendorOfferFormScreen> createState() =>
      _MirajVendorOfferFormScreenState();
}

class _MirajVendorOfferFormScreenState
    extends State<MirajVendorOfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorController = TextEditingController();
  final _subjectController = TextEditingController();
  final _offerNoController = TextEditingController();
  final _remarksController = TextEditingController();
  final List<_VendorOfferLineInput> _lines = [];

  String? _selectedVendorId;
  DateTime _offerDate = DateTime.now();
  DateTime? _validUntil;
  bool _isSaving = false;
  bool _isUploading = false;
  List<Map<String, dynamic>>? _attachments = [];

  bool get _isEditMode => widget.offerId != null;

  List<Map<String, dynamic>> get _offerAttachments {
    return _attachments ??= <Map<String, dynamic>>[];
  }

  CollectionReference<Map<String, dynamic>> get _offersRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(widget.tenantId)
      .collection('vendor_offers');

  CollectionReference<Map<String, dynamic>> get _rawMaterialsRef =>
      FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.tenantId)
          .collection('raw_materials');

  CollectionReference<Map<String, dynamic>> get _vendorsRef => FirebaseFirestore
      .instance
      .collection('companies')
      .doc(widget.tenantId)
      .collection('vendors');

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) return;

    _selectedVendorId = (data['vendorId'] ?? '').toString().trim().isEmpty
        ? null
        : (data['vendorId'] ?? '').toString().trim();
    _vendorController.text = (data['vendorName'] ?? '').toString();
    _subjectController.text = (data['subject'] ?? '').toString();
    _offerNoController.text = (data['offerNo'] ?? '').toString();
    _remarksController.text = (data['remarks'] ?? '').toString();

    final offerDate = data['offerDate'];
    if (offerDate is Timestamp) {
      _offerDate = offerDate.toDate();
    }
    final validUntil = data['validUntil'];
    if (validUntil is Timestamp) {
      _validUntil = validUntil.toDate();
    }

    _attachments = _normalizedAttachments(data);

    final lines = data['lines'];
    if (lines is List) {
      for (final rawLine in lines) {
        if (rawLine is! Map) continue;
        final line = Map<String, dynamic>.from(rawLine);
        _lines.add(_VendorOfferLineInput.fromData(line));
      }
    }
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _subjectController.dispose();
    _offerNoController.dispose();
    _remarksController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  double _toDouble(String value) => double.tryParse(value.trim()) ?? 0;

  String _safeExt(String? ext) {
    final clean = (ext ?? '').replaceAll('.', '').trim().toLowerCase();
    return clean.isEmpty ? 'bin' : clean;
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  }

  List<Map<String, dynamic>> _normalizedAttachments(Map<String, dynamic> data) {
    final attachments = data['attachments'];
    if (attachments is List) {
      return attachments
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final attachment = data['attachment'];
    if (attachment is Map) {
      return [Map<String, dynamic>.from(attachment)];
    }

    return [];
  }

  Future<void> _pickAttachments() async {
    try {
      setState(() => _isUploading = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
        withData: true,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      if (hasFileOverUploadLimit(result.files)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(maxUploadFileSizeMessage)),
          );
        }
        return;
      }

      final uploaded = <Map<String, dynamic>>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) continue;

        final ext = _safeExt(file.extension);
        final contentType = _contentType(ext);
        final safeName =
            'vendor_offer_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = FirebaseStorage.instance.ref().child(
          'companies/${widget.tenantId}/purchase/vendor_offers/$safeName',
        );

        final task = await ref.putData(
          bytes,
          SettableMetadata(
            contentType: contentType,
            customMetadata: {
              'companyId': widget.tenantId,
              'uploadedBy': widget.currentUserUid,
              'module': 'purchase',
              'type': 'vendor_offer',
              'originalName': file.name,
            },
          ),
        );

        final url = await task.ref.getDownloadURL();
        uploaded.add({
          'name': file.name,
          'url': url,
          'contentType': contentType,
          'uploadedAt': Timestamp.now(),
          'uploadedBy': widget.currentUserUid,
        });
      }

      if (uploaded.isNotEmpty) {
        setState(() {
          _attachments = [..._offerAttachments, ...uploaded];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attachment upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _offerAttachments.removeAt(index);
    });
  }

  Future<void> _pickDate({required bool validity}) async {
    final value = await showDatePicker(
      context: context,
      initialDate: validity ? (_validUntil ?? DateTime.now()) : _offerDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value == null) return;
    setState(() {
      if (validity) {
        _validUntil = value;
      } else {
        _offerDate = value;
      }
    });
  }

  Future<void> _pickVendor() async {
    final vendor = await showDialog<_SelectedVendor>(
      context: context,
      builder: (_) => _VendorPickerDialog(vendorsRef: _vendorsRef),
    );
    if (vendor == null) return;
    setState(() {
      _selectedVendorId = vendor.id;
      _vendorController.text = vendor.name;
    });
  }

  Future<void> _addLine() async {
    final material = await showDialog<_SelectedRawMaterial>(
      context: context,
      builder: (_) =>
          _RawMaterialPickerDialog(rawMaterialsRef: _rawMaterialsRef),
    );

    if (material == null) return;

    setState(() {
      _lines.add(
        _VendorOfferLineInput(
            productId: material.id,
            productName: material.materialCode,
            uom: material.uom,
            addToProductCost: false,
          )
          ..descriptionController.text =
              '${material.description} • ${material.grade}',
      );
    });
  }

  Future<bool> _offerNoExists(String offerNo) async {
    final normalizedOfferNo = offerNo.trim().toLowerCase();

    final snapshot = await _offersRef
        .where('offerNoLower', isEqualTo: normalizedOfferNo)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    if (_isEditMode && snapshot.docs.first.id == widget.offerId) {
      return false;
    }

    return true;
  }

  Future<void> _save() async {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;
    final offerNo = _offerNoController.text.trim();

    if (await _offerNoExists(offerNo)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer number already exists'),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    if (_offerAttachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vendor offer attachment is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one item line'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final lines = _lines.map((line) {
        final qty = _toDouble(line.qtyController.text);
        final rate = _toDouble(line.rateController.text);
        final gst = _toDouble(line.gstController.text);
        final taxable = qty * rate;
        final tax = taxable * gst / 100;
        return {
          'productId': line.productId,
          'productName': line.productName,
          'description': line.descriptionController.text.trim(),
          'uom': line.uom,
          'qty': qty,
          'rate': rate,
          'gstPercentage': gst,
          'taxableAmount': taxable,
          'taxAmount': tax,
          'lineTotal': taxable + tax,
          'addToProductCost': line.addToProductCost,
        };
      }).toList();

      final total = lines.fold<double>(
        0,
        (runningTotal, line) =>
            runningTotal + ((line['lineTotal'] as num?)?.toDouble() ?? 0),
      );

      final data = {
        'tenantId': widget.tenantId,
        'vendorId': _selectedVendorId ?? '',
        'vendorName': _vendorController.text.trim(),
        'subject': _subjectController.text.trim(),
        'offerNo': _offerNoController.text.trim(),
        'offerNoLower': _offerNoController.text.trim().toLowerCase(),
        'offerDate': Timestamp.fromDate(_offerDate),
        'validUntil': _validUntil == null
            ? null
            : Timestamp.fromDate(_validUntil!),
        'attachment': _offerAttachments.isNotEmpty
            ? _offerAttachments.first
            : null,
        'attachments': _offerAttachments,
        'lines': lines,
        'totalAmount': total,
        'status': 'received',
        'remarks': _remarksController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': widget.currentUserUid,
      };

      if (_isEditMode) {
        await _offersRef.doc(widget.offerId).update(data);
      } else {
        await _offersRef.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': widget.currentUserUid,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode ? 'Vendor offer updated' : 'Vendor offer saved',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Vendor Offer' : 'New Vendor Offer'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101828),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Offer Details'),
                  TextFormField(
                    controller: _vendorController,
                    validator: _required,
                    readOnly: true,
                    onTap: _pickVendor,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Name *',
                      prefixIcon: Icon(Icons.business_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subjectController,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Subject *',
                      prefixIcon: Icon(Icons.subject_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _offerNoController,
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Offer / Quotation No. *',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(validity: false),
                        icon: const Icon(Icons.event_outlined),
                        label: Text('Offer: ${_formatDate(_offerDate)}'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(validity: true),
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(
                          _validUntil == null
                              ? 'Validity'
                              : 'Valid: ${_formatDate(_validUntil!)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Vendor Offer Attachment *'),
                  FilledButton.icon(
                    onPressed: _isUploading ? null : _pickAttachments,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Upload Offer Documents',
                    ),
                  ),
                  if (_offerAttachments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._offerAttachments.asMap().entries.map(
                      (entry) => _AttachmentTile(
                        attachment: entry.value,
                        onRemove: () => _removeAttachment(entry.key),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: _SectionTitle('Offer Items')),
                      OutlinedButton.icon(
                        onPressed: _addLine,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  if (_lines.isEmpty)
                    const Text(
                      'No item lines added',
                      style: TextStyle(color: Color(0xFF667085)),
                    )
                  else
                    ..._lines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      return _OfferLineEditor(
                        line: line,
                        onRemove: () {
                          setState(() {
                            _lines.removeAt(index).dispose();
                          });
                        },
                        onChanged: () => setState(() {}),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormCard(
              child: TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : (_isEditMode
                          ? 'Update Vendor Offer'
                          : 'Save Vendor Offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorOfferCard extends StatefulWidget {
  final String tenantId;
  final String offerId;
  final String currentUserUid;
  final Map<String, dynamic> data;

  const _VendorOfferCard({
    required this.tenantId,
    required this.offerId,
    required this.currentUserUid,
    required this.data,
  });

  @override
  State<_VendorOfferCard> createState() => _VendorOfferCardState();
}

class _VendorOfferCardState extends State<_VendorOfferCard> {
  bool _isConverting = false;

  void _openEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MirajVendorOfferFormScreen(
          tenantId: widget.tenantId,
          currentUserUid: widget.currentUserUid,
          offerId: widget.offerId,
          initialData: widget.data,
        ),
      ),
    );
  }

  Future<void> _convertToPurchaseOrder() async {
    if (_isConverting) return;
    setState(() => _isConverting = true);
    try {
      final db = FirebaseFirestore.instance;
      final offerRef = db
          .collection('companies')
          .doc(widget.tenantId)
          .collection('vendor_offers')
          .doc(widget.offerId);
      final poRef = db
          .collection('companies')
          .doc(widget.tenantId)
          .collection('purchase_orders')
          .doc();

      final lines = (widget.data['lines'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      await db.runTransaction((transaction) async {
        final freshOffer = await transaction.get(offerRef);
        final freshData = freshOffer.data() ?? widget.data;
        if ((freshData['status'] ?? '').toString() == 'converted') {
          return;
        }

        transaction.set(poRef, {
          'tenantId': widget.tenantId,
          'poNo': 'PO-${DateTime.now().millisecondsSinceEpoch}',
          'vendorId': freshData['vendorId'] ?? '',
          'vendorName': freshData['vendorName'] ?? '',
          'sourceVendorOfferId': widget.offerId,
          'sourceOfferSubject': freshData['subject'] ?? '',
          'sourceOfferNo': freshData['offerNo'] ?? '',
          'sourceOfferAttachment': freshData['attachment'],
          'sourceOfferAttachments':
              freshData['attachments'] ??
              (freshData['attachment'] == null
                  ? []
                  : [freshData['attachment']]),
          'poDate': FieldValue.serverTimestamp(),
          'lines': freshData['lines'] ?? [],
          'totalAmount': freshData['totalAmount'] ?? 0,
          'status': 'draft',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': widget.currentUserUid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': widget.currentUserUid,
        });

        transaction.update(offerRef, {
          'status': 'converted',
          'convertedPurchaseOrderId': poRef.id,
          'convertedAt': FieldValue.serverTimestamp(),
          'convertedBy': widget.currentUserUid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': widget.currentUserUid,
        });
      });

      for (final line in lines) {
        if (line['addToProductCost'] != true) continue;
        final productId = (line['productId'] ?? '').toString();
        if (productId.isEmpty) continue;
        final rate =
            (line['rate'] as num?)?.toDouble() ??
            double.tryParse((line['rate'] ?? '').toString()) ??
            0;
        await db
            .collection('companies')
            .doc(widget.tenantId)
            .collection('products')
            .doc(productId)
            .update({
              'costPrice': rate,
              'vendorOfferCost': rate,
              'lastPurchaseCost': rate,
              'lastVendorOfferId': widget.offerId,
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedBy': widget.currentUserUid,
              'updatedByUid': widget.currentUserUid,
            });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase order draft created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conversion failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.data['status'] ?? 'received').toString();
    final attachments = _normalizedCardAttachments(widget.data);
    final lines = (widget.data['lines'] as List? ?? []);

    return _FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _offerTitle(widget.data),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 8),
          if ((widget.data['offerNo'] ?? '').toString().trim().isNotEmpty) ...[
            Text(
              'Offer No: ${(widget.data['offerNo'] ?? '').toString()}',
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            (widget.data['vendorName'] ?? '').toString(),
            style: const TextStyle(
              color: Color(0xFF475467),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MiniMetric(label: 'Items', value: '${lines.length}'),
              _MiniMetric(
                label: 'Total',
                value:
                    'Rs ${(((widget.data['totalAmount'] as num?)?.toDouble() ?? 0)).toStringAsFixed(2)}',
              ),
            ],
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...attachments.map(
              (attachment) => _AttachmentTile(attachment: attachment),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: status == 'converted' ? null : _openEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                FilledButton.icon(
                  onPressed: status == 'converted' || _isConverting
                      ? null
                      : _convertToPurchaseOrder,
                  icon: _isConverting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_cart_checkout_outlined),
                  label: Text(
                    status == 'converted'
                        ? 'Converted'
                        : (_isConverting ? 'Converting...' : 'Convert to PO'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _normalizedCardAttachments(
    Map<String, dynamic> data,
  ) {
    final attachments = data['attachments'];
    if (attachments is List) {
      return attachments
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final attachment = data['attachment'];
    if (attachment is Map) {
      return [Map<String, dynamic>.from(attachment)];
    }

    return [];
  }

  String _offerTitle(Map<String, dynamic> data) {
    final subject = (data['subject'] ?? '').toString().trim();
    if (subject.isNotEmpty) return subject;
    final offerNo = (data['offerNo'] ?? '').toString().trim();
    return offerNo.isEmpty ? 'Vendor offer' : offerNo;
  }
}

class _OfferLineEditor extends StatelessWidget {
  final _VendorOfferLineInput line;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _OfferLineEditor({
    required this.line,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.productName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: line.descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: line.qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: line.rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: line.gstController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'GST %'),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: line.addToProductCost,
            title: const Text('Update raw material purchase rate'),
            subtitle: const Text(
              'Applied when converting this offer into Purchase Order',
            ),
            onChanged: (value) {
              line.addToProductCost = value;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _VendorOfferLineInput {
  final String productId;
  final String productName;
  final String uom;
  final TextEditingController descriptionController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController gstController;
  bool addToProductCost;

  _VendorOfferLineInput({
    required this.productId,
    required this.productName,
    required this.uom,
    required this.addToProductCost,
  }) : descriptionController = TextEditingController(),
       qtyController = TextEditingController(text: '1'),
       rateController = TextEditingController(text: '0'),
       gstController = TextEditingController(text: '18');

  factory _VendorOfferLineInput.fromData(Map<String, dynamic> data) {
    final line = _VendorOfferLineInput(
      productId: (data['productId'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      uom: (data['uom'] ?? 'Nos').toString(),
      addToProductCost: data['addToProductCost'] == true,
    );
    line.descriptionController.text = (data['description'] ?? '').toString();
    line.qtyController.text = (data['qty'] ?? 1).toString();
    line.rateController.text = (data['rate'] ?? 0).toString();
    line.gstController.text = (data['gstPercentage'] ?? 18).toString();
    return line;
  }

  void dispose() {
    descriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
    gstController.dispose();
  }
}

class _RawMaterialPickerDialog extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> rawMaterialsRef;

  const _RawMaterialPickerDialog({required this.rawMaterialsRef});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Raw Material'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: rawMaterialsRef.snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (docs.isEmpty) {
              return const Center(child: Text('No raw materials found'));
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();

                final material = _SelectedRawMaterial(
                  id: doc.id,
                  materialCode: (data['materialCode'] ?? '').toString(),
                  description: (data['description'] ?? '').toString(),
                  grade: (data['grade'] ?? '').toString(),
                  uom: (data['uom'] ?? 'KG').toString(),
                );

                return ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(material.materialCode),
                  subtitle: Text('${material.description} • ${material.grade}'),
                  trailing: Text(material.uom),
                  onTap: () {
                    Navigator.pop(context, material);
                  },
                );
              },
            );
          },
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

class _SelectedRawMaterial {
  final String id;
  final String materialCode;
  final String description;
  final String grade;
  final String uom;

  const _SelectedRawMaterial({
    required this.id,
    required this.materialCode,
    required this.description,
    required this.grade,
    required this.uom,
  });
}

class _VendorPickerDialog extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> vendorsRef;

  const _VendorPickerDialog({required this.vendorsRef});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Vendor'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: vendorsRef.orderBy('nameLower').snapshots(),
          builder: (context, snapshot) {
            final docs = (snapshot.data?.docs ?? [])
                .where(
                  (doc) =>
                      doc.data()['isDeleted'] != true &&
                      doc.data()['isActive'] != false,
                )
                .toList();

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (docs.isEmpty) {
              return const Center(
                child: Text('No active vendors found. Add a vendor first.'),
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
                  contactPerson: (data['contactPerson'] ?? '').toString(),
                  phone: (data['phone'] ?? '').toString(),
                );

                return ListTile(
                  leading: const Icon(Icons.business_outlined),
                  title: Text(vendor.name),
                  subtitle: Text(
                    [
                      vendor.contactPerson,
                      vendor.phone,
                    ].where((value) => value.trim().isNotEmpty).join(' • '),
                  ),
                  onTap: () => Navigator.pop(context, vendor),
                );
              },
            );
          },
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
  final String contactPerson;
  final String phone;

  const _SelectedVendor({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
  });
}

class _PurchaseHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PurchaseHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final Map<String, dynamic> attachment;
  final VoidCallback? onRemove;

  const _AttachmentTile({required this.attachment, this.onRemove});

  Future<void> _open() async {
    final url = (attachment['url'] ?? '').toString();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.attach_file_outlined),
      title: Text(
        (attachment['name'] ?? 'Attachment').toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            onPressed: _open,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open'),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final converted = status == 'converted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: converted ? const Color(0xFFE8F7EE) : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        converted ? 'Converted' : 'Received',
        style: TextStyle(
          color: converted ? Colors.green.shade700 : Colors.orange.shade800,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
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

class _EmptyPurchaseState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyPurchaseState({
    required this.icon,
    required this.title,
    required this.message,
  });

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF667085)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  const months = [
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
