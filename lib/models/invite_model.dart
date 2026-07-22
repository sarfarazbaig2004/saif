class InviteModel {
  final String inviteId;
  final String code;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final bool isActive;
  final Map<String, dynamic> permissions;
  final List<String> allowedModuleIds;
  final int permissionSchemaVersion;
  final String verticalSelectionMode;
  final List<String> verticalIds;
  final String factorySelectionMode;
  final List<String> factoryIds;
  final Map<String, dynamic> verticalPermissions;
  final int verticalPermissionSchemaVersion;
  final String companyId;
  final String companyName;
  final String createdByUid;
  final String acceptedByUid;

  InviteModel({
    required this.inviteId,
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.isActive,
    required this.permissions,
    required this.allowedModuleIds,
    required this.permissionSchemaVersion,
    required this.verticalSelectionMode,
    required this.verticalIds,
    required this.factorySelectionMode,
    required this.factoryIds,
    required this.verticalPermissions,
    required this.verticalPermissionSchemaVersion,
    required this.companyId,
    required this.companyName,
    required this.createdByUid,
    required this.acceptedByUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'inviteId': inviteId,
      'code': code,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'isActive': isActive,
      'permissions': permissions,
      'allowedModuleIds': allowedModuleIds,
      'permissionSchemaVersion': permissionSchemaVersion,
      'verticalSelectionMode': verticalSelectionMode,
      'verticalIds': verticalIds,
      'factorySelectionMode': factorySelectionMode,
      'factoryIds': factoryIds,
      'verticalPermissions': verticalPermissions,
      'verticalPermissionSchemaVersion': verticalPermissionSchemaVersion,
      'companyId': companyId,
      'companyName': companyName,
      'createdByUid': createdByUid,
      'acceptedByUid': acceptedByUid,
    };
  }

  factory InviteModel.fromMap(Map<String, dynamic> map) {
    return InviteModel(
      inviteId: (map['inviteId'] ?? '').toString(),
      code: (map['code'] ?? '').toString().toUpperCase(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: (map['role'] ?? 'sales').toString(),
      status: (map['status'] ?? 'pending').toString(),
      isActive: map['isActive'] ?? true,
      permissions: Map<String, dynamic>.from(map['permissions'] ?? {}),
      allowedModuleIds: map['allowedModuleIds'] is Iterable
          ? (map['allowedModuleIds'] as Iterable)
                .map((value) => value.toString())
                .toSet()
                .toList()
          : const [],
      permissionSchemaVersion:
          (map['permissionSchemaVersion'] as num?)?.toInt() ?? 0,
      verticalSelectionMode: _readSelectionMode(map['verticalSelectionMode']),
      verticalIds: _readStringList(map['verticalIds']),
      factorySelectionMode: _readSelectionMode(map['factorySelectionMode']),
      factoryIds: _readStringList(map['factoryIds']),
      verticalPermissions: _readMap(map['verticalPermissions']),
      verticalPermissionSchemaVersion:
          (map['verticalPermissionSchemaVersion'] as num?)?.toInt() ?? 0,
      companyId: (map['companyId'] ?? '').toString(),
      companyName: (map['companyName'] ?? '').toString(),
      createdByUid: (map['createdByUid'] ?? '').toString(),
      acceptedByUid: (map['acceptedByUid'] ?? '').toString(),
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! Iterable || value is String) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  static String _readSelectionMode(dynamic value) {
    return value?.toString().trim().toLowerCase() == 'single'
        ? 'single'
        : 'multiple';
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map(
        (key, item) => MapEntry(key, item is Map ? _readMap(item) : item),
      );
    }
    if (value is Map) {
      return value.map(
        (key, item) =>
            MapEntry(key.toString(), item is Map ? _readMap(item) : item),
      );
    }
    return <String, dynamic>{};
  }
}
