# RDMS Ultimate Feature Implementation Plan

> **Status:** Proposed, source-grounded roadmap. No application changes are authorized or implemented by this document.
> **For implementation:** Approve one phase at a time, then execute its checkboxes in dependency order. Preserve existing data and offline functionality. Do not automatically commit, deploy, change OAuth scopes, or migrate live databases.

**Goal:** Develop RDMS Ultimate from a local document library with optional Google Drive backup into a dependable, searchable records workspace, with secure cross-device access and optional organizational workflows.

**Architecture:** Keep Flutter/Riverpod, Drift/SQLite, managed local files, the Express metadata API, PostgreSQL, and direct Google Drive integration. Add recoverable local operations and durable synchronization before expanding into collaboration. Treat local storage, cloud backup, metadata replication, and document lifecycle as separate concerns.

**Tech stack:** Dart/Flutter Material 3, Riverpod 3, Drift/SQLite FTS5, Dio, Google Sign-In, secure credential storage, Node.js/TypeScript, Express, Zod, PostgreSQL 16, and Docker Compose.

---

## 1. Examination Scope and Confidence

This plan examines the project's first-party client feature areas, storage/database/authentication/sync services, server routes and repositories, schemas, test sources, platform configuration, deployment configuration, privacy policy, and existing plans.

- Code and configuration describe the current implementation. Older plans describe intent, not proof that a feature exists.
- Generated Dart bindings, build output, vendored dependencies, and platform boilerplate are not treated as independent product features.
- Secret `.env` contents and user documents were not needed for this examination.
- This is a static assessment, not a penetration test or production certification. Application tests, device builds, Google OAuth, real Drive transfers, and database deployment were not run. IDE diagnostics were unavailable because the language server was not ready.
- The Git check resolved to a parent repository with no commits and this project untracked. A project-scoped history/baseline is not established by this assessment; do not initialize or commit inside the parent repository without confirming the intended boundary.
- Current-state architecture was examined using the system-modeler workflow; the proposed sequencing uses the evolution-planner and writing-plans workflows.

## 2. Project Purpose and How It Works Today

### 2.1 Product purpose

RDMS Ultimate is an **offline-first document organization and backup application**. Its model and default categories are oriented toward Indonesian office/government records: decisions, reports, meeting minutes, technical documents, and regulations.

The practical user journey is: **import a file → describe it → find/open it locally → optionally back it up to a personal Google Drive account**. An optional server maintains a searchable metadata index; it does not store document binaries.

The current operating model is one local library per application installation. There is no application-user ownership, organization, membership, role, or access-control model in the server schema. Google Sign-In grants Drive access; it is not backend authentication.

### 2.2 Confirmed architecture and data responsibilities

| Component | Current responsibility | Important boundary |
| --- | --- | --- |
| Flutter client | Import form, explorer, filters/sorting, details, command palette, cloud controls | Primary usable interface; core browsing does not require the server |
| Drift/SQLite | Local metadata, Drive IDs, sync status, FTS5 index | One document table plus search structures; no versions, durable job table, or tombstones |
| Managed local directory | Copied document binaries with sanitized generated filenames | Metadata database is separate from the selected document directory |
| Google Drive API | Upload, status lookup, rename, trash/permanent delete | Uses the signed-in user's credentials and `drive.file` scope |
| Express/PostgreSQL | Metadata batch upsert, hash reconciliation, category/list/detail/search APIs | No file upload/download service and no authenticated record ownership |
| Docker Compose | Local PostgreSQL and API deployment | Host ports are loopback-bound; this is not a complete production deployment |

### 2.3 Existing functions: preserve and extend

| Function | Current behavior | Evidence |
| --- | --- | --- |
| Import | One picked file, title, document number, category, document date, fiscal year, optional manually supplied text | E01 |
| Local storage | Copy file, generate managed filename, detect common MIME headers, compute SHA-256 in an isolate | E02 |
| Local search | SQLite FTS5 over title, number, category, and supplied extracted text | E03 |
| Browsing | Reactive document list; composed search/category/year/status filtering; four sort modes; summary counts | E04 |
| Adaptive UI | Compact, medium, desktop-width, and wide layouts; system light/dark themes; details shown according to available space | E05 |
| Command palette | Ctrl/Cmd+K, `tahun:`, `kategori:`, `nama:`, import/upload/storage actions | E06 |
| Details and opening | Metadata, indexed text, checksum/path information, external open/open-with/folder actions | E07 |
| Google connection | Interactive/silent sign-in, secure-storage-backed tokens, configurable folder and backend URL | E08 |
| Backup | Single/bulk queue initiation; up to two workers; Drive resumable-upload endpoint | E09 |
| Cloud maintenance | Check tracked file existence/name/trash state; rename; trash or permanently delete a Drive copy | E09 |
| Local deletion | Confirmation followed by local file and metadata deletion; remote copy deliberately unaffected | E10 |
| Backend metadata | Transactional batch upsert by client ID; hash comparison; PostgreSQL full-text search; category/list/detail endpoints | E11 |
| Test assets | Storage/FTS, mocked sync, provider state, responsive UI, import form, overflow/opening, and backend use-case tests | E12 |

### 2.4 End-to-end behavior and limitations

**Import and find:** The form passes a native file path to the repository. Storage copies the binary, computes metadata/hash, and the repository inserts a local row with `local_only`. SQLite triggers maintain FTS5. The UI observes local rows and can open the binary in an external application.

**Backup:** A user action marks rows `queued`. The running application processes a snapshot of queued documents, uploads each binary to Drive, attempts a metadata POST, and records the Drive ID with `synced`. Backend submission errors are swallowed, so **`synced` does not prove that PostgreSQL has the metadata**.

**Cloud verification:** Refresh checks already-known Drive IDs for name/existence/trash state. A name mismatch is labeled `lost`; a 404 is labeled `deleted`. This is not content-integrity verification, a remote change feed, or recovery of a library on another device.

**Deletion:** Local deletion removes the row and managed file; Drive deletion is a separate action. There is no local recycle bin, restoration flow, or backend deletion propagation.

**Current API surface:** `GET /api/v1/health`, `POST /api/v1/sync/batch-metadata`, `POST /api/v1/sync/reconcile`, `GET /api/v1/documents`, `GET /api/v1/documents/search`, `GET /api/v1/documents/categories`, and `GET /api/v1/documents/:id`.

**Product maturity:** A functional local-library/backup foundation, not yet a complete multi-device DMS, team workspace, or governed records archive.

## 3. Most Important Improvement Opportunities

| Priority | Evidence-backed gap | User consequence | Planned response |
| --- | --- | --- | --- |
| P0 | Local deletion removes metadata even when the file deletion helper reports failure; there is no trash or restore flow [E10] | Accidental loss, orphaned files, or loss of the Drive reference needed for recovery | Phase 1 |
| P0 | Custom storage path is held in memory; selecting another path does not migrate existing files [E02, E04] | Restart/configuration changes can produce a split library and confusing file locations | Phase 1 |
| P0 | One status represents several destinations; backend errors are ignored [E09] | A reassuring backup badge can conceal missing server metadata | Phase 2 |
| P0 | Upload session URI/offset are not persisted; one stream sends the binary; queue recovery is not wired at startup [E09, E13] | Interrupted work cannot reliably resume after application termination | Phase 2 |
| P0 | No backend authentication/ownership; reconciliation compares only hashes [E11] | Any client able to reach the API can access its records; same-content metadata edits are not reconciled | Phases 2–3 |
| P0 for release | Fixed development DB credentials, raw error responses, no release signing configuration, and incomplete privacy descriptions [E08, E14, E15] | Deployment and privacy claims are not ready for sensitive records | Phases 0, 3, 9 |
| P1 | No general metadata editor, bulk importer, duplicate workflow, tags, favorites, or collections [E01, E03, E07] | Repetitive filing and difficult correction/organization | Phase 4 |
| P1 | Text extraction is manual; the preview panel is a details panel, not an embedded reader [E01, E07] | Scans cannot be searched automatically; users repeatedly switch applications | Phase 5 |
| P1 | No Drive download/restore or client consumption of server listings/change feeds [E08, E09, E11] | A cloud copy alone cannot rebuild the full working library | Phase 6 |
| P1 | No document revisions, lifecycle history, or authoritative audit trail [E03, E11] | Changes overwrite context; previous approved records cannot be reconstructed | Phase 7 |
| P2 | No team memberships, file sharing policy, review assignments, or retention controls [E11] | Unsuitable for organizational approval/archival processes | Phase 8, optional |
| P1 | Current UI materializes the full library; tests mock cloud/backend operations [E04, E12] | Large-library behavior and real integration reliability remain unproven | Phases 5, 9 |

P0 protects data, truthful state, or access boundaries. P1 materially improves routine document work. P2 is conditional expansion, not an MVP requirement.

### Do not plan already-built features as new work

Retain and regression-test responsive layout, dark mode, combined filtering, sorting, command palette, SHA-256, filename sanitization, single/bulk backup, Drive rename/delete, empty states, and explicit debug-only sample loading. The older UI plan's baseline observations are partly superseded by current code. This roadmap complements that plan rather than repeating a homepage redesign.

## 4. Recommended Product Direction

| Approach | Benefits | Trade-off | Recommendation |
| --- | --- | --- | --- |
| Dependable local-first workspace | Preserves the strongest existing behavior; helps users immediately; limits deployment complexity | Team processes arrive later | **Selected baseline** |
| Team/workflow platform first | Fits a department-wide deployment | Requires identity, permissions, file ownership, synchronization, and governance before safe use | Enable only after foundational gates |
| AI/OCR-first expansion | Better discovery and reduced data entry | Increases processing/privacy complexity without solving recoverability | Add bounded OCR after storage/sync reliability; defer generative AI |

### Planning assumptions

- Preserve Indonesian product terminology and sapphire branding; localization infrastructure may be added without redesigning the application.
- Local-only mode remains supported. No mandatory Google account or backend login for a private offline library.
- Android is the first physical-device release target because a runner is present. iOS requires separate macOS/device verification. Desktop-width layouts are not evidence of packaged desktop support.
- Personal Google Drive remains the default binary-backup provider. Do not broaden Drive scopes automatically.
- A production backend requires authenticated ownership even if there is only one initial user.
- Organizational workflows are opt-in expansion. Specific legal retention periods, identity-provider registration, signing credentials, and deployment hosts require owner-supplied configuration; do not invent them.

## 5. Phase Overview and Dependencies

Effort labels are relative scope, not delivery-date promises: **S** = bounded work, **M** = several coordinated components, **L** = a substantial cross-layer feature, **XL** = a separate product increment.

| Phase | Outcome | Priority | Depends on | Effort |
| --- | --- | --- | --- | --- |
| 0 | Verified baseline and safe migration/configuration boundaries | P0 | None | M |
| 1 | Recoverable local library and portable backup | P0 | 0 | L |
| 2 | Durable sync, resumable transfers, and honest status | P0 | 0–1 | L |
| 3 | Authenticated personal backend and privacy controls | P0 when backend enabled | 0; integrate with 2 | L |
| 4 | Metadata editing, organization, and bulk productivity | P1 | 1–2 | L |
| 5 | Embedded reading, OCR, and scalable discovery | P1 | 4 | L |
| 6 | Cloud restore and conflict-safe cross-device library | P1 | 1–3; support 4 fields | L |
| 7 | Version history and auditable document lifecycle | P1 | 2–3, 6 | L |
| 8 | Team sharing, approvals, reminders, and retention | P2, conditional | 3, 6–7 | XL |
| 9 | Production operations and verified platform delivery | Release gate | 0 onward; selected features complete | L |

Execute in this sequence by default. Phase 3 can start after Phase 0 and must finish before exposing metadata beyond the development boundary. Phase 9's CI, instrumentation, and device checks start early; its final acceptance gates each release, not just the last phase.

---

## Phase 0 — Baseline, Migrations, and Safe Configuration

**Outcome:** Later changes can be delivered without guessing the working baseline or risking existing libraries.

### Implementation tasks

- [ ] **0.1 Establish the project baseline.** Confirm the intended Git root, installed Flutter/Dart/Node toolchains against manifests, and current analyzer/test results. Record existing failures separately from newly introduced failures. Keep generated output out of manual edits.
- [ ] **0.2 Introduce ordered database migrations.** Add an `onUpgrade` strategy and schema fixtures for Drift. Replace repeated bootstrap SQL as the long-term PostgreSQL migration mechanism with numbered SQL migrations, a migration ledger, and single-run locking. Preserve `schema.sql` as a fresh-install baseline only.
- [ ] **0.3 Make migration failures visible.** Missing required schema artifacts and failed migrations must block API readiness; do not continue serving as though startup succeeded. Validate development builds and Docker packaging separately.
- [ ] **0.4 Harden existing API input boundaries.** Validate real calendar dates, hexadecimal hashes, document-number lengths, UUID route IDs, integers, and bounded arrays. Use batch size 100 and pagination limits 1–100; reject malformed/negative values instead of passing `NaN` or invalid limits to SQL. Keep all SQL values parameterized.
- [ ] **0.5 Separate development and production configuration.** Require injected production DB credentials, remove usable production defaults, validate startup configuration, and return generic client-facing errors with request IDs. Keep local-only deployment loopback-bound until Phase 3.
- [ ] **0.6 Add baseline regression cases.** Include existing combined filtering/sorting, real empty state, large text, missing-file handling, and copy/insert/delete failure cases. Do not treat sample-data text mentioning a feature as implementation evidence.

**Existing files:** [local database](client/lib/core/database/app_database.dart), [server database setup](server/src/database/db.ts), [server startup](server/src/main.ts), [controller](server/src/modules/documents/delivery/document.controller.ts), [server app](server/src/app.ts), [package scripts](server/package.json), [Dockerfile](server/Dockerfile), [Compose](compose.yaml).

**Proposed files:** `server/src/database/migrate.ts`, `server/src/database/migrations/001_baseline.sql`, `server/src/config.ts`, `client/test/database_migration_test.dart`, `server/src/modules/documents/delivery/document.controller.test.ts`.

**Acceptance gate:** Fresh and existing databases reach the same expected schema without data loss; failed migrations make readiness fail; malformed requests receive controlled 4xx responses; baseline test limitations are recorded honestly.

## Phase 1 — Recoverable Local Storage and Backup

**Outcome:** Users can safely keep, move, delete, and recover their library without Google Drive or the backend.

### Implementation tasks

- [ ] **1.1 Persist storage configuration.** Store a durable storage-root record and a relative managed path for new files. Migrate legacy absolute paths without moving files implicitly. Separate “use this folder for future imports” from “relocate existing library.”
- [ ] **1.2 Add safe relocation.** Preflight permissions/free space, pause affected file operations, copy to a staging destination, verify every checksum, atomically update path references, and retain the original copy until the user confirms successful relocation. Interrupted relocation resumes or rolls back through a journal.
- [ ] **1.3 Make imports recoverable.** Stage file copies and record an import operation before finalizing metadata. A database failure must leave either the original intact with a recoverable staging record or a cleanly rolled-back managed copy. Never delete the user's source file.
- [ ] **1.4 Add a local recycle bin.** Replace ordinary hard deletion with `trashed_at` and a restorable local-file state. Exclude trashed records from default search/list counts. Restore with stable document/Drive IDs. Permanent removal is a separate confirmed action; failed file removal must retain recoverable metadata. No automatic purge in this phase.
- [ ] **1.5 Add export/import of a complete library backup.** Use a versioned archive containing a JSON manifest and managed binaries with SHA-256 checksums. Export a consistent logical database snapshot, not a live SQLite/WAL file copied independently. Include metadata, IDs, paths relative to archive root, and trash state; exclude credentials, absolute device paths, and upload session secrets.
- [ ] **1.6 Validate restores before activation.** Check manifest version, hashes, duplicate IDs, path traversal/symlinks, entry counts, and expanded-size limits. Restore to staging, show a preview, and never overwrite an existing library silently. Clearly warn that the initial portable archive is not encrypted and needs protected storage.
- [ ] **1.7 Add library health checks.** Report missing files, changed file contents, orphaned managed files, inaccessible roots, and failed operations. Offer relink by checksum and reindex. External changes become “needs review,” not silently updated checksums.

**Existing files:** [storage service](client/lib/core/services/storage_service.dart), [repository](client/lib/features/documents/data/repositories/drift_document_repository.dart), [domain model](client/lib/features/documents/domain/models/document_item.dart), [table](client/lib/core/database/tables/local_documents.dart), [storage provider](client/lib/features/documents/presentation/providers/document_providers.dart), [row deletion](client/lib/features/documents/presentation/widgets/document_list_item.dart).

**Proposed files:** `client/lib/core/services/library_backup_service.dart`, `client/lib/core/services/library_integrity_service.dart`, `client/lib/core/database/tables/storage_roots.dart`, `client/lib/core/database/tables/local_operations.dart`, `client/lib/features/recovery/presentation/recovery_screen.dart`, `client/test/library_recovery_test.dart`.

**Acceptance gate:** A restart preserves the chosen location; failed copy/database/delete operations lose no source data; trash/restore preserves IDs and searchability; an exported library restores into a clean installation with matching document counts and binary hashes; malicious archive paths are rejected.

## Phase 2 — Reliable Sync and a Sync Center

**Outcome:** Uploads survive interruption, metadata retries do not re-upload binaries, and users know exactly which copy is current.

### Implementation tasks

- [ ] **2.1 Separate document state from replica state.** Retain document lifecycle and local availability independently. Add destination-specific Drive and backend states: disabled/not configured, pending, running, current, retryable failure, blocked, and conflict. Store the revision/hash acknowledged by each destination and last successful verification time.
- [ ] **2.2 Add a transactional outbox.** In the same SQLite transaction as a document mutation, create durable jobs containing operation ID, document ID, destination, operation kind, content/metadata revision, attempt count, next retry time, and redacted last error. Drive account identity and backend profile are immutable job bindings. Do not execute old jobs under a newly connected account.
- [ ] **2.3 Implement restart-safe queue processing.** Recover expired job leases at startup/resume, continuously claim new eligible jobs, retain the two-worker transfer limit, and deduplicate active operations per document/destination. Retry network/429/5xx failures with capped exponential backoff and jitter; block authorization/permanent validation failures until corrected. Add pause/resume/cancel and retry-failed controls.
- [ ] **2.4 Implement actual resumability.** Persist a protected Drive session reference and acknowledged offset. Query server upload status after interruption, send bounded chunks aligned to Drive's protocol, handle 308/range responses and expired sessions, and report actual resumed bytes. Never label every fresh upload as resumed.
- [ ] **2.5 Prevent duplicate remote files.** Associate application document/operation IDs with Drive app properties. Reuse the intended remote object or reconcile an uncertain completed upload before creating another. Persist the returned file ID before the independent metadata POST. No silent upload to the Drive root if the configured folder cannot be resolved.
- [ ] **2.6 Add revision-aware metadata acknowledgments.** Introduce `/api/v2/sync/batch` with per-operation results: operation ID, server document ID, accepted revision, and applied/conflict/rejected status. Compare `baseRevision`, not just file hashes; metadata-only edits advance revision. Duplicate operation IDs return the original result without applying a second mutation. A conflict preserves pending local data instead of silently overwriting it.
- [ ] **2.7 Correct remote-state semantics.** Treat remote rename as a metadata difference; a 404 can mean inaccessible or missing, not proven permanent deletion. Maintain separate remote filename and physical local path. Queue remote rename/trash operations and their metadata updates with explicit scopes. Do not turn removal of one backup copy into global document deletion.
- [ ] **2.8 Add a Sync Center.** Show destination, per-file byte progress, queue depth, last success, paused/blocked reason, and retry controls. Display “Drive backed up; metadata pending” when appropriate. Keep diagnostics free of tokens, session URLs, local absolute paths, and full extracted text.

**Existing files:** [queue](client/lib/core/services/sync_queue_service.dart), [Drive client](client/lib/core/services/gdrive_service.dart), [backend client](client/lib/core/services/backend_sync_client.dart), [providers](client/lib/features/documents/presentation/providers/document_providers.dart), [status display](client/lib/features/documents/presentation/widgets/sync_status_badge.dart), [PostgreSQL repository](server/src/modules/documents/infra/postgres-document.repository.ts).

**Proposed files:** `client/lib/core/database/tables/sync_jobs.dart`, `client/lib/core/database/tables/document_replicas.dart`, `client/lib/features/sync_center/presentation/sync_center_screen.dart`, `server/src/modules/documents/usecases/apply-sync-operations.usecase.ts`, `client/test/sync_recovery_test.dart`, `server/src/modules/documents/usecases/apply-sync-operations.test.ts`.

**Migration:** Legacy `synced` records a previous Drive upload/check, not current content integrity or backend acknowledgment. Mark backend state unverified/pending and schedule Drive re-verification. Preserve known Drive IDs. Leave v1 available only for controlled migration clients; Phase 3 must secure every retained version before deployment.

**Acceptance gate:** Terminating/restarting the client mid-upload resumes safely; jobs queued during processing are not stranded; backend downtime leaves Drive success intact and retries metadata only; repeated requests create no duplicate records/files; account switching never transfers jobs to the wrong destination.

**Background boundary:** This phase guarantees durable restart and foreground/resume processing. It does not promise execution while the mobile OS has suspended or terminated the app; platform schedulers are a separate Phase 9 gate.

## Phase 3 — Authenticated Backend, Ownership, and Privacy

**Outcome:** Personal metadata sync and retrieval are safe to expose outside a trusted development environment.

### Implementation tasks

- [ ] **3.1 Add application identity.** Use OIDC Authorization Code with PKCE through a configured identity provider. Authorize the API with audience-scoped access tokens, not OIDC ID tokens or Drive access tokens. Validate issuer, audience, signature, expiry, and key rotation using a maintained verifier; use backend session checks or provider introspection for revocation. Local-only mode continues without login.
- [ ] **3.2 Introduce personal workspaces and ownership.** Add users, workspaces, memberships, and workspace-scoped document IDs/operation receipts. A newly authenticated user receives one personal workspace; arbitrary caller-supplied workspace IDs do not grant access.
- [ ] **3.3 Enforce authorization in every repository path.** Scope batch operations, list/detail/search, categories, reconcile, downloads/change feeds added later, and operation status by authorized workspace. Reject cross-workspace IDs. Personal workspaces initially have an owner only; broader roles arrive in Phase 8.
- [ ] **3.4 Migrate existing unowned server records safely.** Quarantine legacy data until an administrator explicitly maps it to the intended owner/workspace. Do not assign all existing documents to the first user who signs in. Back up before ownership migration and verify record counts afterward.
- [ ] **3.5 Add account-scoped local profiles.** Partition metadata, credentials, jobs, and file roots by workspace/account. Switching accounts must not display another account's cache. Define sign-out as credential removal and stopped synchronization; offer a separate explicit action to remove cached files.
- [ ] **3.6 Harden transport/session handling.** Require HTTPS outside loopback development, bounded timeouts, per-identity request throttling, allowlisted browser origins, redacted structured logs, and explicit credential-storage failures. Remove manual token entry from normal release UX; keep any developer diagnostics debug-only.
- [ ] **3.7 Correct privacy disclosures.** Describe email identity access, personal Drive access, optional backend metadata/extracted-text transfer, retention, and separate local/cloud deletion. Remove the unsupported claim that deleting a local document automatically clears all credentials. Provide clear consent and connection testing before enabling backend replication; do not transmit absolute local paths.

**Existing files:** [server app](server/src/app.ts), [controller](server/src/modules/documents/delivery/document.controller.ts), [schema](server/src/database/schema.sql), [backend client](client/lib/core/services/backend_sync_client.dart), [Google auth](client/lib/core/services/google_auth_service.dart), [token storage](client/lib/core/services/token_storage_service.dart), [cloud settings](client/lib/features/documents/presentation/widgets/cloud_sync_settings_modal.dart), [privacy policy](PRIVACY_POLICY.md).

**Proposed files:** `server/src/modules/auth/delivery/auth.middleware.ts`, `server/src/modules/workspaces/domain/workspace.entity.ts`, `client/lib/core/services/backend_auth_service.dart`, `client/lib/features/accounts/presentation/account_settings_screen.dart`, `server/src/modules/documents/delivery/document.authorization.test.ts`.

**Acceptance gate:** Unauthenticated calls fail; two users cannot read or mutate one another's records through any API version; expired/revoked sessions stop sync; local-only use still works; profile switching does not expose another cache; metadata payloads omit local absolute paths.

**Required external configuration:** Approved OIDC issuer/client registration and deployment domain. Without these, retain local/private development mode and do not claim production identity readiness.

## Phase 4 — Everyday Document Productivity

**Outcome:** Filing, correcting, organizing, and exporting records becomes practical for routine office use.

### Implementation tasks

- [ ] **4.1 Add metadata editing.** Edit title, document number, category, document date, fiscal year, notes, and supplied searchable text. Validate consistently with the API, support explicitly clearing nullable values, and guard unsaved changes. Persist locally and queue only affected metadata operations; title changes must not implicitly rename the binary.
- [ ] **4.2 Normalize categories.** Introduce stable category IDs/codes and editable display labels. Provide a reviewed migration map for known casing variants. Preserve ambiguous legacy categories such as `SK` versus `Surat Keputusan` until the user confirms a merge. Archive used categories instead of deleting references. Replace fixed fiscal-year lists with validated entry and years derived from actual records.
- [ ] **4.3 Add tags, favorites, and virtual collections.** Store tags and document-tag relations; collections reference records rather than moving physical files. Favorites are per local profile initially. Every relation must be scoped to the owning library/workspace.
- [ ] **4.4 Add bulk import.** Select multiple files, preview filenames/types/sizes, apply shared defaults, override individual metadata, and show per-file outcomes. Persist batch progress so retries skip completed imports. Preserve `original_file_name` separately from the managed filename.
- [ ] **4.5 Add duplicate detection.** Check content hash within the current workspace before finalizing an import. Offer skip, open existing, or intentionally keep a separate record. Same filenames alone are not duplicates; same bytes may legitimately represent different records. Do not automatically merge or delete either record.
- [ ] **4.6 Add multi-selection operations.** Apply tags/category, queue backup, export selected files, or move selected records to local trash. Show the exact count/scope and per-item failures. Destructive cloud actions remain separate from local organization.
- [ ] **4.7 Add document-register export and saved views.** Export filtered metadata as UTF-8 CSV with spreadsheet-formula escaping; save query/filter/sort presets locally. Import/export/search continue offline. Saved search state does not imply that files have been downloaded.
- [ ] **4.8 Extend metadata persistence end to end.** Add category/tag/collection entities and notes/original filenames to local migrations, the v2 payload schema, PostgreSQL persistence, and portable backup manifests. Queue organization changes independently of binaries. Keep favorites and saved views device-local for this release; when the backend is disabled, all organizational data still survives local backup/restore.

**Existing files:** [import form](client/lib/features/documents/presentation/widgets/add_document_modal.dart), [repository contract](client/lib/features/documents/domain/repositories/document_repository.dart), [repository implementation](client/lib/features/documents/data/repositories/drift_document_repository.dart), [providers](client/lib/features/documents/presentation/providers/document_providers.dart), [toolbar](client/lib/features/documents/presentation/widgets/document_toolbar.dart), [sidebar](client/lib/features/documents/presentation/widgets/document_sidebar.dart), [backend payloads](client/lib/core/services/backend_sync_client.dart), [server entity](server/src/modules/documents/domain/document.entity.ts), [server persistence](server/src/modules/documents/infra/postgres-document.repository.ts).

**Proposed files:** `client/lib/features/documents/presentation/widgets/edit_document_modal.dart`, `client/lib/features/imports/presentation/bulk_import_screen.dart`, `client/lib/core/services/duplicate_detection_service.dart`, `client/lib/core/services/document_export_service.dart`, `client/lib/core/database/tables/document_organization.dart`, `client/test/document_productivity_test.dart`.

**Acceptance gate:** Edits appear immediately in search/details and survive restart; clearing optional fields works; metadata-only edits do not upload binaries; duplicate import requires an explicit choice; a partially failing 100-file batch can resume without repeating completed items; selection scope is unambiguous.

## Phase 5 — Reading, OCR, and Better Discovery

**Outcome:** Users can inspect documents inside RDMS and find records by actual content.

### Implementation tasks

- [ ] **5.1 Add a bounded embedded reader.** Support local PDF viewing and image zoom/rotation; retain external opening for Office and unsupported formats. Load pages/thumbnails lazily, provide text selection/search when available, and handle corrupted/password-protected/missing files without crashing. Keep the existing details surface distinct from the reader.
- [ ] **5.2 Add mobile scan-to-document.** Capture/import multiple pages, rotate/crop/reorder, review quality, and save a PDF through the same recoverable import pipeline. Permission denial and cancellation leave no committed partial record. Desktop capture remains file import until its platform gate is complete.
- [ ] **5.3 Add extraction jobs.** Extract existing PDF/text content first; use on-device OCR for image-only pages on supported mobile platforms. Persist job state and content hash so work is cancelable/retryable and invalidated by binary changes. Store source, language, page mapping, and user corrections separately from the original binary.
- [ ] **5.4 Support Indonesian and English search content.** Make language selection explicit; allow correction of OCR text before accepting it as metadata. Do not silently send document content to an external OCR/AI service. Devices without an approved OCR adapter retain manual text entry and a truthful unavailable state.
- [ ] **5.5 Improve search semantics.** Add original/managed filename, tags, exact document number, date range, MIME type, and local-availability filters. Preserve FTS relevance as a selectable sort, escape FTS syntax safely, return snippets/page references, and support combinations of command-palette prefixes instead of one prefix at a time.
- [ ] **5.6 Move large-library queries into SQLite.** Filter/order/page in the database with a stable ID tie-breaker. Fetch summary counts independently and resolve selected records by ID. Do not rebuild/sort the entire library in Dart on each update. Add equivalent workspace-scoped server search filters after Phase 3.
- [ ] **5.7 Establish measured performance targets.** Benchmark 10,000 metadata records plus representative OCR text on a named reference device. Proposed target: p95 local result latency below 300 ms excluding the typing debounce, bounded page fetches, and responsive scrolling during extraction. These are future acceptance targets, not current measured claims.

**Existing files:** [details panel](client/lib/features/documents/presentation/widgets/document_preview_panel.dart), [FTS implementation](client/lib/core/database/app_database.dart), [providers](client/lib/features/documents/presentation/providers/document_providers.dart), [command palette](client/lib/features/command_palette/presentation/command_palette_modal.dart), [server FTS](server/src/database/schema.sql), [client dependencies](client/pubspec.yaml).

**Proposed files:** `client/lib/features/document_reader/presentation/document_reader_screen.dart`, `client/lib/features/scanning/presentation/scan_document_screen.dart`, `client/lib/core/services/text_extraction_service.dart`, `client/lib/core/database/tables/extraction_jobs.dart`, `client/test/document_search_test.dart`, `client/test/text_extraction_test.dart`.

**Dependency gate:** Select and pin a maintained PDF renderer and native OCR/capture adapters only after verifying license, declared Flutter/Dart compatibility, offline operation, and Android/iOS support on devices. Hide unsupported platform actions; do not implement a web rewrite to satisfy a plugin gap.

**Acceptance gate:** Digital PDFs and scanned-image fixtures are searchable after extraction; corrupt files fail independently; corrections persist; reader actions work offline; a unique scanned phrase is discoverable; combined filters remain correct on a paged library.

## Phase 6 — Restore and Cross-Device Synchronization

**Outcome:** Users can recover backed-up files and safely access the same library on another device.

### Implementation tasks

- [ ] **6.1 Add Drive download/restore.** Download authorized app-owned files to staging, verify against the recorded SHA-256, and atomically activate the managed copy. Preserve document IDs. Report inaccessible, trashed, deleted, changed-content, and interrupted cases separately. Never overwrite a differing local copy without a resolution decision.
- [ ] **6.2 Back up the library catalog.** Maintain a versioned manifest in the app's Drive area containing document metadata, IDs, version/hash references, and replica locations, excluding credentials and device paths. This enables recovery when the optional PostgreSQL server was never used. Discovery of legacy uploads without a manifest must show incomplete metadata rather than invent it.
- [ ] **6.3 Add an authenticated changes API.** Provide `/api/v2/sync/changes?cursor=...&limit=...` for workspace-scoped upserts and tombstones. Use a server-issued cursor with committed ordering that cannot skip late-committing transactions; do not use client timestamps alone. Invalid/expired cursors trigger a paginated snapshot resync.
- [ ] **6.4 Apply pulls transactionally.** Commit applied remote changes and the next cursor in one local transaction. Merge acknowledgments with pending outbox jobs. Represent remote-only records without fake local file paths; download on demand or mark “keep offline.” Sync metadata independently of binary availability.
- [ ] **6.5 Resolve conflicts explicitly.** Compare base/remote/local revisions. Preserve both conflicting versions; provide keep-local-as-new-revision, keep-remote, and duplicate-as-new-document choices with a comparison screen. Binary conflicts are never automatically merged. Rejected stale updates do not erase local work.
- [ ] **6.6 Separate deletion scopes.** Removing a local cached copy retains the catalog and remote reference. Global document trash is an explicit authorized action with a durable tombstone. Remote backup deletion remains a provider operation. Retain synchronization tombstones for the supported offline window; older clients perform a full resync rather than resurrecting deleted records.
- [ ] **6.7 Add quota-aware offline availability.** Let users keep selected records offline, see required storage, pause downloads, and evict verified cache copies only. Never evict a sole local copy, unsynced revision, or unresolved conflict.

**Existing files:** [Drive service](client/lib/core/services/gdrive_service.dart), [backend client](client/lib/core/services/backend_sync_client.dart), [document model](client/lib/features/documents/domain/models/document_item.dart), [server repository](server/src/modules/documents/infra/postgres-document.repository.ts), [reconcile use case](server/src/modules/documents/usecases/reconcile.usecase.ts).

**Proposed files:** `client/lib/core/services/library_restore_service.dart`, `client/lib/core/services/pull_sync_service.dart`, `client/lib/features/conflicts/presentation/conflict_resolution_screen.dart`, `server/src/modules/documents/usecases/list-document-changes.usecase.ts`, `client/test/cross_device_sync_test.dart`, `server/src/modules/documents/usecases/list-document-changes.test.ts`.

**Acceptance gate:** A clean device reconstructs a catalog and restores matching binaries; two devices converge after offline edits; concurrent conflicting edits preserve both versions; repeated pull pages are idempotent; a deletion is not resurrected by a stale client; interruption cannot advance the cursor without its data.

## Phase 7 — Version History and Auditability

**Outcome:** Users can understand who changed a record and recover a previous document revision.

### Implementation tasks

- [ ] **7.1 Introduce immutable versions.** Separate stable document identity from version identity. Each version records content hash, original filename, size, MIME type, creator/device, timestamps, revision, and optional change note. Preserve each version's binary and cloud reference; a logical document points to its current version. If revisions share unchanged binary storage, track references so deleting one revision never removes bytes required by another revision or a legal hold.
- [ ] **7.2 Add replace-file and restore-version actions.** Replace creates a new version; restoring an older version also creates a new current revision. Metadata-only edits do not duplicate unchanged binaries. Detect externally modified managed files and require import-as-version or discard-local-change confirmation.
- [ ] **7.3 Add an activity timeline.** Record import, metadata edit, version creation, backup/restore, trash/restore, and conflict resolution. Distinguish a convenience local history from server-authoritative audit events. Client-supplied actor names are not audit identity.
- [ ] **7.4 Make server audit append-only for application roles.** Record authenticated actor, workspace, object/version, action, server time, request/operation ID, and redacted field changes. Commit audit events with the business mutation. Restrict audit access and avoid storing full OCR text or credentials in logs.
- [ ] **7.5 Add history comparison/export.** Show metadata differences and side-by-side supported previews, download a permitted earlier version, and export an authorized activity report. Include versions and lifecycle events in portable backups and Drive manifests.

**Existing files:** [document model](client/lib/features/documents/domain/models/document_item.dart), [repository](client/lib/features/documents/data/repositories/drift_document_repository.dart), [Drive client](client/lib/core/services/gdrive_service.dart), [server entity](server/src/modules/documents/domain/document.entity.ts), [server schema](server/src/database/schema.sql).

**Proposed files:** `client/lib/core/database/tables/document_versions.dart`, `client/lib/features/history/presentation/document_history_screen.dart`, `server/src/modules/audit/domain/audit-event.entity.ts`, `server/src/modules/documents/usecases/create-document-version.usecase.ts`, `client/test/document_versioning_test.dart`, `server/src/modules/audit/audit.integration.test.ts`.

**Acceptance gate:** Replacing/restoring never loses the previous bytes; interrupted version uploads do not change the current pointer prematurely; audit attribution derives from authentication; unauthorized users cannot read history; replaying a sync operation does not duplicate lifecycle events.

## Phase 8 — Optional Team and Records-Management Workflows

**Outcome:** A department can share and govern documents without confusing personal backup with organizational ownership.

**Entry gate:** Explicitly approve team use, organizational Drive/storage ownership, retention policy, and records-administration responsibilities. Skip this phase for a personal-library product.

### Implementation tasks

- [ ] **8.1 Add workspace memberships and roles.** Implement owner/admin, editor, reviewer, and viewer roles with server-enforced capabilities. Use expiring invitations and auditable role changes. Only owners transfer ownership; reviewers approve but cannot silently replace approved content.
- [ ] **8.2 Implement real binary access controls.** Backend metadata permissions alone do not grant Drive access. For organizational mode, use an explicitly provisioned organization-owned Drive location and permission model validated against the approved scopes. If this cannot be supported without new authorization, disable team binary sharing until that authorization is approved. Never simulate sharing by returning a Drive ID or creating public links.
- [ ] **8.3 Add controlled review lifecycle.** Implement draft → in review → approved/rejected → archived. Bind each approval to a specific immutable version. Editing approved content creates a draft version requiring fresh approval. Store assigned reviewers, decision note, due date, and transition events.
- [ ] **8.4 Add assignments, comments, and notifications.** Provide an in-app task inbox and document-linked comments. Deduplicate reminders; do not place sensitive document content into notification bodies. Email/push delivery is separately opt-in and requires configured providers.
- [ ] **8.5 Add records metadata.** Add incoming/outgoing register fields, sender/recipient, responsible unit, classification, related-document references, and optional QR-based internal record lookup. Workspace-wide register numbers are allocated transactionally online; offline drafts use temporary IDs, not competing official sequence numbers.
- [ ] **8.6 Add retention and legal holds.** Apply configurable, owner-approved schedules by record class. Start with retention-due reports and manual disposal approval; default automated destruction to off. Legal holds block purge of originals, versions, and relevant replicas. A disposal report records which stores actually completed removal.
- [ ] **8.7 Handle revoked access honestly.** Deny future server/download operations immediately and remove cache access on the next authenticated check according to policy. Explain that already exported or fully offline plaintext copies cannot be remotely recalled with an absolute guarantee.

**Proposed areas/files:** `server/src/modules/workspaces/`, `server/src/modules/approvals/`, `server/src/modules/retention/`, `client/lib/features/workspaces/`, `client/lib/features/approvals/`, `client/lib/features/notifications/`, `server/src/modules/approvals/approval.integration.test.ts`, `server/src/modules/retention/retention.integration.test.ts`.

**Acceptance gate:** Role tests cover metadata and file access; a stale client cannot approve a superseded version; changed approved content requires review again; legal hold blocks disposal; revocation blocks future online access; all authorized transitions are attributable.

**Boundary:** This phase does not claim statutory archival compliance, qualified electronic signatures, or guaranteed deletion of user-exported copies. Those require separate policy/legal and technical validation.

## Phase 9 — Operations, Accessibility, and Platform Delivery

**Outcome:** Selected features are measurable, supportable, and verified on the platforms advertised to users.

### Implementation tasks

- [ ] **9.1 Add CI from the first implementation increment.** Run formatting checks, Flutter analysis/tests, TypeScript checks/tests, PostgreSQL integration tests, and migration fixtures. Build Android releases in CI with proper secret-managed signing. Dependency/security checks complement, not replace, access-control tests.
- [ ] **9.2 Test real integration boundaries.** Use controlled HTTP fault injection for timeouts, 308 uploads, token expiry, rate limits, disconnects, and lost acknowledgments. Add a real PostgreSQL test service and opt-in manual Drive smoke tests using disposable app-owned fixtures; never production documents.
- [ ] **9.3 Add useful operational visibility.** Track queue age, retries/failure categories, metadata replication lag, migration status, backup age, and restore outcomes. Provide redacted diagnostic export and separate readiness/liveness checks. No document-content analytics by default.
- [ ] **9.4 Establish server backup and recovery.** Schedule protected PostgreSQL backups and validate restoration into an isolated environment. Remember that database backups do not contain Drive binaries. Recommended initial service target: metadata RPO 24 hours and restore RTO 4 hours, subject to owner acceptance and a successful drill.
- [ ] **9.5 Finish secure device packaging.** Validate Android signing, OAuth client registration, storage permissions, and opening/share behavior on devices. Configure iOS identity/callbacks/entitlements and signing on macOS before claiming support. Existing iOS scaffolding alone does not verify Google Sign-In.
- [ ] **9.6 Treat desktop and web as explicit deliverables.** Add Windows/macOS/Linux runners only for approved targets and test file picker, credential store, opening, OAuth, and persistent paths per target. Browser support requires replacing native `dart:io` storage/process dependencies and configuring browser-compatible Drift storage; keep it out of the default native roadmap. Add real OS drag-and-drop only after a desktop runner is accepted.
- [ ] **9.7 Add constrained background scheduling.** If required, integrate platform-supported schedulers with the same durable job leases; respect network/battery policy and OS execution limits. Explain foreground-only limitations where needed. Do not promise always-running mobile uploads.
- [ ] **9.8 Extend accessibility and localization.** Preserve current responsive behavior and add screen-reader names, predictable keyboard focus, non-color status cues, reduced-motion handling across splash/dialogs, and 200% text-scale checks. Extract UI strings into localization resources while preserving current terminology. Avoid adding another decorative dashboard.
- [ ] **9.9 Add first-run/support UX.** Explain local storage versus cloud backup versus server index, offer an optional connection/restore wizard, provide last successful backup status and safe troubleshooting, and avoid requiring sign-in to import locally.
- [ ] **9.10 Add a sensitive-records release gate.** Before advertising protection for sensitive institutional records, require a threat model and verified encryption for local metadata/binaries/backups with recoverable key management. An app lock is only a convenience layer, not encryption; user exports and third-party viewers require explicit disclosure.

**Existing files:** [client manifest](client/pubspec.yaml), [Android manifest](client/android/app/src/main/AndroidManifest.xml), [Android release configuration](client/android/app/build.gradle.kts), [iOS configuration](client/ios/Runner/Info.plist), [web bootstrap](client/web/index.html), [server scripts](server/package.json), [Dockerfile](server/Dockerfile), [Compose](compose.yaml), [client README](client/README.md), [privacy policy](PRIVACY_POLICY.md).

**Proposed files:** `.github/workflows/ci.yml`, `client/integration_test/library_lifecycle_test.dart`, `server/src/database/migration.integration.test.ts`, `client/lib/features/settings/presentation/diagnostics_screen.dart`, `client/lib/l10n/app_id.arb`.

**Acceptance gate:** Selected platform builds and release signing are verified; complete offline/import/backup/restore journeys pass; backup restoration is demonstrated; token/content redaction is tested; accessibility checks include keyboard and screen-reader operation; unsupported platform claims are removed.

---

## 6. Cross-Cutting Data and Migration Rules

1. **Identity:** Keep a stable document UUID, separate version UUIDs, and server IDs. Scope server uniqueness to authorized workspace. A content hash detects identical bytes; it is not a user identity, authorization token, or replacement for metadata revision.
2. **Location:** Local paths belong to a device and are never portable business identifiers. Store root-relative paths; remote-only records have explicit availability rather than a fabricated local path.
3. **State:** Separate document lifecycle, local availability, Drive replica status, backend replication status, extraction jobs, and workflow approvals. Do not extend one sync enum to represent all of them.
4. **Atomicity:** Local metadata and outbox writes share a SQLite transaction. Server mutations, accepted-operation receipts, audit events, and change-feed entries share a PostgreSQL transaction. Cross-filesystem/database work uses staging and recoverable journals, not a claim of distributed atomicity.
5. **Conflict safety:** Server revision checks prevent stale overwrite. Replay keys prevent duplicate application. Content differences and metadata-only changes are both detectable. Preserve local work until resolution succeeds.
6. **Migration safety:** Use additive schema changes, backfill on a copy, verify counts/hashes/FTS, and keep backups before destructive cleanup. Rebuild FTS as derived data after schema changes. Extend backup manifests with every new persistent feature and test old-manifest upgrades. Do not hand-edit `app_database.g.dart`.
7. **Legacy categories and ownership:** Preserve ambiguous values and unowned records until an explicit mapping is confirmed. Do not infer ownership from whoever connects first.
8. **Rollback:** Disable new feature entry points or roll forward after a migration failure; do not run an older incompatible client against an upgraded writable database. Prove restore-from-backup before relying on rollback.
9. **Privacy:** Personal Drive authorization is separate from backend login and workspace access. OCR/server indexing, cache retention, and export all need truthful disclosure. Credentials and upload session references never enter ordinary backups or logs.
10. **Engineering boundaries:** Extend existing repository/service seams. Split the large import/settings widgets when adding their new workflows; do not rewrite the entire client, introduce microservices, or replace `pg` with an ORM merely to implement this roadmap.

## 7. Release Slices and What to Build First

### Release A — Dependable single-user workspace

Complete Phases 0–2 and 4, the Phase 5 embedded-reader slice, and applicable Phase 9 gates. Add Phase 3 whenever a deployed backend is enabled. Include local backup restoration before calling Drive upload a complete recovery solution.

**Highest-value first tasks:** persistent storage settings, local trash/restore, portable library backup, separate Drive/backend status, persistent retry jobs, and metadata editing.

### Release B — Searchable and recoverable cloud library

Complete scanning/OCR/search from Phase 5, authenticated identity from Phase 3, cross-device recovery from Phase 6, and Phase 7 history. Demonstrate a new-device restore and a two-device conflict scenario before release.

### Release C — Organization-ready records workflows

Only with explicit demand, complete Phase 8 and its stronger storage-ownership, access-control, encryption, audit, and operational gates. Keep a personal-library configuration available if team functionality is unnecessary.

### Deliberately deferred

- Generative AI chat/summarization, semantic/vector search, and automatic classification without human review.
- Real-time collaborative editing of Word/PDF files.
- Public/anonymous file links, external publishing portals, or automatic broad Drive access.
- Legally binding electronic signatures and certified archival compliance.
- Billing/subscriptions, complex analytics dashboards, and microservices.
- A browser rewrite or support claims for every desktop platform before native validation.

These features add cost and risk without fixing the most immediate filing, recovery, and synchronization needs.

## 8. Verification Strategy

During future implementation, add the relevant tests alongside the phase's changes, use static analysis as needed, and run the complete suite once at the end of the agreed batch. Do not run the entire suite after every small edit.

### Existing verification commands

Run from the project root with dependencies installed and SDKs matching the manifests:

```powershell
Push-Location client
flutter analyze
flutter test
Pop-Location

Push-Location server
npx --no-install tsc --noEmit
npm run test:ts
Pop-Location
```

Check each command's exit status before continuing. For a production build gate, use `npm --prefix server run build`; `npm test` consumes compiled `dist` tests and must not be used as evidence for changed source without rebuilding. These commands are provided for future implementation verification; they were not executed during this documentation task.

### Required acceptance matrix

| Scenario | Evidence required |
| --- | --- |
| Offline import/edit/search | Files and metadata persist with all network access disabled |
| Crash during import/relocation/delete | Restart recovery preserves source data and consistent catalog references |
| Local trash and archive restore | Stable IDs and matching hashes after restoration to a clean library |
| Drive success, backend unavailable | Separate accurate statuses; metadata retries without duplicate upload |
| Interrupted resumable upload | Verified acknowledged offsets and no duplicate remote object |
| Account/profile switch | No previous-account jobs, records, or cached content leak |
| Metadata-only conflict | Revision mismatch detected even when binary SHA-256 is unchanged |
| New-device restore | Catalog reconstructed and chosen binaries verified |
| Two-device edits/deletes | Convergence or explicit conflict, no silent overwrite/resurrection |
| OCR and search | Reference scan text found; extraction failure does not block normal browsing |
| Versions/approval | Old bytes retained; approval applies only to its exact version |
| Authorization | Cross-user/workspace list/search/detail/sync/file/history requests denied |
| Platform readiness | Real device/native-runner evidence, not viewport-only widget tests |
| Accessibility | Large text, keyboard, focus restoration, screen reader, and reduced-motion checks |
| Operational recovery | PostgreSQL restore drill plus verified binary-backup availability |

**Current test limitations:** Drive tests use `mockMode: true`; backend tests use an in-memory repository. Their names mention resumability/resilience, but they do not establish real HTTP resume behavior, application-restart recovery, PostgreSQL transaction correctness, or physical-device permission support. No integration-test directory or CI workflow was found in the examined first-party project paths.

## 9. Evidence Index

Evidence IDs throughout this plan refer to current source/configuration, not proof of successful runtime verification.

| ID | Source | What it establishes |
| --- | --- | --- |
| E01 | [Import form](client/lib/features/documents/presentation/widgets/add_document_modal.dart), [import repository](client/lib/features/documents/data/repositories/drift_document_repository.dart) | Single-file import, metadata fields, manual extracted text, fixed import categories/year options |
| E02 | [Storage](client/lib/core/services/storage_service.dart), [sanitizer](client/lib/core/utils/file_sanitizer.dart), [hashing](client/lib/core/utils/hash_util.dart), [MIME detection](client/lib/core/utils/mime_detector.dart) | Managed copies, in-memory custom root, hashing, limited header inspection with extension fallback |
| E03 | [Local table](client/lib/core/database/tables/local_documents.dart), [database/FTS](client/lib/core/database/app_database.dart), [model](client/lib/features/documents/domain/models/document_item.dart) | Current schema, FTS fields, single sync-status field, absence of version/lifecycle models |
| E04 | [Providers](client/lib/features/documents/presentation/providers/document_providers.dart), [list](client/lib/features/documents/presentation/widgets/document_list_view.dart), [toolbar](client/lib/features/documents/presentation/widgets/document_toolbar.dart) | Reactive browsing, composed filtering, in-memory sorting, counts, and explicit sample loading |
| E05 | [Explorer](client/lib/features/document_explorer/presentation/document_explorer_screen.dart), [layout rules](client/lib/features/document_explorer/presentation/home_layout.dart), [theme](client/lib/core/theme/app_theme.dart), [app](client/lib/main.dart) | Adaptive shell, shortcuts, theme configuration |
| E06 | [Command palette](client/lib/features/command_palette/presentation/command_palette_modal.dart) | Local search prefixes and command actions |
| E07 | [Details panel](client/lib/features/documents/presentation/widgets/document_preview_panel.dart), [file opener](client/lib/core/services/file_opener_service.dart), [row actions](client/lib/features/documents/presentation/widgets/document_list_item.dart) | Metadata view and external opening, not embedded document rendering |
| E08 | [Google authentication](client/lib/core/services/google_auth_service.dart), [credential storage](client/lib/core/services/token_storage_service.dart), [backend client](client/lib/core/services/backend_sync_client.dart), [cloud settings](client/lib/features/documents/presentation/widgets/cloud_sync_settings_modal.dart) | Scopes/session flow, token fallback, optional backend URL, local-path metadata transfer |
| E09 | [Sync queue](client/lib/core/services/sync_queue_service.dart), [Drive client](client/lib/core/services/gdrive_service.dart), [Drive dialogs](client/lib/features/documents/presentation/widgets/drive_file_action_dialogs.dart) | Two workers, upload flow, swallowed metadata failure, name/status checks, remote rename/delete |
| E10 | [Local delete](client/lib/features/documents/data/repositories/drift_document_repository.dart), [file removal](client/lib/core/services/storage_service.dart) | Hard local deletion and ignored file-removal result |
| E11 | [API setup](server/src/app.ts), [routes](server/src/modules/documents/delivery/document.controller.ts), [schema](server/src/database/schema.sql), [PostgreSQL repository](server/src/modules/documents/infra/postgres-document.repository.ts), [entities](server/src/modules/documents/domain/document.entity.ts) | Unauthenticated metadata API, transaction/upsert behavior, hash-only reconcile, server FTS |
| E12 | [Storage tests](client/test/phase1_storage_and_db_test.dart), [sync tests](client/test/phase4_sync_queue_test.dart), [matrix tests](client/test/phase6_verification_matrix_test.dart), [provider tests](client/test/document_home_state_test.dart), [homepage tests](client/test/homepage_redesign_test.dart), [backend tests](server/src/modules/documents/usecases/document.usecases.test.ts) | Existing verification scope and mocked integration boundaries |
| E13 | [Splash initialization](client/lib/features/splash/presentation/splash_screen.dart), [provider wiring](client/lib/features/documents/presentation/providers/document_providers.dart) | Best-effort silent Google sign-in; no startup durable queue recovery wiring |
| E14 | [Database setup](server/src/database/db.ts), [server startup](server/src/main.ts), [Dockerfile](server/Dockerfile), [Compose](compose.yaml), [server package](server/package.json) | Deployment defaults, bootstrap schema execution, scripts and packaging |
| E15 | [Android build](client/android/app/build.gradle.kts), [Android manifest](client/android/app/src/main/AndroidManifest.xml), [iOS plist](client/ios/Runner/Info.plist), [web bootstrap](client/web/index.html), [client manifest](client/pubspec.yaml), [privacy policy](PRIVACY_POLICY.md) | Platform scaffolding/release constraints and current disclosures |
| E16 | [Original architecture plan](gemini-code-1791860676256.md), [UI plan](implementation_plan_UI.md), [client README](client/README.md) | Historical direction; some planned capabilities are absent and some UI baseline gaps are already addressed |

## 10. Completion Definition

A phase is complete only when its user journey works, its migration preserves existing records, its failure cases are verified, its statuses describe actual persisted outcomes, and the relevant tests/device checks pass. Checkbox completion alone is not evidence.

The recommended next implementation increment is **Phase 0 followed by Phase 1**. Build recoverability and trustworthy synchronization before promising intelligent, collaborative, or enterprise document management.
