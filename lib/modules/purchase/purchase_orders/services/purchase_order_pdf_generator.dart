import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:QUIK/modules/purchase/purchase_orders/models/purchase_order_model.dart';

class PurchaseOrderPdfGenerator {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _moneyFormat = NumberFormat('#,##0.00', 'en_IN');

  static final PdfColor _primaryColor = PdfColor.fromInt(0xFF111827);
  static final PdfColor _accentColor = PdfColor.fromInt(0xFF2563EB);
  static final PdfColor _mutedColor = PdfColor.fromInt(0xFF667085);
  static final PdfColor _borderColor = PdfColor.fromInt(0xFFE4E7EC);
  static final PdfColor _softBgColor = PdfColor.fromInt(0xFFF8FAFC);

  static Future<Map<String, dynamic>> fetchCompanyData({
    required String tenantId,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(tenantId)
        .get();
    return doc.data() ?? const <String, dynamic>{};
  }

  static Future<Uint8List> buildPdf({
    required PurchaseOrderModel order,
    required Map<String, dynamic> companyData,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final doc = pw.Document();

    pw.ImageProvider? logoImage;
    final logoUrl = _text(companyData['logoUrl']);
    if (logoUrl.isNotEmpty) {
      try {
        logoImage = await networkImage(logoUrl);
      } catch (_) {}
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(34),
        build: (context) => [
          _header(order, companyData, logoImage),
          pw.SizedBox(height: 14),
          pw.Container(height: 1.4, color: _accentColor),
          pw.SizedBox(height: 18),
          _infoSection(order),
          pw.SizedBox(height: 16),
          _itemTable(order),
          pw.SizedBox(height: 14),
          _totalSection(order),
          pw.SizedBox(height: 14),
          if (order.attachments.isNotEmpty) _attachmentsSection(order),
          if (order.attachments.isNotEmpty) pw.SizedBox(height: 14),
          _termsSection(),
          pw.SizedBox(height: 22),
          _signatureSection(companyData),
        ],
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _borderColor)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Purchase Order • ${order.poNumber}',
                style: pw.TextStyle(fontSize: 8, color: _mutedColor),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: _mutedColor),
              ),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(
    PurchaseOrderModel order,
    Map<String, dynamic> companyData,
    pw.ImageProvider? logoImage,
  ) {
    final companyName = _text(
      companyData['entityName'] ??
          companyData['companyName'] ??
          companyData['name'],
    );
    final address = _text(companyData['address']);
    final gst = _text(companyData['gstin'] ?? companyData['gstNo']);
    final pan = _text(companyData['pan']);
    final email = _text(companyData['email']);
    final phone = _text(companyData['phone']);

    final ids = <String>[];
    if (gst.isNotEmpty) ids.add('GSTIN: $gst');
    if (pan.isNotEmpty) ids.add('PAN: $pan');

    final contacts = <String>[];
    if (phone.isNotEmpty) contacts.add('Ph: $phone');
    if (email.isNotEmpty) contacts.add('Email: $email');

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logoImage != null) ...[
          pw.Container(
            width: 54,
            height: 54,
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderColor),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyName.isEmpty
                    ? 'AMAN INFRA DEVELOPER'
                    : companyName.toUpperCase(),
                style: pw.TextStyle(
                  color: _primaryColor,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  address,
                  style: pw.TextStyle(fontSize: 9, color: _mutedColor),
                ),
              ],
              if (ids.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text(
                  ids.join('  |  '),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
              if (contacts.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  contacts.join('  |  '),
                  style: pw.TextStyle(fontSize: 9, color: _mutedColor),
                ),
              ],
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'PURCHASE ORDER',
              style: pw.TextStyle(
                color: _accentColor,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            pw.SizedBox(height: 6),
            _statusBadge(order.status),
          ],
        ),
      ],
    );
  }

  static pw.Widget _statusBadge(String status) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _softBgColor,
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(999),
      ),
      child: pw.Text(
        status.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _primaryColor,
        ),
      ),
    );
  }

  static pw.Widget _infoSection(PurchaseOrderModel order) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _card(
            title: 'SUPPLIER / VENDOR',
            children: [
              _strong(
                order.vendorName.isEmpty
                    ? 'Vendor not selected'
                    : order.vendorName,
              ),
              if (order.vendorAddress.trim().isNotEmpty)
                _line(order.vendorAddress),
              if (order.vendorGst.trim().isNotEmpty)
                _line('GSTIN: ${order.vendorGst}'),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _card(
            title: 'PO DETAILS',
            children: [
              _kv('PO No.', order.poNumber),
              _kv('PO Date', _dateFormat.format(order.poDate)),
              _kv('Type', order.purchaseType),
              if (order.expectedDeliveryDate != null)
                _kv(
                  'Expected Delivery',
                  _dateFormat.format(order.expectedDeliveryDate!),
                ),
              _kv(
                'Payment Terms',
                order.paymentTerms.isEmpty ? '-' : order.paymentTerms,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _itemTable(PurchaseOrderModel order) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: _primaryColor,
          borderRadius: const pw.BorderRadius.vertical(
            top: pw.Radius.circular(8),
          ),
        ),
        children: [
          _th('S.No', align: pw.Alignment.center),
          _th('Item / Description', align: pw.Alignment.centerLeft),
          _th('HSN/SAC'),
          _th('Qty'),
          _th('Rate'),
          _th('GST'),
          _th('Amount'),
        ],
      ),
    ];

    for (var i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isOdd ? _softBgColor : PdfColors.white,
            border: pw.Border(
              bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            ),
          ),
          children: [
            _td('${i + 1}', align: pw.Alignment.center),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item.itemName,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (item.description.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      item.description,
                      style: pw.TextStyle(fontSize: 8, color: _mutedColor),
                    ),
                  ],
                ],
              ),
            ),
            _td(item.hsnSac.isEmpty ? '-' : item.hsnSac),
            _td('${_num(item.quantity)} ${item.unit}'),
            _td(_rs(item.rate)),
            _td('${_num(item.gstPercent)}%'),
            _td(_rs(item.totalAmount), bold: true),
          ],
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(35),
          1: pw.FlexColumnWidth(2.3),
          2: pw.FixedColumnWidth(55),
          3: pw.FixedColumnWidth(60),
          4: pw.FixedColumnWidth(70),
          5: pw.FixedColumnWidth(48),
          6: pw.FixedColumnWidth(78),
        },
        children: rows,
      ),
    );
  }

  static pw.Widget _totalSection(PurchaseOrderModel order) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _card(
            title: 'DELIVERY / REMARKS',
            children: [
              _kv(
                'Delivery Address',
                order.deliveryAddress.isEmpty ? '-' : order.deliveryAddress,
              ),
              if (order.remarks.trim().isNotEmpty)
                _kv('Remarks', order.remarks),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Container(
          width: 230,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _softBgColor,
            border: pw.Border.all(color: _borderColor),
            borderRadius: pw.BorderRadius.circular(9),
          ),
          child: pw.Column(
            children: [
              _amountRow('Subtotal', order.subtotal),
              pw.SizedBox(height: 5),
              _amountRow('GST', order.gstTotal),
              pw.Divider(color: _borderColor),
              _amountRow('Grand Total', order.grandTotal, bold: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _attachmentsSection(PurchaseOrderModel order) {
    return _card(
      title: 'RELATED VENDOR QUOTATION / ATTACHMENTS',
      children: order.attachments
          .map((attachment) => _line('• ${attachment.fileName}'))
          .toList(growable: false),
    );
  }

  static pw.Widget _termsSection() {
    const terms = [
      'Material/service should be supplied as per approved specification and agreed commercial terms.',
      'Supplier invoice must mention this Purchase Order number.',
      'Goods/services are subject to inspection and acceptance by the company.',
      'Payment will be released as per agreed payment terms after document verification.',
    ];

    return _card(
      title: 'TERMS & CONDITIONS',
      children: terms.map((term) => _line('• $term')).toList(growable: false),
    );
  }

  static pw.Widget _signatureSection(Map<String, dynamic> companyData) {
    final companyName = _text(
      companyData['entityName'] ??
          companyData['companyName'] ??
          companyData['name'],
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 230,
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'For ${companyName.isEmpty ? 'Company' : companyName}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 42),
              pw.Container(height: 1, color: _borderColor),
              pw.SizedBox(height: 5),
              pw.Text(
                'Authorized Signatory',
                style: pw.TextStyle(fontSize: 9, color: _mutedColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _card({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              color: _mutedColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(fontSize: 9, color: _mutedColor),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _strong(String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(
      value,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: _primaryColor,
      ),
    ),
  );

  static pw.Widget _line(String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Text(value, style: pw.TextStyle(fontSize: 9, color: _mutedColor)),
  );

  static pw.Widget _th(
    String value, {
    pw.Alignment align = pw.Alignment.centerRight,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      alignment: align,
      child: pw.Text(
        value,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _td(
    String value, {
    bool bold = false,
    pw.Alignment align = pw.Alignment.centerRight,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: align,
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  static pw.Widget _amountRow(
    String label,
    double amount, {
    bool bold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: bold ? 10 : 9,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
        pw.Text(
          _rs(amount),
          style: pw.TextStyle(
            fontSize: bold ? 11 : 9,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  static String _rs(double value) => 'Rs ${_moneyFormat.format(value)}';

  static String _num(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  static String _text(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }
}
