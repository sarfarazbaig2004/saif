// ignore_for_file: invalid_use_of_protected_member

part of '../screens_add_inquiry.dart';

extension _AddInquiryProductsSection on _ScreensAddInquiryState {
  Widget _buildProductsSection() {
    return InquiryItemsGrid(
      items: _structuredProducts,
      onChanged: (items) {
        setState(() => _structuredProducts = items);
        _calculateInquiryReadiness();
      },
      onImportBoq: () => _showInquiryItemFutureMessage('BOQ import'),
      onUploadBom: () => _showInquiryItemFutureMessage('BOM linkage'),
      onUploadDrawing: () => _showInquiryItemFutureMessage('drawing upload'),
      onOpenBom: _openBomForInquiryItem,
    );
  }

  Future<void> _openBomForInquiryItem(
    Map<String, dynamic> item, {
    required bool readOnly,
  }) async {
    final itemId = _ensureInquiryItemId(item);
    await _persistInquiryProductsIfEditing();
    final bomId = (item['bomId'] ?? '').toString().trim();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EngineeringBomEntryScreen(
          tenantId: _tenantId,
          initialInquiryId: _currentInquiryReference(),
          initialInquiryItemId: itemId,
          initialBomId: bomId,
          initialCustomer: _customerNameSnapshot,
          initialProject: _currentProjectReference(),
          initialItemDescription: _inquiryItemDescription(item),
          initialQty: _inquiryItemQty(item),
          readOnly: readOnly,
        ),
      ),
    );
    await _refreshInquiryItemBomLink(itemId);
  }

  String _currentInquiryReference() {
    return _firstNonEmptyString([
          widget.existingDoc?.id,
          widget.existingInquiry?.id,
          _existingRawData?['inquiryNumber'],
          widget.existingInquiry?.inquiryNumber,
        ]) ??
        '';
  }

  String _ensureInquiryItemId(Map<String, dynamic> item) {
    var id = (item['inquiryItemId'] ?? '').toString().trim();
    if (id.isNotEmpty) return id;
    id = InquiryItemsGrid.newItemId();
    final index = _structuredProducts.indexWhere((candidate) {
      return identical(candidate, item) ||
          _inquiryItemDescription(candidate) == _inquiryItemDescription(item);
    });
    if (index >= 0) {
      setState(() => _structuredProducts[index]['inquiryItemId'] = id);
    }
    return id;
  }

  Future<void> _persistInquiryProductsIfEditing() async {
    if (widget.existingDoc == null) return;
    await widget.existingDoc!.set({
      'products': _structuredProducts,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _refreshInquiryItemBomLink(String inquiryItemId) async {
    if (_tenantId.isEmpty || inquiryItemId.isEmpty) return;
    final query = await TenantFirestore(tenantId: _tenantId)
        .collection('engineering_boms')
        .where('inquiryId', isEqualTo: _currentInquiryReference())
        .where('inquiryItemId', isEqualTo: inquiryItemId)
        .limit(1)
        .get();
    if (query.docs.isEmpty || !mounted) return;
    final doc = query.docs.first;
    final data = doc.data();
    debugPrint(
      'BOM_LINK_FOUND inquiryId=${_currentInquiryReference()} '
      'inquiryItemId=$inquiryItemId bomLinked=true bomId=${doc.id} '
      'bomNumber=${data['bomNo'] ?? data['bomNumber'] ?? ''} '
      'bomStatus=${data['status'] ?? ''}',
    );
    setState(() {
      for (final item in _structuredProducts) {
        if ((item['inquiryItemId'] ?? '').toString() == inquiryItemId) {
          item['bomLinked'] = true;
          item['bomId'] = doc.id;
          item['bomNumber'] = data['bomNo'] ?? data['bomNumber'] ?? '';
          item['bomStatus'] = data['status'] ?? '';
        }
      }
    });
  }

  String _currentProjectReference() {
    return _firstNonEmptyString([
          _controllers.subject.text,
          _controllers.projectSiteLocation.text,
        ]) ??
        '';
  }

  String _inquiryItemDescription(Map<String, dynamic> item) {
    return _firstNonEmptyString([item['description'], item['name']]) ?? '';
  }

  double _inquiryItemQty(Map<String, dynamic> item) {
    final value = item['quantity'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showInquiryItemFutureMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be connected in the engineering stage.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
