import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerFollowupModel {
  static const List<String> followUpTypes = [
    'Call',
    'Meeting',
    'Site Visit',
    'Email',
    'WhatsApp',
    'Proposal',
    'Payment',
    'Other',
  ];

  static const List<String> statuses = [
    'Open',
    'In Progress',
    'Closed',
    'Missed',
  ];

  static const List<String> priorities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  final String id;
  final String title;
  final String description;
  final DateTime followUpDate;
  final String followUpType;
  final String priority;
  final String status;
  final String assignedTo;
  final DateTime? reminderDate;
  final String nextAction;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String createdByUid;

  const CustomerFollowupModel({
    required this.id,
    required this.title,
    required this.description,
    required this.followUpDate,
    required this.followUpType,
    required this.priority,
    required this.status,
    required this.assignedTo,
    this.reminderDate,
    required this.nextAction,
    this.createdAt,
    this.updatedAt,
    required this.createdBy,
    required this.createdByUid,
  });

  factory CustomerFollowupModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime toDateTime(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? toDateTimeOpt(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return CustomerFollowupModel(
      id: id,
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      followUpDate: toDateTime(map['followUpDate']),
      followUpType: (map['followUpType'] ?? '').toString(),
      priority: (map['priority'] ?? 'Medium').toString(),
      status: (map['status'] ?? 'Open').toString(),
      assignedTo: (map['assignedTo'] ?? '').toString(),
      reminderDate: toDateTimeOpt(map['reminderDate']),
      nextAction: (map['nextAction'] ?? '').toString(),
      createdAt: toDateTimeOpt(map['createdAt']),
      updatedAt: toDateTimeOpt(map['updatedAt']),
      createdBy: (map['createdBy'] ?? map['createdByName'] ?? '').toString(),
      createdByUid: (map['createdByUid'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'followUpDate': Timestamp.fromDate(followUpDate),
      'followUpType': followUpType,
      'priority': priority,
      'status': status,
      'assignedTo': assignedTo,
      'reminderDate':
          reminderDate != null ? Timestamp.fromDate(reminderDate!) : null,
      'nextAction': nextAction,
      'createdBy': createdBy,
      'createdByUid': createdByUid,
    };
  }
}
