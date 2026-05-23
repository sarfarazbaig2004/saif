import 'package:flutter/material.dart';

class AddInquiryControllers {
  final subject = TextEditingController();
  final sourceRef = TextEditingController();
  final expectedValue = TextEditingController();
  final budget = TextEditingController();
  final deliveryTimeline = TextEditingController();
  final projectSiteLocation = TextEditingController();
  final competitor = TextEditingController();
  final decisionMaker = TextEditingController();
  final notes = TextEditingController();
  final internalNotes = TextEditingController();
  final lastFollowUpNote = TextEditingController();
  final linkedQuotationId = TextEditingController();
  final lossReason = TextEditingController();
  final tag = TextEditingController();
  final customerSearch = TextEditingController();

  void dispose() {
    subject.dispose();
    sourceRef.dispose();
    expectedValue.dispose();
    budget.dispose();
    deliveryTimeline.dispose();
    projectSiteLocation.dispose();
    competitor.dispose();
    decisionMaker.dispose();
    notes.dispose();
    internalNotes.dispose();
    lastFollowUpNote.dispose();
    linkedQuotationId.dispose();
    lossReason.dispose();
    tag.dispose();
    customerSearch.dispose();
  }
}
