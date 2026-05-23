class InquiryEpcDetailsModel {
  final String projectName;
  final String siteName;
  final String consultant;
  final String rfqRefNo;
  final String tenderRef;
  final String projectType;
  final String structureType;
  final String materialGrade;
  final String surfaceFinish;
  final String galvanizingThickness;
  final String applicableStandard;
  final String inspectionAgency;
  final String warrantyRequirement;
  final String deliverySchedule;

  const InquiryEpcDetailsModel({
    required this.projectName,
    required this.siteName,
    required this.consultant,
    required this.rfqRefNo,
    required this.tenderRef,
    required this.projectType,
    required this.structureType,
    required this.materialGrade,
    required this.surfaceFinish,
    required this.galvanizingThickness,
    required this.applicableStandard,
    required this.inspectionAgency,
    required this.warrantyRequirement,
    required this.deliverySchedule,
  });

  factory InquiryEpcDetailsModel.empty() {
    return const InquiryEpcDetailsModel(
      projectName: '',
      siteName: '',
      consultant: '',
      rfqRefNo: '',
      tenderRef: '',
      projectType: '',
      structureType: '',
      materialGrade: '',
      surfaceFinish: '',
      galvanizingThickness: '',
      applicableStandard: '',
      inspectionAgency: '',
      warrantyRequirement: '',
      deliverySchedule: '',
    );
  }

  factory InquiryEpcDetailsModel.fromMap(Map<String, dynamic> map) {
    return InquiryEpcDetailsModel(
      projectName: (map['projectName'] ?? '').toString(),
      siteName: (map['siteName'] ?? '').toString(),
      consultant: (map['consultant'] ?? '').toString(),
      rfqRefNo: (map['rfqRefNo'] ?? '').toString(),
      tenderRef: (map['tenderRef'] ?? '').toString(),
      projectType: (map['projectType'] ?? '').toString(),
      structureType: (map['structureType'] ?? '').toString(),
      materialGrade: (map['materialGrade'] ?? '').toString(),
      surfaceFinish: (map['surfaceFinish'] ?? '').toString(),
      galvanizingThickness: (map['galvanizingThickness'] ?? '').toString(),
      applicableStandard: (map['applicableStandard'] ?? '').toString(),
      inspectionAgency: (map['inspectionAgency'] ?? '').toString(),
      warrantyRequirement: (map['warrantyRequirement'] ?? '').toString(),
      deliverySchedule: (map['deliverySchedule'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectName': projectName,
      'siteName': siteName,
      'consultant': consultant,
      'rfqRefNo': rfqRefNo,
      'tenderRef': tenderRef,
      'projectType': projectType,
      'structureType': structureType,
      'materialGrade': materialGrade,
      'surfaceFinish': surfaceFinish,
      'galvanizingThickness': galvanizingThickness,
      'applicableStandard': applicableStandard,
      'inspectionAgency': inspectionAgency,
      'warrantyRequirement': warrantyRequirement,
      'deliverySchedule': deliverySchedule,
    };
  }
}
