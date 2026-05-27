import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class JoinCompanyService {
  JoinCompanyService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  String _normalizeText(String? value) {
    return (value ?? '').trim();
  }

  String _normalizeEmail(String? value) {
    return _normalizeText(value).toLowerCase();
  }

  Future<String> createJoinRequestDraft({
    required String inviteCode,
    required String fullName,
    required String email,
  }) async {
    final normalizedInviteCode = _normalizeText(inviteCode).toUpperCase();
    final normalizedFullName = _normalizeText(fullName);
    final emailLower = _normalizeEmail(email);

    if (normalizedInviteCode.isEmpty) {
      throw Exception('Invite code is required.');
    }

    if (normalizedFullName.isEmpty) {
      throw Exception('Full name is required.');
    }

    if (emailLower.isEmpty) {
      throw Exception('Email is required.');
    }

    final callable = _functions.httpsCallable('sendJoinCompanyOtp');

    final result = await callable.call({
      'inviteCode': normalizedInviteCode,
      'fullName': normalizedFullName,
      'email': emailLower,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final draftId = _normalizeText(data['draftId']);

    if (draftId.isEmpty) {
      throw Exception('Draft ID not returned from server.');
    }

    await _deleteLegacyJoinRequestSecrets(draftId);

    return draftId;
  }

  Future<void> resendJoinRequestOtp({required String draftId}) async {
    final normalizedDraftId = _normalizeText(draftId);
    if (normalizedDraftId.isEmpty) {
      throw Exception('Draft ID is required.');
    }

    final callable = _functions.httpsCallable('resendJoinCompanyOtp');
    await callable.call({'draftId': normalizedDraftId});
    await _deleteLegacyJoinRequestSecrets(normalizedDraftId);
  }

  Future<void> verifyJoinRequestOtpAndComplete({
    required String draftId,
    required String otp,
    required String password,
  }) async {
    final normalizedDraftId = _normalizeText(draftId);
    final normalizedOtp = _normalizeText(otp);

    if (normalizedDraftId.isEmpty) {
      throw Exception('Draft ID is required.');
    }

    if (normalizedOtp.isEmpty) {
      throw Exception('OTP is required.');
    }

    if (password.isEmpty) {
      throw Exception('Password is required.');
    }

    final callable = _functions.httpsCallable('verifyJoinCompanyOtp');

    final result = await callable.call({
      'draftId': normalizedDraftId,
      'otp': normalizedOtp,
      'password': password,
    });

    await _deleteLegacyJoinRequestSecrets(normalizedDraftId);

    final data = Map<String, dynamic>.from(result.data as Map);

    final email = _normalizeEmail(data['email']);
    final companyId = _normalizeText(data['companyId']);

    if (email.isEmpty || companyId.isEmpty) {
      throw Exception('Incomplete verification response from server.');
    }

    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> _deleteLegacyJoinRequestSecrets(String draftId) async {
    final normalizedDraftId = draftId.trim();
    if (normalizedDraftId.isEmpty) return;

    try {
      await _firestore
          .collection('join_company_requests')
          .doc(normalizedDraftId)
          .update({'password': FieldValue.delete()});
      debugPrint('JoinCompanyService: cleaned legacy join request secrets');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') return;
      debugPrint('JoinCompanyService: legacy join cleanup skipped: ${e.code}');
    } catch (e) {
      debugPrint('JoinCompanyService: legacy join cleanup skipped');
    }
  }
}
