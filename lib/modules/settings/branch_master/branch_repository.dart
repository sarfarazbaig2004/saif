import 'package:cloud_firestore/cloud_firestore.dart';

import 'branch_model.dart';

class DuplicateBranchException implements Exception {
  final String message;

  const DuplicateBranchException(this.message);
}

class BranchRepository {
  final String companyId;
  final FirebaseFirestore _firestore;

  BranchRepository({required this.companyId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _branches => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('branches');

  Stream<List<BranchModel>> watchBranches() {
    return _branches.snapshots().map((snapshot) {
      final branches = snapshot.docs
          .map(BranchModel.fromFirestore)
          .where((branch) => !branch.isDeleted)
          .toList();
      branches.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return branches;
    });
  }

  Future<void> addBranch({
    required String name,
    required String code,
    required String description,
    required bool isActive,
    required String userId,
  }) async {
    final normalizedName = name.trim().toLowerCase();
    final normalizedCode = code.trim().toLowerCase();

    final results = await Future.wait([
      _branches.where('nameNormalized', isEqualTo: normalizedName).limit(1).get(),
      _branches.where('codeNormalized', isEqualTo: normalizedCode).limit(1).get(),
      _branches.get(),
    ]);
    final nameMatch = results[0];
    final codeMatch = results[1];
    final allBranches = results[2];

    final legacyNameMatch = allBranches.docs.any((doc) {
      final data = doc.data();
      return data['isDeleted'] != true &&
          (data['name'] ?? '').toString().trim().toLowerCase() == normalizedName;
    });
    final legacyCodeMatch = allBranches.docs.any((doc) {
      final data = doc.data();
      return data['isDeleted'] != true &&
          (data['code'] ?? '').toString().trim().toLowerCase() == normalizedCode;
    });

    if (nameMatch.docs.any((doc) => doc.data()['isDeleted'] != true) ||
        legacyNameMatch) {
      throw const DuplicateBranchException('A branch with this name already exists.');
    }
    if (codeMatch.docs.any((doc) => doc.data()['isDeleted'] != true) ||
        legacyCodeMatch) {
      throw const DuplicateBranchException('A branch with this code already exists.');
    }

    final document = _branches.doc(normalizedCode);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(document);
      if (existing.exists) {
        throw const DuplicateBranchException('A branch with this code already exists.');
      }
      transaction.set(
        document,
        BranchModel(
          id: document.id,
          name: name.trim(),
          code: code.trim().toUpperCase(),
          description: description.trim(),
          isActive: isActive,
          createdBy: userId,
          updatedBy: userId,
        ).toMap(),
      );
    });
  }
}
