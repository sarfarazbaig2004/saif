import 'package:QUIK/modules/engineering/bom/models/engineering_bom_line_model.dart';

class EngineeringBomQuotationSeed {
  const EngineeringBomQuotationSeed._();

  static Map<String, dynamic> build({
    required String format,
    required String bomId,
    required String bomNo,
    required String inquiryId,
    required String customer,
    required String project,
    required double totalProjectWeight,
    required List<EngineeringBomLineModel> lines,
  }) {
    return {
      'source': 'Engineering BOM',
      'quotationFormat': format,
      'engineeringBomId': bomId,
      'engineeringBomNo': bomNo,
      'inquiryId': inquiryId,
      'inquiryNumber': inquiryId,
      'customerName': customer,
      'subject': project.isEmpty ? 'Engineering BOM $bomNo' : project,
      'notes': 'Generated from Engineering BOM $bomNo',
      'products': format == 'bomDetailed'
          ? _detailed(bomId, lines)
          : [_commercial(bomId, bomNo, project, totalProjectWeight, lines)],
    };
  }

  static Map<String, dynamic> _commercial(
    String bomId,
    String bomNo,
    String project,
    double totalProjectWeight,
    List<EngineeringBomLineModel> lines,
  ) {
    final description = lines
        .map((line) => line.itemDescription)
        .where((value) => value.trim().isNotEmpty)
        .join(', ');
    return {
      'id': 'bom-commercial-$bomId',
      'productId': '',
      'name': project.isEmpty ? 'Engineering BOM $bomNo' : project,
      'description': description,
      'quantity': totalProjectWeight,
      'uom': 'KG',
      'unit': 'KG',
      'rate': 0.0,
      'unitPrice': 0.0,
      'gstPercentage': 18.0,
      'quotationLineType': 'commercial',
    };
  }

  static List<Map<String, dynamic>> _detailed(
    String bomId,
    List<EngineeringBomLineModel> lines,
  ) {
    return lines
        .map((line) {
          return {
            'id': 'bom-$bomId-${line.lineNo}',
            'productId': '',
            'name': line.section.isEmpty ? line.itemDescription : line.section,
            'description': line.material.isEmpty
                ? line.itemDescription
                : '${line.itemDescription}\nMaterial: ${line.material}',
            'quantity': line.totalProjectWeight > 0
                ? line.totalProjectWeight
                : line.calculatedWeight,
            'uom': 'KG',
            'unit': 'KG',
            'rate': 0.0,
            'unitPrice': 0.0,
            'gstPercentage': 18.0,
            'quotationLineType': 'bomDetailed',
            'bomSection': line.section,
            'bomMaterial': line.material,
            'bomLengthMm': line.lengthMm,
            'bomWeight': line.calculatedWeight,
            'bomTotalProjectWeight': line.totalProjectWeight,
          };
        })
        .toList(growable: false);
  }
}
