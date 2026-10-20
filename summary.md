# Chat Handoff Summary — RDMS (Document Management System)

## Project
- **What:** Offline-first Flutter document library + optional Google Drive binary backup + optional Node/Express/PostgreSQL **metadata** API (server stores metadata only, no binaries). Indonesian gov/office records domain (SK, Laporan, Notula, Teknis, Peraturan).
- **Stack:** Flutter/Dart (Material 3, Riverpod 3, Drift/SQLite FTS5, Dio, google_sign_in, flutter_secure_storage, file_picker 13, open_filex, flutter_pdfview); Node/Express/TypeScript (Zod, `pg`, `jose`), PostgreSQL 16, Docker Compose.
- **Repo root:** `d:\Developers\Projects\document-management-system` — `client/` (Flutter), `server/` (Node). Windows / PowerShell 7.
- **Governing roadmap:** `implementation_plan_feat.md` (Phases 0–9). Execute one phase at a time, approved by the user.

## User working preferences (persist across agents)
- **No git operations at all** (repo has no commits; do not init/commit).
- **Don't run tests after every edit** — implement the batch, run `flutter analyze`/`tsc` during edits, run full suites once at end.
- Preserve Indonesian UI copy; `en-us` for code/analysis.
- **Never claim unverified completion** — always cite a fresh command result.
- Phase 3 must be usable **with no login** (see below).

## Phase status
| Phase | Status | Details / Missing Scope |
|---|---|---|
| 0 Baseline/config | ✅ Done | Core configuration, Drift SQLite, Google Drive foundation |
| 1 Recoverable storage/backup | ✅ Done | Managed file storage, journal, recycle bin, local backup/restore |
| 2 Durable sync / Sync Center | ✅ Done | Outbox, retry mechanism, Sync Center UI, resumable Drive uploads |
| 3 Auth backend/ownership | ⚠️ **NOT COMPLETE** (Partial) | Backend 3.1–3.3 verifier implemented (`REQUIRE_AUTH=false` default); client PKCE login, user profile 3.5, transport hardening 3.6, privacy policy 3.7, and live Keycloak container verification **not completed** |
| 4 Productivity (edit/tags/collections/bulk/CSV) | ✅ Done | Metadata editing, tags, collections, bulk import, register CSV export |
| 5.1 Embedded Reader | ⚠️ **NOT COMPLETE** (Partial) | Compiles with `flutter_pdfview` for Android/iOS; **not device-verified on hardware**, desktop inline reader not supported |
| 5.2 Camera Document Scanning | ❌ **NOT COMPLETE** (Not Started) | Edge detection, perspective crop, and mobile camera capture pipeline pending |
| 5.3 OCR Text Extraction | ❌ **NOT COMPLETE** (Not Started) | On-device text recognition pipeline pending plugin & model decisions |
| 5.4 Offline MLKit / Tesseract | ❌ **NOT COMPLETE** (Not Started) | Language pack download, offline processing queue, and background extraction pending |
| 5.5 Search Semantics | ⚠️ **NOT COMPLETE** (Partial) | Query prefix parser & facet filtering done; relevance ranking scoring and snippet highlight extraction **not completed** |
| 5.6 DB-side filter/sort/page | ✅ Done | SQLite EXISTS subqueries, pagination, and count queries |
| 5.7 Heavy List Performance | ❌ **NOT COMPLETE** (Deferred) | Extreme stress testing (>10,000 documents) and frame budgeting unverified on mobile hardware |
| 6 Multi-device Sync | ❌ **NOT COMPLETE** (Not Started) | Conflict resolution, device ledger pairing, and multi-client replication not implemented |
| 7 Team Collaboration & Sharing | ❌ **NOT COMPLETE** (Not Started) | Multi-user roles, shared document collections, and access control not implemented |
| 8 Hardening & Security Compliance | ❌ **NOT COMPLETE** (Not Started) | Encrypted storage at rest, security audits, and compliance documentation pending |
| 9 Production Packaging & CI/CD | ❌ **NOT COMPLETE** (Not Started) | Release signing keystores, automated GitHub Actions CI/CD, and app store bundling pending |

## Current verification (as of last run)
- `client`: `flutter analyze` → 0 errors (3 pre-existing `info` lints only); `flutter test` → **119 pass**.
- `server`: `npx --no-install tsc --noEmit` → exit 0; `npm run test:ts` → **55 pass**.
- Verify commands: from `client/`: `flutter analyze`, `flutter test`; from `server/`: `npx --no-install tsc --noEmit`, `npm run test:ts`.

## Key work done this session (recent)
**Phase 5.1 — reader:** `flutter_pdfview: ^1.4.5` (MIT/offline/Android+iOS only, gate-verified) added; new `client/lib/features/document_reader/presentation/document_reader_screen.dart` (PDF via native view + password/corrupt handling; images zoom/rotate; missing-file safe; external-open fallback). Detail panel shows "Baca Dokumen" only when `DocumentReaderScreen.isAvailable(doc)` (platform + type), else external open.

**Phase 5.6 — perf (root cause of earlier freezes):** moved list filtering/ordering/paging into SQLite. `AppDatabase` gained `watchDocumentPage` (EXISTS sub-queries for tag/collection, LIMIT/OFFSET, `id` tie-breaker, parameterized FTS), `watchDocumentCount`, `watchCategoryCounts`, `watchStatusSummary`, `watchDocumentById`, `watchDocumentsByIds`. Repository + providers rewired: `documentsListStreamProvider` returns a DB page; `documentListLimitProvider` + infinite-scroll in `document_list_view.dart`; summary/category/favorite counts and selection/detail resolve by DB/by-id, not full-table Dart scans. `allDocumentsStreamProvider` kept defined (test overrides depend on it) but off the live hot path. CSV export fetches full filtered set (not just the loaded page).

**Phase 5.5 — search:** `client/lib/features/documents/domain/search_query.dart` (`parseDocumentQuery`) combines multiple `prefix:value` tokens (tahun/kategori/status/nomor/tipe/berkas/tag/dari/ke + nama alias) into one filter; the command palette (`command_palette_modal.dart`) runs it through `watchDocumentPage`. FTS token escaping hardened.

**Phase 3 (server):** `server/src/modules/auth/` — pluggable `TokenVerifier`, `KeycloakTokenVerifier` (jose, verifies sig/issuer/**audience**/expiry via remote JWKS), `WorkspaceProvisioner`/`DbWorkspaceProvisioner`, `requireAuth({enforce,...})`. **Auth is optional by default** (`REQUIRE_AUTH=false` in dev; `true` in prod): no token → shared local workspace (fixed UUID seeded by migration `004_add_identity.sql`); a valid token is still workspace-scoped. Migration 004 adds users/workspaces/memberships + `documents.workspace_id`, and replaces the **globally-UNIQUE `client_local_id`** with per-workspace uniqueness `(workspace_id, client_local_id)`. Every repository path takes `workspaceId` as a required arg. `app.ts` mounts `requireAuth` on `/api/v1`+`/api/v2` (health public). Keycloak provisioned in `compose.yaml` + `keycloak/realm-import/rdms.json`. Config: `config.ts` `oidc` + `auth` blocks.

**Bug fixes:** swipe-to-delete / detail freeze traced to full-library Dart remap+sort (fixed by 5.6) and to rendering huge `extractedText`/`notes` in a `Text` (truncated in `document_preview_panel.dart` to 1500/400 chars). `DocumentSelectionNotifier.toggle` bug (set-literal couldn't remove) fixed.

## Critical pitfalls / conventions (memories exist for these)
- **Drift date filter in raw SQL:** bind bounds with `Variable.withDateTime(DateTime.fromMillisecondsSinceEpoch(m))`, NOT a raw `Variable<int>` — unit mismatch returns 0 rows. Probe with `SELECT typeof(col), col`.
- **Riverpod `StreamProvider.future` hangs under `flutter_test`** — instead `container.listen(provider,(_,_) {})` + `await Future.delayed(Duration.zero)` then read `.value`. (`await repo.watchX().first` directly is fine.)
- **Bash shell reuses cwd** — always `cd` explicitly before `npm install`/`flutter`; an accidental npm install polluted `client/`.
- Correct import path to `DocumentItem` from `features/document_reader/...` is `../../documents/domain/models/document_item.dart`.
- Server is **CommonJS TS**: use `.js` import suffixes, `__dirname`, no `import.meta`. `npm test` runs compiled `dist` (stale) — use `npm run test:ts`.
- `flutter_pdfview` is **Android/iOS only** → reader must stay platform-gated.
- Stale linter-cache errors are common after edits — trust the actual `flutter analyze`/`tsc`/test run.

## Test doubles
- `server/src/modules/documents/infra/mock-document.repository.ts` — workspace-scoped `IDocumentRepository` double (docs keyed `ws::clientLocalId`, ledger `ws::operationId`); used by `document.usecases.test.ts` and `document.authorization.test.ts` (real HTTP via `createApp({overrides})` + stub verifier/provisioner).
- `client/test/phase55_search_test.dart`, `phase56_database_query_test.dart`, `phase4_productivity_test.dart`, `document_home_state_test.dart` (updated to DB-backed providers).

## What's blocked / needs the user
- **Verify 5.1 + perf on a real Android device** (cannot in this environment).
- **5.2 scanning / 5.3-5.4 OCR:** user deferred; needs plugin + device decisions.
- **6/7/8/9:** need identity posture (stay local-only vs enable Keycloak), signing/keystore, CI host, deployment domain/HTTPS, accessibility/device checks.
- Phase 3 remaining: 3.5 account-scoped client profiles, 3.6 transport hardening, 3.7 PRIVACY_POLICY.md, native PKCE login (`flutter_appauth`), and live Keycloak+Postgres verification (realm audience mapping, `iss` matching in containers).

## Phase-3 auth posture caveat to preserve
The plan's original "unauthenticated calls fail" gate is now a **configurable posture, not default** — the product is intentionally usable with **no login** (`REQUIRE_AUTH=true` restores mandatory auth for public exposure). Do not "fix" this back to mandatory without the user asking.
