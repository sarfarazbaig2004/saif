// ignore_for_file: invalid_use_of_protected_member

part of '../screens_add_inquiry.dart';

extension _AddInquiryProductsSection on _ScreensAddInquiryState {
  Widget _buildProductsSection() {
    return InquiryItemsGrid(
      items: _structuredProducts,
      onChanged: (items) {
        setState(() => _structuredProducts = items);
        _calculateDealScore();
      },
      onImportBoq: () => _showInquiryItemFutureMessage('BOQ import'),
      onUploadBom: () => _showInquiryItemFutureMessage('BOM linkage'),
      onUploadDrawing: () => _showInquiryItemFutureMessage('drawing upload'),
      onCreateBom: _openBomForInquiryItem,
    );
  }

  void _openBomForInquiryItem(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EngineeringBomEntryScreen(
          tenantId: _tenantId,
          initialInquiryId: _currentInquiryReference(),
          initialCustomer: _customerNameSnapshot,
          initialProject: _currentProjectReference(),
          initialItemDescription: _inquiryItemDescription(item),
          initialQty: _inquiryItemQty(item),
        ),
      ),
    );
  }

  String _currentInquiryReference() {
    return _firstNonEmptyString([
          _existingRawData?['inquiryNumber'],
          widget.existingInquiry?.inquiryNumber,
          widget.existingInquiry?.id,
          widget.existingDoc?.id,
        ]) ??
        '';
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
