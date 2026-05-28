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
    );
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
