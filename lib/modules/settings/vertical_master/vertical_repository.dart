import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'vertical_model.dart';

class DuplicateVerticalException implements Exception {
  final String message;

  const DuplicateVerticalException(this.message);
}

class VerticalRepository {
  final String companyId;
  final FirebaseFirestore _firestore;

  VerticalRepository({required this.companyId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _verticals => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('verticals');

  Stream<List<VerticalModel>> watchVerticals() {
    return _verticals.snapshots().map((snapshot) {
      final verticals = snapshot.docs
          .map(VerticalModel.fromFirestore)
          .where((vertical) => !vertical.isDeleted)
          .toList();
      verticals.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return verticals;
    });
  }

  Future<void> addVertical({
    required String name,
    required List<String> factoryIds,
    required List<String> factoryNames,
    required String userId,
  }) async {
    final normalizedName = name.trim().toLowerCase();
    if (factoryIds.isEmpty) {
      throw ArgumentError('Select at least one factory.');
    }
    final documentId = base64Url
        .encode(utf8.encode(normalizedName))
        .replaceAll('=', '');
    final document = _verticals.doc(documentId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(document);
      if (existing.exists) {
        throw const DuplicateVerticalException(
          'A vertical with this name already exists.',
        );
      }
      transaction.set(
        document,
        VerticalModel(
          id: document.id,
          name: name.trim(),
          factoryIds: List<String>.from(factoryIds),
          factoryNames: List<String>.from(factoryNames),
          createdBy: userId,
          updatedBy: userId,
        ).toMap(),
      );
    });
  }
}
