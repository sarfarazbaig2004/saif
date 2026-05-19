# QUIK ERP Flutter Architecture Rules

## Core Principles

1. No screen should exceed 300 lines unless it is orchestration-only.
2. Business logic must never live inside UI widgets.
3. Firestore/database access only through services.
4. Complex forms must use DTO/Draft objects.
5. Controllers lifecycle must be isolated from screens.
6. Async operations must be moved into handlers/services.
7. Reusable UI must live inside form_widgets or shared widgets.
8. ERP entities must support audit trail expansion later.
9. Save flows must support future approval workflow integration.
10. Every ERP document must be state-driven.

---

## Folder Structure

screens/
→ orchestration only

form_widgets/
→ reusable UI components

form_services/
→ business logic, save handlers, factories, builders

models/
→ firestore/database models

providers/
→ UI state management only

---

## Naming Standards

Screen:
screen_customer_po.dart

Service:
customer_po_save_service.dart

Factory:
customer_po_form_draft_factory.dart

DTO:
customer_po_form_draft.dart

Builder:
customer_po_form_builder.dart

Handler:
customer_po_form_save_handler.dart

---

## ERP Engineering Rules

1. Every module must support:
   - approvals
   - audit trail
   - attachments
   - comments
   - activity timeline
   - role permissions

2. All IDs must be future multi-tenant safe.

3. No direct Firestore calls inside widgets.

4. All calculations must be centralized.

5. UI must remain replaceable without affecting business logic.

---

## Quality Gates

Before every push:

- flutter analyze
- dart format lib
- ./tool/check_file_lengths.sh

No warnings.
No dead imports.
No duplicated logic.

---

## Architecture Goal

QUIK ERP is not a Flutter app.

It is an ERP operating system with:
- modular architecture
- scalable business logic
- audit-ready workflows
- AI-readable code structure
- IPO-grade engineering discipline
