# CivilDoc PRD → RDMS Ultimate: Major Implementation Plan
### Rev. 2 — offline-first personal library posture

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans`, phase-by-phase. Steps use checkbox (`- [ ]`) syntax.
>
> **Standing project conventions these tasks deliberately follow** (recorded in `docs/ROADMAP.md` Part I and in
> project memory — do not "fix" them back):
> - **No Git operations.** This repo has no project-scoped commits, so tasks end with a `Checkpoint:` line
>   (the state that must be true before the next task starts) instead of `git add` / `git commit`.
> - **Batched verification.** Run `flutter analyze` / `npx tsc --noEmit` while working; run full suites **once per
>   phase**, not per task.
> - **Indonesian UI copy**, English code/comments/docs.
> - **Never claim unverified completion** — every "done" cites a fresh command output.

**Goal:** Deliver the parts of the CivilDoc PRD that a civil servant can actually use from a desktop or phone
without a network, a server account, or an IT department — while explicitly declining the institutional
architecture the PRD assumes but never justifies.

**Architecture (unchanged in kind, extended in depth):** Flutter + Drift/SQLite + a managed local file store stays
authoritative for everything, and the app must remain fully functional with the backend disabled. The server stays
**metadata-only — it receives no document bytes in any phase of this plan.** New capability is layered as:
immutable local version blobs with personal-cloud revision mirroring, cross-device convergence of the *same*
person's library, richer local discovery, and a single-operator security model (device encryption + profile
partition + cloud-off-by-default) in place of server-side access control.

**Tech Stack:** Dart/Flutter (Material 3, Riverpod 3, Drift/SQLite FTS5, Dio, `flutter_secure_storage`,
`flutter_pdfview`, `google_mlkit_text_recognition`, `camera`, `crypto`), Node/Express/TypeScript (Zod, `pg`,
`jose`), PostgreSQL 16, Keycloak 26 (optional), Docker Compose v2. **Rev. 2 adds no infrastructure service** —
no object store, no Redis, no queue, no AV scanner, no document converter (compare Rev. 1 §5.3, now removed).

---

## Revision note — what changed and why

Rev. 1 read the PRD literally as an institutional, multi-user, server-authoritative records system and concluded
that the plan's first problem was *"where do team binaries live"*, recommending a server-side S3-compatible object
store with ACL-gated presigned URLs, plus shared workspaces, RBAC, comment threads, review workflows, and three
consumer clouds.

That posture is now **rejected**, on product grounds rather than technical ones. RDMS Ultimate's value is that a
clerk in a district office keeps their SK, Laporan, and Notula files working on a laptop with no internet, no
directory service, and no admin. Making the server the gatekeeper for bytes inverts that: it turns an offline tool
into a networked one, adds a confidential-records custody obligation the project has not accepted, and buys the
least-provable PRD requirement (institutional sharing) at the highest architectural cost.

| Rev. 1 | Rev. 2 |
|---|---|
| Server object store (MinIO/S3) + presigned URLs + `storage_objects` | **No bytes on the server, ever.** Local content-addressed blobs + personal Drive revisions |
| Shared workspaces, 5 roles, capability matrix, invitations (M3) | Deferred — Appendix T |
| Comments, review lifecycle, presence, SSE, assignments (M4) | Deferred — Appendix T; replaced by local annotations + handover export |
| Server-side `audit_events`, append-only, institutional evidence | Local personal activity timeline, mirrored to the user's own workspace; explicitly **not** an institutional audit trail |
| Central telemetry sink to satisfy the 4 PRD metrics | Local counters + a self-view; org-level reporting only as an explicit opt-in |
| Drive/OneDrive/Dropbox/S3 as four peers (M5, XL) | Personal-provider abstraction, Drive first, OneDrive/Dropbox optional (P6) |
| Thumbnails + OCR + AV via Docker sidecars | Thumbnails and OCR **on-device**; server never sees a file to scan |
| 4 decision gates (G-1…G-4) blocking the plan | **1 gate** (T-1: is institutional multi-user actually required?) |
| 12 server migrations, 16 phases M0–M7 | 6 server migrations, 7 phases P0–P6 |

Nothing here argues the PRD is wrong. It argues the PRD describes **two products**, and this plan builds the one
the codebase already is, well. The deferred half stays costed and reachable (Appendix T) — and §2.2.4 keeps the
schema hedge that makes the later jump cheap instead of catastrophic.

---

## 0. Product posture (the constraint that shapes every decision below)

### 0.1 Seven commitments

1. **Offline is the default state, not the degraded state.** Every feature must define its no-network behaviour,
   and that behaviour must be useful.
2. **No login required.** `REQUIRE_AUTH=false` and the seeded local workspace (`004_add_identity.sql:76-86`) keep
   working in every phase. The backend is an *optional accelerator* for one person's devices.
3. **The server holds metadata only.** No phase introduces a binary upload, download route, or object store on the
   server. If this changes, it is a different product and Rev. 1's Appendix T is the starting point.
4. **One operator per installation, possibly several profiles.** Access control is about *profiles on a device and
   the person's own cloud*, not about permissions between colleagues.
5. **Cloud is opt-in per provider, per folder, per document.** The default is no cloud. A record classified
   `rahasia` must be visibly blocked from consumer cloud storage.
6. **Never lose a byte the user imported.** This is what makes versioning, refcounting, and the recoverable
   journal the centre of gravity of this plan rather than an add-on.
7. **Say what is not guaranteed.** Exported copies cannot be recalled; an app lock is not encryption; a personal
   timeline is not legal evidence; Drive may drop old revisions. Honest limits beat over-claiming, especially for a
   government audience.

### 0.2 How the PRD is read under this posture

**Adopt** = build as written. **Adapt** = satisfy the underlying need differently. **Defer** = real requirement,
different product; Appendix T, with re-entry conditions stated.

| PRD requirement | Verdict | Rev. 2 treatment |
|---|---|---|
| F1 Create/manage categories | **Adopt** | P5.1 — local-first category CRUD; server mirror only when a backend is configured |
| F1 Tag documents with multiple keywords | **Adopt** | already shipped locally; P3.3 adds autocomplete + usage counts + server mirror |
| F2 Share documents with team members | **Defer** | Appendix T. Interim: **P1.7 handover export** — a self-contained bundle (bytes + metadata + manifest) the clerk hands over on disk/USB/OS share, which is how document transfer actually happens in offices with segregated networks |
| F2 Real-time collaboration | **Defer** | Appendix T, and see V-2: co-editing is not applicable to immutable PDFs and scans |
| F2 Permissions view / edit / comment | **Adapt** | Comment → **P3.5 personal annotations** on a document. Permissions → **P4** single-operator profile + provider controls. Between-people permission is Appendix T |
| F3 Full-text search with keywords + filters | **Adopt** | P3.1–P3.4, mostly already built on-device |
| F3 Results show metadata and previews | **Adopt** | P3.4 snippets, P3.6 on-device thumbnails, P3.7 desktop reader |
| F4 Automatic versioning | **Adopt** | **P1**, the core of this plan |
| F4 View / restore previous versions | **Adopt** | **P1** |
| F4 Change logs for all edits | **Adapt** | **P1.5** personal activity timeline. Not institutional audit evidence (V-3) |
| F5 Integrate Drive / OneDrive / Dropbox | **Adapt** | P6: personal-provider abstraction; Drive (built) → OneDrive → Dropbox, each optional and individually gated |
| F5 Seamless sync | **Adopt** | P2 — bidirectional convergence across *one person's* devices, which is the real need |
| F5 Multi-cloud environments | **Adapt** | P6.4 per-provider policy per folder/document; no cross-tenant story |
| N1 2-second load | **Adopt** | P0.2 measures it; P3.8 targets it |
| N2 RBAC | **Adapt** | P4 — profile isolation + capability = "whose device is this". Server-side ACL is Appendix T |
| N2 Encryption in transit / at rest | **Adopt, elevated** | P4 — at rest moves **up** in priority, because with no server ACL, local encryption is the *only* control (see §1.3) |
| N3 Scalability | **Adapt** | Scales per-user library + per-workspace mirror; no institutional tenancy target |
| N4 Usability, tutorials, help | **Adopt** | P5.4–P5.6 |
| N5 Compliance with local government data protection | **Adapt** | P4.5 threat model + truthful disclosures, framed as *personal processing of official records*, not a records-management-system certification (V-4) |

### 0.3 Relationship to `docs/ROADMAP.md`

The existing Phases 0–9 remain authoritative for status. Rev. 2 phases map onto it as follows, and are numbered
**P0–P6** so they never collide with roadmap Phase 0–9 numbers:

| Rev. 2 phase | Roadmap phases it subsumes |
|---|---|
| P0 Baseline & measurement | 5.7 (deferred), part of 0.6 |
| P1 Version history & lifecycle | **7.1–7.5** (entire phase) |
| P2 Cross-device convergence | **6.1–6.7** (entire phase) + 3.5 profile partition + 3.6 leftovers |
| P3 Discovery & reading | 5.2–5.5 completion (5.1 partially shipped) |
| P4 Personal security & privacy | 8.7 partially, 9.10, and the undone 3.7 |
| P5 Records discipline & adoption UX | 4.2 completion, 8.5–8.6 reduced to single-user, 9.8–9.9 |
| P6 Optional multi-cloud | extends 2.4–2.5 to other providers |
| Appendix T | **8.1–8.4** (team RBAC, sharing, review, collaboration) |

Roadmap 6 (cross-device) and 7 (versioning) are both ❌ Not started and both are pure personal-library features —
which is why they, not the collaboration phases, are the substance of this plan.

---

## 1. Gap Analysis

### 1.1 Verified current state

Read from the repository, not from its documentation's claims about itself. Line references are live as of this
revision.

| Area | What exists today | Evidence |
|---|---|---|
| **Identity** | OIDC verification via Keycloak + `jose` (sig / iss / **aud** / exp, remote JWKS); `users` / `workspaces` / `memberships`; per-request `AuthContext.workspaceId`. Auth **off by default**; anonymous traffic maps to seeded local workspace `00000000-…-000000000001`. | `server/src/modules/auth/*`, `004_add_identity.sql` |
| **Data isolation** | Enforced structurally: every repository method takes `workspaceId` as its first argument; `client_local_id` uniqueness is per-workspace `(workspace_id, client_local_id)` partial-indexed; NULL-workspace legacy rows are quarantined and invisible to authenticated reads. | `document.repository.ts`, `postgres-document.repository.ts`, `document.controller.ts:192-203` (fails closed 401) |
| **Roles** | `memberships.role VARCHAR(16) DEFAULT 'owner'` — the column exists and **nothing reads it**. Every caller is owner of one personal workspace. | `004_add_identity.sql:41` |
| **Sync** | Transactional outbox (`sync_jobs`), per-destination state (`document_replicas`, `destination IN ('drive','backend')`), restart-safe leases, capped backoff + jitter, resumable Drive uploads with persisted sessions, Sync Center UI. **Push-only**: no change feed, no pull, no tombstones, no convergence. | `sync_queue_service.dart` (733 lines), `drive_upload_sessions.dart`, `sync_center_screen.dart` |
| **Revision counter** | `documents.revision` + `baseRevision` optimistic concurrency on `POST /api/v2/sync/batch`, idempotency ledger `accepted_operations` (`applied \| conflict \| rejected`). | `002_add_revisions.sql`, `apply-sync-operations.usecase.ts` |
| **Local file store** | `LocalStorageService implements IStorageService` — flat managed directory, filenames `[ISO_DATE]_[SANITIZED_TITLE]_[UUID_SHORT].[EXT]`, MIME sniffed from first 16 bytes, SHA-256 computed on copy. **Not content-addressed**: identical bytes imported twice occupy two files. `deleteManagedFile(path)` deletes unconditionally, **no reference check**. `storeBytes` buffers the whole file in memory (`writeAsBytes(bytes)`), `storeFile` streams. | `storage_service.dart:92-172`, `:184-196` |
| **Portable backup** | **Uncompressed folder** (deliberately: "a partial archive is still inspectable"), `manifest.json` at **v2** accepting `{1,2}`, carrying `appSchemaVersion`, per-document `fileRelativePath`, `sha256Hash`, `extractedText`, `syncStatus`, `gdriveFileId`. Restore **verifies every hash** and mandates a `ConflictPolicy` (silent overwrite not permitted). Favorites/saved views excluded by design. | `library_backup_service.dart:13-39`, `:110-116`, `:310-340` |
| **Search (client)** | SQLite FTS5 over title / document_number / category / extracted_text, `bm25()` ranking, DB-side filter+sort+page (`watchDocumentPage`, EXISTS sub-queries so paging counts stay correct), multi-prefix command-palette parser (tahun/kategori/status/nomor/tipe/berkas/tag/dari/ke + aliases). | `app_database.dart:129-221`, `:331-524`, `search_query.dart` |
| **Search (server)** | PostgreSQL `tsvector` with config `'simple'` — **no stemming** — over title / document_number / file_name / `custom_metadata->>'extractedText'`; GIN index; `ts_rank_cd`. Filters: category, year, limit, offset only. | `schema.sql:33-47`, `postgres-document.repository.ts:146-164` |
| **Organization** | Tags, document-tag links, collections, categories (code+name+archived), saved views — **all client-side**. Favorites and saved views are device-local *by design*. Server keeps tags only as opaque JSONB: normalized tag entities were explicitly **deferred** awaiting identity scoping. | `organization.dart`, `003_add_document_metadata_fields.sql:4-8` |
| **Categories, server** | `document_categories` is a **global table with no write API** — five seeded codes, shared by every workspace, editable only by SQL. | `schema.sql:3-7`, `:50-56` |
| **Binaries** | **The server stores no byte anywhere.** The only remote binary home is the user's **personal** Google Drive. There is no server-side upload route of any kind, and no server-side content download. | `gdrive_service.dart` (661 lines), route list in `document.controller.ts` |
| **Versioning** | None. One row per document, one `sha256Hash`; replacing a file overwrites it. `revision` is a sync-concurrency token, not content history. | `local_documents.dart` |
| **History / audit** | `accepted_operations` (outcome, revision_after, applied_at) — an idempotency ledger with **no actor column**. No activity timeline anywhere. | `002_add_revisions.sql:19-26` |
| **Encryption** | Tokens in `flutter_secure_storage`. **Nothing encrypted at rest**: not the SQLite DB, not managed files, not PostgreSQL, not the backup folder. Transport over loopback HTTP in dev; HTTPS documented as required. `crypto` is the only hashing dep. | `pubspec.yaml:41`, `PRIVACY_POLICY.md`, roadmap 1.6 |
| **Reader** | `flutter_pdfview` — **Android/iOS only**, platform-gated; desktop/web get external open. Camera + MLKit + cropper deps present; scanning and OCR pipeline not wired (`camera_ocr/` exists, roadmap 5.2–5.4 ❌). | `document_reader_screen.dart`, `pubspec.yaml:53-56` |
| **Records metadata** | Five categories only. No register, sender/recipient, responsible unit, classification, related-document links, retention, or disposition. | `schema.sql:50-56`, `local_documents.dart` |
| **Tests / toolchain** | Client `flutter analyze` 0 errors (3 info lints), `flutter test` 119 pass. Server `tsc --noEmit` exit 0, `npm run test:ts` 55 pass. **No CI of any kind** (roadmap 9.1 unstarted). | `docs/ROADMAP.md:41-44`, `.github/` absent |

### 1.2 Functional gap matrix

Severity: 🔴 absent · 🟠 partial · 🟡 present-but-narrow · 🟢 met. *(verdict from §0.2 in parentheses)*

| PRD requirement | Current | Concrete gap | Effort |
|---|---|---|---|
| **F1** Manage categories | 🟡 | No category CRUD in the client either — only pick from a list. Server table is global with no write path; renaming a code would orphan every `documents.category_id`. Needs: create/rename/archive/merge with an explicit user-confirmed merge map (`organization.dart:8-11` already encodes the never-auto-merge rule) | M |
| **F1** Multiple tags per document | 🟢/🟡 | Local ✅ (tags, document_tags, EXISTS filtering in `watchDocumentPage`). No autocomplete, no rename/merge, no usage counts, no replication — a second device sees **zero** tags | S |
| **F2** Share with team *(Defer)* | 🔴 | Out of posture. **P1.7 handover export** covers the transfer need locally; between-people permissions are Appendix T | — |
| **F2** Real-time collaboration *(Defer)* | 🔴 | Out of posture, and see V-2 — the shared artifact is an immutable PDF/scan, not an editable buffer | — |
| **F2** view/edit/comment permissions *(Adapt)* | 🔴 | Comments become local annotations (P3.5). "Permissions" become profile isolation + per-document cloud opt-out (P4) | M |
| **F3** Full-text + filters | 🟠 | Client 🟢 (9 filter dimensions, DB-side paging, bm25). Server 🟠: 2 filters, `'simple'` = no stemming, and its filters do not match the client's — the same query gives different answers on device 2. **PostgreSQL ships no `indonesian` text-search config** (built-ins cover ~17 European languages + `simple`), so stemming is not available without a custom dictionary — see P3.2 for what to do instead | M |
| **F3** Metadata + previews in results | 🟠 | Metadata ✅. Preview = full-screen native viewer, mobile only; **no thumbnails, no snippet, no page reference**; desktop has no in-app preview at all | M |
| **F4** Automatic versioning *(Adopt)* | 🔴 | Zero implementation. Requires: version identity distinct from document identity, content-addressed local blobs with refcounting (because `deleteManagedFile` is currently unguarded), and a Drive-revision strategy that tolerates provider-side revision expiry | L |
| **F4** View / restore versions *(Adopt)* | 🔴 | Restore must create a **new** current version, never destroy history | M |
| **F4** Change logs *(Adapt)* | 🔴 | No actor model, no timeline. Local-first activity log; server mirror is the user's own workspace history, not institutional evidence (V-3) | M |
| **F5** Drive / OneDrive / Dropbox *(Adapt)* | 🟠 | Drive is hard-wired through 661 lines. There is **no interface for remote providers** — `IStorageService` abstracts the *local* store and `LocalStorageService` correctly implements it (Rev. 1 mis-stated this). The seam to build is `RemoteContentProvider` | XL → **optional** |
| **F5** Seamless sync *(Adopt)* | 🟠 | Push-only. `reconcile` compares hashes and returns `missingOnServer`/`outdatedOnServer` — a diff report, **not a pull path**. A second device cannot reconstruct the library; no conflict resolution | L |
| **F5** Multi-cloud *(Adapt)* | 🔴 | Needs the remote-provider interface plus a per-document location policy that honours classification (P6.4) | L → optional |

### 1.3 Non-functional gap matrix — note the inversion

**At-rest encryption moved from "compliance phase, late" (Rev. 1) to a first-class concern, and it is now the
primary security control rather than a supplement.** The logic is unavoidable: if the server enforces no ACL and
holds no bytes, then the protection on every record is whatever the device provides. A lost laptop *is* the
breach. That makes P4 more important than it was, and makes its scope smaller.

| PRD | Current | Rev. 2 gap | Where |
|---|---|---|---|
| N1 ≤2 s load | **Unmeasured.** DB-side filtering removed the known freezes; no device benchmark exists | P0.2 baseline, then per-surface budgets. The PRD's N1 is currently *unevaluable*, not merely missed | P0, P3.8 |
| N2 RBAC | `memberships.role` unread; single personal workspace per user | **Replaced** by profile partition (`workspace_id` on local rows) + app lock + per-document cloud opt-out | P2.5, P4.1–4.3 |
| N2 Encryption in transit | HTTPS required in docs; dev is loopback HTTP; no HSTS; no forced redirect | Enforce outside loopback, bounded timeouts, redacted logs | P4.4 |
| N2 **Encryption at rest** | 🔴 Absent at every layer | Encrypt managed files + backup folder + sensitive columns, with **recoverable** key management. Pre-existing libraries must remain openable after the upgrade | **P4.2 — elevated** |
| N3 Scalability | Single Postgres, `OFFSET` paging, unbounded log tables | Per-user libraries scale to ~10⁴ docs comfortably; needs cursor paging for version/activity feeds and bounded local caches | P1.6, P2.2 |
| N4 Usability / tutorials / help | Adaptive 3-pane, dark/light, command palette. **No first-run tour, no in-app help** | Adoption is impossible without this; also the cheapest UX win in the plan | P5.4–P5.6 |
| N5 Compliance | `PRIVACY_POLICY.md` accurate for a personal tool; no multi-user/retention/telemetry disclosure | Reframe as personal processing of official records; PDP 27/2022 duties that *do* attach; explicit non-claims | P4.5 |

### 1.4 Success-metric readiness under the personal posture

The PRD's four metrics were written for a mandated institutional rollout. Under a personal-library product, two are
directly measurable, one needs redefining, and one is not ours to deliver. Saying so is part of the plan.

| PRD metric | Measurable? | Rev. 2 approach |
|---|---|---|
| **Adoption** — 80 % of employees in year 1 | ❌ centrally, ✅ per-profile | **Local counters only by default.** An org-wide adoption figure requires each installation to opt in to reporting to *their own* backend — offered, never assumed. Adoption for this product is driven by usefulness, not mandate (see §7 Q4) |
| **Search time −50 %** | ✅ | The strongest fit. `search_executed → document_opened` delta measured **on-device**, shown in a "Ringkasan Produktivitas" self-view. Baseline from P0.2; the improvement is attributable to P3 without any data leaving the device |
| **Errors −30 %** | ✅ after redefinition | Define "error" concretely rather than inheriting the PRD's vagueness: **(a)** distributing the wrong version — eliminated by P1; **(b)** duplicate filing — hash check exists (P0 instruments its hit rate); **(c)** mis-filing — reduced by classification + register validation P5.1; **(d)** lost document — eliminated by P1 blobs + P4 backup. Counters are local |
| **Satisfaction 4.5/5** | ❌ | A quarterly survey is an **ops process**; code supplies only the instrument (P5.6 in-app capture, stored locally). Flagged to the product owner in §7 Q4 rather than quietly claimed |

### 1.5 Scope verdicts

Four requirements cannot be met as written. Each is stated with what we build instead — not a silent downgrade.

**V-1 — "Share documents with team members" is not a personal-library feature.**
Real sharing needs a binary location both parties can be granted access to. The posture forbids the server holding
bytes (commitment 3), and Rev. 1's own analysis established that returning a colleague *your personal* Drive file ID
is not access but leakage. So F2 is deferred as a unit, and the transfer need is met locally: **P1.7 handover
export** produces a self-contained bundle (bytes + metadata + manifest + activity) the clerk hands over on disk,
USB, or the OS share sheet — which is genuinely how documents move between Indonesian offices on segregated
networks, and works with no account on either end.

**V-2 — "Real-time collaboration" is not applicable to the artifact.**
The PRD's own domain is SK, Laporan, Notula — immutable PDFs and scans. Literal co-editing would require an
editable first-party format, OT/CRDT convergence, and a server-side renderer, and would abolish the offline-first
guarantee. Even Appendix T implements F2 as *asynchronous* collaboration (share, annotate, propose a new version,
approve) because that is the need; if true co-authoring is later mandated, the honest answer is embedding an
editor (OnlyOffice / Google Docs), a separate product with its own tenancy requirements — not a feature of this one.

**V-3 — A personal activity timeline is not an institutional audit trail.**
Roadmap 7.3 already distinguishes convenience history from server-authoritative audit. Without verified multi-user
identity and an append-only, app-role-cannot-write store, we have the former. P1.5 builds a durable local timeline
(who: this device/profile; what: version created, restored, edited; when) and mirrors it to the user's own
workspace so it survives device loss. It is labelled *Riwayat dokumen saya* and the docs state plainly that it is
not evidence-grade audit data. Appendix T's `010_add_audit_events.sql` (Rev. 1) is the route to the real thing.

**V-4 — Compliance here is personal-processing compliance, not RMS certification.**
Statutory archival compliance, qualified electronic signatures (e.g. TTBE under PP 132/2022), and guaranteed
deletion of already-exported copies are **out of scope** — roadmap Phase 8's own "Boundary" paragraph says so and
Rev. 2 keeps that boundary. What *does* attach: lawful-basis documentation, data minimisation, subject access,
breach notification, and truthful privacy disclosures (P4.5). Over-claiming here is the highest-consequence failure
available to this project (R-12).

---

## 2. Technical Strategy

### 2.1 Invariants every phase must re-assert

Each phase's acceptance gate includes these as tests, not as intentions.

1. **Backend-disabled parity.** With no server configured, every shipped feature still works. Proven by running the
   feature's tests against a `BackendSyncClient` stub that always throws unreachable.
2. **No-login parity.** `REQUIRE_AUTH=false` + the seeded local workspace keeps serving. Asserted by a standing test
   in every phase. Do not "fix" auth back to mandatory (`docs/ROADMAP.md:76-77`).
3. **No bytes to the server.** A test asserts no route accepts a binary body and none returns one. This is a
   posture guard, not an implementation detail — it is what keeps R-01-type drift from creeping back in.
4. **Workspace scoping on every new path.** Client: `workspace_id` on every shared row, filtered in every query.
   Server: `workspaceId` as the first repository argument, as `document.repository.ts` already mandates.
5. **Fail closed.** Reuse the controller's `resolveWorkspace()` shape: no authorization ⇒ 401, never a wider query.
6. **Never lose an imported byte.** No deletion path may remove managed bytes without a `content_blobs.ref_count`
   check (the current `deleteManagedFile` is unguarded — fixing it is a P1 task, not an incidental refactor).
7. **Local paths are device-private.** No absolute path in any payload (already enforced,
   `backend_sync_client.dart:119-121`), log, manifest, or notification.
8. **Indonesian UI copy**, Material 3, adaptive 3-pane, dark/light, keyboard-navigable, non-colour status cues.

### 2.2 Data model

#### 2.2.1 Where version bytes live — the central design decision

The posture (server holds no bytes) forces exactly one workable answer, and it turns out to be a good one:

```
                      ┌──────────────────────────────────────────────┐
  import / replace ──►│ LOCAL managed store  (AUTHORITATIVE)         │
                      │  blobs/<sha256[0:2]>/<sha256>  content-addr. │
                      │  content_blobs{sha256,path,size,ref_count}   │
                      └───────────────┬──────────────────────────────┘
                                      │ opt-in backup (per document)
                                      ▼
                      ┌──────────────────────────────────────────────┐
                      │ PERSONAL Google Drive — native file revisions │
                      │  provider_version_ref = revisionId            │
                      │  ⚠ bounded & provider-controlled (see below)  │
                      └───────────────┬──────────────────────────────┘
                                      │ metadata only (no bytes)
                                      ▼
                      ┌──────────────────────────────────────────────┐
                      │ SERVER document_versions mirror               │
                      │  tells device 2 that v1..v7 exist, their      │
                      │  metadata, and where to fetch each            │
                      └──────────────────────────────────────────────┘
```

Consequences that shape the rest of the plan:

- **Local blobs are the guarantee.** History survives Drive outages, scope changes, and account loss.
- **Drive revisions are best-effort convenience, not history.** Google's per-file revision retention is bounded and
  provider-controlled; a version that exists *only* as a Drive revision is at risk. So the client must
  (a) verify whether the currently authorized Drive scope even permits revision listing and `keepForever`, and
  (b) if a revision the user cares about is only remote, download it into a local blob and mark the version
  `local_available = true`. The UI must show `hanya di Drive` for versions whose bytes are not local, and never
  imply they are safe.
- **The server mirror is metadata only**, which is what makes a second device of the same person able to say
  "you have 7 versions of this; 3 are on Drive; 1 is local" — without the server ever touching a file.
- **Thumbnails and OCR are on-device**, because the server has no file to process. This is what removes Poppler,
  `sharp`, a converter sidecar, Redis, and ClamAV from Rev. 1's infrastructure list.

**Legacy adoption rule.** Today's store is a flat, human-readable directory (`storage_service.dart:92-131`) and is
*not* content-addressed. Do **not** bulk-move existing files into the blob layout — that would invalidate
`library_integrity_service.dart`'s relink logic, the relocation journal, and every existing `localFilePath`.
Instead: version 1 of a pre-existing document keeps pointing at its current managed path (zero extra bytes), and
every *new* version is written to `blobs/<hash-prefix>/<sha256>`. A `content_blobs` row therefore has a nullable
`legacy_path` and a `path`, and the guard in invariant 6 consults whichever is set.

#### 2.2.2 Client (Drift/SQLite) — `schemaVersion` 4 → 7

`app_database.dart:45-48` states the contract — every schema change bumps `schemaVersion` **and** adds a matching
`if (from < N)` block; `_installFtsAndIndexes()` re-runs on every path so a v1 install and an upgraded install
cannot drift. Follow it exactly, and remember the FTS `AFTER UPDATE` trigger is a delete-and-reinsert of the whole
row (`:150-156`): **any new searchable column requires editing the trigger body, or search silently breaks for
upgraded installs only** (R-09).

| V | Block | Adds | Phase |
|---|---|---|---|
| **5** | `from < 5` | `document_versions`, `content_blobs`, `activity_events`; `local_documents.current_version_id`, `local_documents.workspace_id` (default = the install's personal profile) | P1 |
| **6** | `from < 6` | `change_cursors`, `tombstones` (+ `trashed_at`-style `deleted_at` on `document_versions`); `annotations` | P2, P3 |
| **7** | `from < 7` | `usage_counters` (local metrics), `record_metadata` (register/classification/related-doc), `retention_marks` | P0 counters, P5 |

Sketch of the load-bearing P1 tables (Drift, matching the existing house style — see `document_replicas.dart` for
the comment density to imitate):

```dart
/// Immutable content versions (Rev.2 P1.1). Deliberately distinct from
/// [LocalDocuments.baseRevision]: a revision is a sync concurrency token,
/// a VERSION is an immutable content identity with its own bytes and author.
class DocumentVersions extends Table {
  TextColumn get id => text()();                       // UUID, version identity
  TextColumn get documentId => text()();               // stable document identity
  TextColumn get workspaceId => text().withDefault(const Constant(personalProfile))();
  IntColumn get versionNumber => integer()();
  TextColumn get parentVersionId => text().nullable()();
  TextColumn get sha256Hash => text()();
  TextColumn get blobId => text()();                   // -> content_blobs.id
  TextColumn get fileName => text()();                 // managed name AT THAT MOMENT
  TextColumn get originalFileName => text().nullable()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get mimeType => text()();
  /// Where the bytes additionally exist besides the local blob.
  TextColumn get originBackend => text().withDefault(const Constant('local'))(); // local|gdrive|none
  TextColumn get providerVersionRef => text().nullable()();  // Drive revisionId
  BoolColumn get localAvailable => boolean().withDefault(const Constant(true))();
  BoolColumn get localOnly => boolean().withDefault(const Constant(true))();      // cloud opt-in per doc
  TextColumn get changeNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// Metadata as it was when this version was current, so history shows the
  /// description *then*, not the description now (P1.4).
  TextColumn get metadataSnapshot => text()();         // JSON

  @override Set<Column> get primaryKey => {id};
  @override List<Set<Column>> get uniqueKeys => [{workspaceId, documentId, versionNumber}];
}

/// Reference-counted content store. THE GUARD for invariant 6: no managed
/// byte may be deleted while ref_count > 0, because two versions with
/// identical bytes must share one blob (roadmap 7.1).
class ContentBlobs extends Table {
  TextColumn get id => text()();
  TextColumn get sha256Hash => text()();
  TextColumn get relativePath => text().nullable()();  // blobs/<xx>/<hash> when content-addressed
  TextColumn get legacyPath => text().nullable()();    // pre-P1 flat managed file, adopted as v1
  IntColumn get sizeBytes => integer()();
  TextColumn get mimeType => text()();
  IntColumn get refCount => integer().withDefault(const Constant(0))();
  BoolColumn get encrypted => boolean().withDefault(const Constant(false))(); // P4.2
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override Set<Column> get primaryKey => {id};
  @override List<Set<Column>> get uniqueKeys => [{sha256Hash}];
}
```

Also in v5: a `local_documents.workspace_id` default of the install's own personal-profile UUID. Single-user today,
but adding it **now** is what keeps Appendix T a migration instead of a rewrite (§2.2.4).

#### 2.2.3 Server (PostgreSQL) — migrations `005`→`010`

`migrate.ts` is unforgiving and correct: numbered files, SHA-256 checksummed into `schema_migrations`, one
transaction each, advisory-locked, and **changing an applied file is a hard error**. So `001`–`004` are frozen; every
change is a new file. Anything added must also land in `schema.sql` so a fresh Compose volume and an upgraded volume
converge (roadmap 0.2's acceptance gate, R-08).

| Migration | Adds | PRD |
|---|---|---|
| `005_add_workspace_categories_tags.sql` | per-workspace `categories` (id/code/name/archived), normalized `tags`, `document_tags`; re-point `documents.category_id` | F1 |
| `006_add_document_versions.sql` | `document_versions` **metadata mirror only**; `documents.current_version_id` | F4 |
| `007_add_change_log_tombstones.sql` | `change_log` (monotonic seq), `documents.deleted_at` / `document_versions.deleted_at` tombstones | F5 sync |
| `008_add_activity_events.sql` | `activity_events` — the user's own history mirror (V-3) | F4 |
| `009_improve_server_search.sql` | extended `search_vector` (filename, tags, notes, classification) + `unaccent` + `pg_trgm` indexes | F3 |
| `010_add_records_metadata.sql` | register fields, `classification`, `related_documents` | F1, N5 |

**Removed from Rev. 1:** `007_add_storage_objects` (object store), `008_add_org_workspaces_roles`, `009_add_document_sharing`,
`010_add_audit_events`, `011_add_collaboration`, `012_add_review_lifecycle`, `016_add_telemetry` — twelve migrations
to six, and no table anywhere that holds a byte or grants a colleague anything.

```sql
-- 006_add_document_versions.sql
-- PRD F4. This is a METADATA MIRROR: the bytes live in the user's local
-- managed store and, optionally, their personal Drive revisions. Nothing here
-- is fetchable from this server. Keep documents.revision (migration 002) as
-- the sync concurrency token and never reuse it as a version number —
-- see implementation_plan_major.md §2.2.4.
--
-- The forward FK is DEFERRABLE because a document and its first version must
-- be insertable in one transaction (document_versions.document_id also points
-- back at documents).
CREATE TABLE IF NOT EXISTS document_versions (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id          UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    workspace_id         UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    version_number       INT  NOT NULL,
    parent_version_id    UUID REFERENCES document_versions(id),
    sha256_hash          VARCHAR(64) NOT NULL,
    file_name            VARCHAR(255) NOT NULL,
    original_file_name   VARCHAR(255),
    file_size_bytes      BIGINT NOT NULL,
    mime_type            VARCHAR(100) NOT NULL,
    -- local | gdrive | none : where the OWNER'S bytes additionally live. The
    -- server cannot resolve these; it only tells another of the user's
    -- devices which of their own accounts to look in.
    origin_backend       VARCHAR(16) NOT NULL DEFAULT 'local',
    provider_version_ref VARCHAR(255),
    change_note          TEXT,
    metadata_snapshot    JSONB NOT NULL DEFAULT '{}',
    -- Server-derived from the verified token, never from the request body
    -- (roadmap 7.3: "client-supplied actor names are not audit identity").
    created_by           UUID REFERENCES users(id),
    created_device_id    VARCHAR(64),
    deleted_at           TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (workspace_id, document_id, version_number)
);
CREATE INDEX IF NOT EXISTS idx_doc_versions_document
    ON document_versions(document_id, version_number DESC);
CREATE INDEX IF NOT EXISTS idx_doc_versions_workspace
    ON document_versions(workspace_id, created_at DESC);

ALTER TABLE documents
    ADD COLUMN IF NOT EXISTS current_version_id UUID
        REFERENCES document_versions(id) ON DELETE SET NULL
        DEFERRABLE INITIALLY DEFERRED;
```

**Server search, honestly.** Do not plan on stemming: **PostgreSQL ships no `indonesian` text-search configuration**
(the built-ins cover ~17 European languages plus `simple`), so `009` does three cheap, correct things instead —
keeps `'simple'` (which matches the client's `unicode61` behaviour, so results agree across devices), adds
`unaccent` for diacritic-insensitive matching, and adds `pg_trgm` GIN indexes on `title` / `document_number` to
catch the "I typed part of a number" case that `simple` misses. A custom Ispell dictionary is available and **not
worth it**. Do not add Elasticsearch/OpenSearch (§5.4).

#### 2.2.4 Three counters, and the schema hedge for Appendix T

Locking this down prevents the single most likely implementation error in the plan.

| Concept | Field | Advances when | Authoritative for |
|---|---|---|---|
| **Sync revision** | `documents.revision` (002) | any accepted mutation, including metadata-only | optimistic concurrency, `accepted_operations`, replica acks |
| **Content version** | `document_versions.version_number` (006) | a **new byte sequence** is attached | history, restore, comparison |
| **Change sequence** | `change_log.seq` (007) / `change_cursors` (client) | any workspace-visible change or tombstone | pull-feed cursor, convergence |

**The hedge.** Even though Rev. 2 ships no multi-user feature, every new table carries `workspace_id` and the client
threads it from day one. If the institution ever does require team mode (T-1), that makes the jump a matter of
adding roles, ACLs, and a content home — not re-partitioning a schema that assumed one operator. Omitting it would
be the one decision later phases could not work around.

### 2.3 API surface

**Versioning decision.** New capability goes on **`/api/v3`**, mounted exactly like v1/v2 in `app.ts:161-179` (same
`requireAuth` seam, same fail-closed `resolveWorkspace`, same Zod envelope, same `requestId`). v1/v2 stay frozen and
working. `/api/v1/sync/batch-metadata` may be deprecated after P2; **v1 must never be reachable unauthenticated in
a production deploy**.

The whole new surface is small — this is the cost of declining bytes and ACLs:

| Method + path | Purpose | Phase |
|---|---|---|
| `POST /api/v3/documents/:id/versions` | Register version metadata (no bytes). Idempotent on `operationId` | P1 |
| `GET /api/v3/documents/:id/versions?cursor=&limit=` | History page, **cursor** not `OFFSET` | P1 |
| `POST /api/v3/documents/:id/current-version` | Move the current pointer after a local replace/restore | P1 |
| `GET /api/v3/documents/:id/activity` · `POST` (append) | Personal history mirror (V-3) | P1 |
| `GET /api/v3/sync/changes?cursor=&limit=` | **Pull feed**: upserts + tombstones, server-issued monotonic cursor | P2 |
| `PUT /api/v3/documents/:id` · `DELETE` | Metadata edit + durable tombstone (today there is **no** document-level write or delete route at all) | P2 |
| `GET/POST/PUT/DELETE /api/v3/categories` · `POST /api/v3/categories/:code/merge` | Per-workspace category CRUD, archive, user-confirmed merge | P5/P1 |
| `GET /api/v3/tags?prefix=&limit=` | Workspace-scoped autocomplete + usage counts | P3 |
| `GET /api/v3/documents/search` | Replaces v1 search: `tags`, `from`, `to`, `mime`, `filename`, `classification`, `sort=relevance\|date`, `facets`, `highlight`, `cursor` | P3 |
| `PUT /api/v3/documents/:id/record` | Register / classification / related-document links | P5 |
| `POST /api/v3/telemetry/batch` | **Only if the user opted in** to reporting; same contract as local counters | P0 |

**Absent by design** (and each absence is a posture commitment, worth stating in the API docs so a later agent
doesn't "helpfully" add one): no content upload, no content download, no presigned URL, no share link, no
membership or invitation route, no review or comment endpoint, no presence/SSE channel, no public `GET` without a
workspace scope.

**API rules carried over from what already works:**
- **Every write is idempotent-keyed.** Reuse the proven `accepted_operations` pattern (`POST /api/v2/sync/batch`
  returns the *original* outcome on replay) for version registration, current-pointer moves, and activity appends —
  so an offline client resuming on a flaky link cannot duplicate lifecycle events. Roadmap 7's own gate: "replaying
  a sync operation does not duplicate lifecycle events."
- **Optimistic concurrency on the current pointer.** Moving `current_version_id` sends `baseRevision`; a mismatch is
  `conflict`, never a silent overwrite — exactly the semantics `apply-sync-operations.usecase.ts` already implements.
- **Cursor paging** for versions, activity, and the change feed. `OFFSET` (present at
  `postgres-document.repository.ts:166`) is fine for bounded 100-row admin lists but is O(n) on deep pages and
  unsafe against concurrent inserts — do not extend it.
- **Same bounds as today:** batch ≤ 100, page 1–100 via `parseBoundedInt`, dates via `isoCalendarDate`, hashes via
  `sha256Hex`, route ids via `uuidString`. Tighten none of them without a migration and a regression case.
- **Every mutation appends to `change_log` and writes `activity_events` in the same `BEGIN…COMMIT`** as the business
  row, using the `client.query('BEGIN')` style already in `applyOperations`.

### 2.4 Flutter UI

New feature slices, each one responsibility, matching the existing
`features/<name>/{domain,data,presentation}` layout:

```
client/lib/features/
  versions/     domain/{document_version,content_blob}.dart
                data/{version_repository,blob_store}.dart
                presentation/document_history_screen.dart
                presentation/restore_version_dialog.dart
                presentation/widgets/{version_timeline,version_diff_sheet}.dart
  activity/     domain/activity_event.dart   data/activity_repository.dart
                presentation/activity_timeline.dart
  annotations/  domain/annotation.dart       presentation/annotation_panel.dart
  handover/     domain/handover_bundle.dart  data/handover_service.dart
                presentation/export_handover_screen.dart
  sync/         data/{pull_sync_service,change_feed_client}.dart
                presentation/conflict_resolution_screen.dart
  records/      domain/{record_metadata,classification,retention}.dart
                presentation/register_screen.dart
  privacy/      domain/{app_lock,crypto_policy}.dart
                presentation/security_status_screen.dart
  metrics/      data/{usage_counters,metrics_service}.dart   (no upload by default)
                presentation/productivity_summary_screen.dart
  content/      domain/remote_content_provider.dart        ← NEW seam, see below
                data/{drive_content_provider,onedrive_content_provider}.dart
  onboarding/   presentation/{first_run_tour,help_center_screen}.dart
```

**The corrected seam.** `IStorageService` is *not* dead code — `LocalStorageService implements IStorageService`
(`storage_service.dart:30`) and it is the right abstraction for the local store. What is missing is an interface for
**remote content providers**, which today exist only as a hard-wired 661-line `gdrive_service.dart`. The new seam is
`RemoteContentProvider`: `authorize` / `signOut` / `upload` / `resumeUpload` / `download` / `listRevisions` /
`downloadRevision` / `rename` / `trash` / `restore` / `verify` / `capabilities()`. `capabilities()` is what makes
provider gaps honest — Drive reports `immutableRevisions: true`, OneDrive `true`, Dropbox via `rev`; a provider
whose scope cannot list revisions reports it and the version layer downgrades to local-only-for-certain and says so.

Wiring into the existing shell — specific files, not "the UI":

| Existing file | Change |
|---|---|
| `core/database/app_database.dart` | Versions 5–7 (§2.2.2); extend the FTS5 columns **and** all three triggers in the same step |
| `core/services/storage_service.dart` | Add `storeVersionBlob` (content-addressed, streaming hash — do **not** reuse `storeBytes`, which buffers the whole file at `:157`/`:163`) and make `deleteManagedFile` refcount-guarded |
| `core/services/library_backup_service.dart` | **Manifest v3**: `supportedManifestVersion = 2 → 3`, `acceptedManifestVersions = {1,2,3}`; per-document `versions[]` + `blobs[]` + activity. v1/v2 archives must stay restorable (the existing `{1,2}` precedent shows exactly how) |
| `core/services/library_integrity_service.dart` | Health check per version; externally-modified file → offer *import as version* or *discard local change* instead of terminal "needs review" |
| `core/services/gdrive_service.dart` | **P6 only.** Wrap behind `drive_content_provider.dart`; P6.1 adds zero features and must show zero behaviour change |
| `core/services/backend_sync_client.dart` | Add `registerVersion`, `listVersions`, `appendActivity`, `fetchChanges`, `putDocument`, `deleteDocument`. Keep `BackendTransientException` semantics so queue backoff keeps working |
| `features/documents/domain/models/document_item.dart` | Add `currentVersionId`, `versionCount`, `localAvailableVersions`, `classification`. Keep it a value type |
| `features/documents/data/repositories/drift_document_repository.dart` | Thread `workspace_id` through every query; add `watchVersions`, `restoreVersion`, `recordActivity` |
| `features/documents/presentation/providers/document_providers.dart` | New: `activeProfileProvider`, `versionListProvider(docId)`, `activityFeedProvider(docId)`, `blobStorageStatsProvider`. **Test rule (learned the hard way): never `await` a `StreamProvider.future` — `container.listen(provider,(_,_) {})` + `await Future.delayed(Duration.zero)`, then read `.value`** |
| `features/documents/presentation/widgets/document_preview_panel.dart` | "Riwayat Versi", "Catatan", "Serahkan Dokumen" actions. Preserve the 1500/400-char truncation that fixed the earlier freeze |
| `features/documents/presentation/widgets/document_toolbar.dart` · `document_list_item.dart` | "Ganti File" becomes create-version, never in-place overwrite |
| `features/documents_explorer/presentation/home_layout.dart` · `document_sidebar.dart` | Version-pending badge, storage-pressure banner, retention-due list, "Perlu Perhatian" |
| `features/command_palette/presentation/command_palette_modal.dart` | Add `versi:`, `klasifikasi:`, `belumdisinkron:` prefixes to `parseDocumentQuery`; multi-prefix combination must keep working (`phase55_search_test.dart` is the guard) |
| `features/sync_center/presentation/sync_center_screen.dart` | Add the **pull** direction: last cursor, received count, conflicts pending, versions pending upload, per-provider rows |
| `features/document_reader/presentation/document_reader_screen.dart` | Version selector in the reader; annotation overlay (P3.5); desktop renderer swap (P3.7) stays behind `isAvailable()` |

**Offline behaviour, stated per feature** — the PRD never addresses this and the app is local-first, so the plan must:

| Feature | Offline behaviour |
|---|---|
| View history | Full: local blobs render immediately; Drive-only versions show size + provider + "hanya di Drive" |
| Replace file / create version | Fully local. Cloud mirror queued in the existing outbox |
| Restore version | Fully local and instant (bytes are on the device); server registration queued |
| Activity timeline | Fully local; mirror queued, deduplicated by `operationId` on resend |
| Annotations | Local always. Exported into the handover bundle |
| Handover export | **Requires no network by design** — that is its whole reason to exist (V-1) |
| Pull sync | Queued; on reconnect resumes from the persisted cursor. Never loses local work (§2.2 of roadmap 6.5) |
| Search | Local FTS unaffected. Server search shows an honest "butuh koneksi" state, never a stale spinner |

---

## 3. Implementation Phases

```
P0 baseline ──► P1 VERSIONING ──► P2 cross-device convergence ──┬─► P4 security & privacy
                            │                                    ├─► P5 records & adoption UX
                            └─► P3 discovery & reading ──────────┘
                                              P6 multi-cloud (optional, any time after P1)
```

| Phase | Outcome | Priority | Effort | Depends on | Roadmap |
|---|---|---|---|---|---|
| **P0** | Measured baseline + metric definitions | P0 | **S** (days) | — | 5.7 |
| **P1** | Version history, lifecycle, activity, handover | **P0** | L | P0 | 7.1–7.5 |
| **P2** | One person's devices converge safely | **P0** | L | P1 | 6.1–6.7 |
| **P3** | Find and read by content | P1 | L | P1 (browsing), P2 (server parts) | 5.2–5.5 |
| **P4** | Device-loss is not a data breach | **P1** | M | P1 | 9.10, 3.6–3.7 |
| **P5** | Records discipline + adoption UX | P1/P2 | L | P1–P3 | 4.2, 8.5–8.6 lite, 9.8–9.9 |
| **P6** | Optional multi-cloud | P3 (opt-in) | XL | P1 | 2.4–2.5 |

**⛔ Single decision gate.** **T-1: is institutional multi-user sharing actually required?** If yes, this plan
delivers P0–P5 and Appendix T becomes a separate funded product increment. If no (the assumption here), P0–P6 is the
whole story. Nothing before Appendix T needs T-1 resolved — the schema hedge in §2.2.4 keeps the door open at
roughly zero current cost.

---

### Phase P0 — Baseline and measurement *(days, not weeks — do it first)*

**Outcome:** the PRD's NFR and all four success metrics become evaluable, and the "before" photograph exists before
anything changes it.

- [ ] **P0.1 Write `docs/METRICS.md`.** One definition per metric with its formula, its event, and its prohibited
  fields. Specifically define "document-related error" as the four categories in §1.4 — the PRD's "30 % fewer
  errors" is unimplementable until someone commits to what an error is.
- [ ] **P0.2 Device benchmark at 10 000 documents.** Seed with the existing `dummy_data_seeder.dart` plus
  representative OCR-length text; record on **one named device** (roadmap 5.7 requires naming it): cold app open,
  library first-paint, search round-trip excluding debounce, scroll frame budget, open-a-PDF, swipe-to-delete.
  These numbers become the budgets P1–P3 must not exceed and the evidence for N1's 2-second claim. **Skipping this
  makes N1 permanently unevaluable — and the numbers cannot be recovered later.**
- [ ] **P0.3 Local counters table (Drift v7 `usage_counters`) + `metrics_service.dart`.** Events per §1.4:
  `search_executed{source,result_count,latency_ms,opened_result,ms_to_open}`, `document_opened{source,mime}`,
  `duplicate_detected{action}`, `version_created`, `version_restored`, `import_failed{category}`,
  `error_shown{code}`. **Local-only by default.** Hard-coded prohibition list, enforced in a unit test: no document
  content, no filename, no title, no query text (a token-count or length is acceptable), no absolute path.
- [ ] **P0.4 `Ringkasan Produktivitas` self-view** (`productivity_summary_screen.dart`): median search→open time,
  duplicates avoided, versions restored, over the last 30 days. This is the metric surface for a *personal* tool —
  the user sees their own delta.
- [ ] **P0.5 Optional reporting, opt-in.** A per-profile switch, off by default, that batches P0.3 counters to the
  user's own configured backend. Consent copy is explicit about exactly what leaves the device. Server table only
  if the switch is ever enabled — do not create `usage_events` speculatively.

**Files:** `docs/METRICS.md` (new), `client/lib/core/database/tables/usage_counters.dart`,
`client/lib/features/metrics/`, `client/test/{baseline_regression_test,p0_metrics_test}.dart`
(`baseline_regression_test.dart` already exists and is the right home for P0.2's assertions).

**Checkpoint:** a numeric baseline table in `docs/METRICS.md`, device named, and `flutter analyze` 0 errors.

**Acceptance gate:** every PRD metric maps to a defined formula and an event that existing code actually emits;
opt-out is the default; no counter contains content; the benchmark is reproducible by re-running one command.

---

### Phase P1 — Version history and document lifecycle ← **build this first**

**Outcome:** PRD F4 in full (automatic versioning, view/restore, change logs) plus the transfer mechanism that
replaces F2 — and the identity model every later phase stands on. **Entirely functional offline.**

- [ ] **P1.1 Refcount-guarded blob store (the safety prerequisite).** `content_blobs` table +
  `ContentBlobStore`: content-addressed under `blobs/<sha256[0:2]>/<sha256>`, streaming SHA-256 (never
  `storeBytes`'s full-file buffer), **and a refcount check on every delete path** — today
  `deleteManagedFile` (`storage_service.dart:184-196`) deletes unconditionally. Adopt existing flat files as v1 via
  `legacy_path` with **zero byte movement** (§2.2.1). *This task comes before version creation: an unguarded delete
  plus shared blobs is data loss.*
- [ ] **P1.2 `document_versions` (Drift v5) + version identity.** `version_number` per document, immutable rows,
  `metadata_snapshot` capturing the description as it was then. Explicitly separate from `baseRevision` (§2.2.4) —
  assert in a test that a metadata edit advances `revision` but **not** `version_number`.
- [ ] **P1.3 Replace-file = create version.** Rewire `document_toolbar.dart` / `document_list_item.dart` from
  in-place overwrite to version creation. Same bytes ⇒ same blob, new version row (dedup, no disk growth).
  Metadata-only edits never duplicate bytes.
- [ ] **P1.4 Restore = new current version.** Restoring v3 from v7 creates v8 with v3's blob reference; **v4–v6 are
  never destroyed**. Non-destructive by construction, because F4 asks for restore *and* for "a history of all
  document versions" simultaneously.
- [ ] **P1.5 Activity timeline.** `activity_events` (local) recording import, metadata edit, version created,
  restored, trashed, purged, backup, integrity finding, handover. Surface as *Riwayat Dokumen Saya*; label the
  actor as "this device/profile" honestly (V-3). Mirror to the user's own workspace when a backend is configured
  (`008`), idempotent by `operationId`.
- [ ] **P1.6 Version management UI.** `document_history_screen.dart` with a timeline, per-version size,
  local-vs-Drive availability, restore, download-for-reference, and a metadata diff sheet. Storage budget bar +
  **explicit "prune old versions"** action (confirmation, never prunes a version that is someone's only copy —
  invariant 6). Cursor-paged, because a version list is exactly where `OFFSET` pain appears.
- [ ] **P1.7 Handover export (the F2 substitute).** `export_handover_screen.dart` produces a self-contained bundle:
  selected version's bytes (or all versions) + metadata + activity + a human-readable `README.txt` + SHA-256
  manifest, written to a folder or the OS share sheet. Works with no account and no network. Receiver imports it via
  the existing backup-restore path with hash verification and mandatory `ConflictPolicy`. **Label it
  "penyerahan dokumen", not "sharing"** — it grants no permissions and cannot be recalled, which the UI must say.
- [ ] **P1.8 Externally-modified detection → version.** `library_integrity_service.dart` already flags changed
  content; today "needs review" is terminal. Add *import as version* / *discard local change*.
- [ ] **P1.9 Manifest v3.** Extend the portable backup to carry versions, blobs, and activity; v1/v2 archives stay
  restorable. Version bytes dedup by hash inside the folder layout. Verify: a restore reconstructs **history**, not
  just the current file (roadmap 7.5).
- [ ] **P1.10 Server mirror.** `006_add_document_versions.sql` + `versions` module +
  `POST/GET /api/v3/documents/:id/versions`, `POST …/current-version`, `GET/POST …/activity`. Metadata only,
  workspace-scoped, idempotent, optimistic-concurrency on the current pointer. **No content route.**

**Files:** `client/lib/core/database/tables/{document_versions,content_blobs,activity_events}.dart`,
`client/lib/core/services/content_blob_store.dart`, `client/lib/features/{versions,activity,handover}/`,
`client/lib/core/services/library_backup_service.dart` (v3), `server/src/database/migrations/{006,008}_*.sql`,
`server/src/modules/versions/`, `server/src/modules/activity/`,
`client/test/{document_versioning,blob_refcount,version_restore,handover_export,backup_manifest_v3}_test.dart`,
`server/src/modules/versions/usecases/register-document-version.test.ts`.

**Checkpoint:** full suite green, including the pre-existing 119 client / 55 server tests. `p0_metrics_test` shows
the P0.2 budgets still met (versions must not slow the library).

**Acceptance gate:**
- Replacing and restoring **never lose previous bytes** — hash-asserted in a test that fails if any version's blob
  disappears.
- Deleting version N leaves version M's bytes intact when they share a blob (refcount = 2 → 1, file survives).
- A metadata edit advances `revision`, not `version_number`.
- Every feature works with the backend disabled and with no Drive account.
- A pre-existing library upgrades to v5 keeping N documents, M bytes, identical hashes, all openable (§R-08 test).
- Replaying a queued version registration creates exactly one version and one activity event.
- Handover bundle restores into a clean install with versions intact and every hash verified.

---

### Phase P2 — Cross-device convergence

**Outcome:** F5's "seamless synchronization" for one person's devices — the highest-value thing the PRD asks for
that the codebase most clearly lacks. Today sync is push-only; a second device cannot see the library, and after P1
it also cannot see any version history.

**Depends on P1** deliberately: converging a model without version identity means conflicts over which bytes are
current, and P1 makes that answerable.

- [ ] **P2.1 Change feed + tombstones** (`007`). `change_log` with a monotonic server sequence — **not client
  timestamps, and not `updated_at`** (a late-committing transaction would be skipped, roadmap 6.3). Every mutation
  and tombstone appends in its own transaction. `GET /api/v3/sync/changes?cursor=&limit=`; an invalid/expired
  cursor signals a paginated full resync.
- [ ] **P2.2 Pull applied transactionally on the client.** `pull_sync_service.dart` + Drift v6 `change_cursors`:
  commit applied rows and the next cursor in **one** transaction (interruption can never advance the cursor without
  its data). Merge acknowledgments into pending outbox jobs so a pulled remote change does not clobber an unsent
  local edit.
- [ ] **P2.3 Remote-only records have no fake path.** A document whose bytes live elsewhere gets
  `localAvailable = false` with explicit availability, **never a fabricated `localFilePath`** (roadmap §6.2).
  Download-on-demand, plus a per-document "keep offline" flag with a visible size cost (roadmap 6.7).
- [ ] **P2.4 Conflict resolution.** On `conflict` outcome or divergent current pointer: preserve both, open
  `conflict_resolution_screen.dart` offering *keep local as new version* / *keep remote* /
  *duplicate as new document*. **Binary conflicts are never auto-merged** (roadmap 6.5), and a rejected stale update
  does not erase local work.
- [ ] **P2.5 Profile partition.** Finish roadmap 3.5: credentials, jobs, roots, metadata, and version blobs keyed
  by profile; switching profiles shows nothing of the other. Sign-out = credential removal + stopped sync, with a
  separate explicit action to delete cached files. This is also P4's access control (there is no other).
- [ ] **P2.6 Deletion scopes** (roadmap 6.6). Separate *remove local cache* / *global trash with durable tombstone*
  / *delete the Drive copy*. Tombstones retained for a defined offline window; older clients resync rather than
  resurrect deleted records.
- [ ] **P2.7 Drive download/restore** (roadmap 6.1). Restore into staging, verify against the recorded SHA-256,
  activate atomically, preserve document IDs; report inaccessible / trashed / deleted / changed-content /
  interrupted distinctly; never overwrite a differing local copy without a decision. Includes the §2.2.1 rule:
  if a version exists only as a Drive revision, pull it into a local blob rather than trusting retention.
- [ ] **P2.8 Catalog backup** (roadmap 6.2). A versioned manifest in the app's Drive area so a library can be
  reconstructed **when the optional PostgreSQL server was never used** — essential for the no-login population.
  Legacy uploads without a manifest show incomplete metadata rather than invented metadata.

**Files:** `server/src/database/migrations/007_*.sql`, `server/src/modules/documents/usecases/list-document-changes.usecase.ts`,
`client/lib/core/services/{pull_sync_service,library_restore_service}.dart`,
`client/lib/core/database/tables/change_cursors.dart`, `client/lib/features/conflicts/`,
`client/test/{cross_device_sync,pull_transaction,conflict_resolution,deletion_scope}_test.dart`,
`server/src/modules/documents/usecases/list-document-changes.test.ts`.

**Acceptance gate:** two devices editing the same document offline **both keep their work** and either converge or
present a conflict; a clean device reconstructs the catalog and restores matching bytes; a deletion is not
resurrected by a stale client; repeated cursor pages are idempotent; interruption cannot advance the cursor without
its data; a profile switch exposes nothing of the other profile.

---

### Phase P3 — Discovery, annotation, and reading

**Outcome:** F3 in full, and the annotation half of F2. Mostly on-device; server work only where a backend is
configured.

- [ ] **P3.1 Server search parity.** Extend `009`'s filter set to match `parseDocumentQuery`'s dimensions so the
  same query gives the same answers on both devices (today server = 2 filters vs client = 9).
- [ ] **P3.2 `unaccent` + `pg_trgm`** per §2.2.3, with the explicit no-stemming rationale recorded in the migration
  comment so nobody "fixes" it by inventing an Indonesian dictionary.
- [ ] **P3.3 Tag ergonomics.** Server normalization (`005`) + client autocomplete, rename, merge, usage counts in
  the sidebar. Tags are the one Phase 4 feature with a real cross-device gap.
- [ ] **P3.4 Snippets and highlights.** `ts_headline()` server-side, FTS5 `snippet()`/`highlight()` client-side,
  page references where OCR stores them. This is the direct answer to F3's "results display … previews".
- [ ] **P3.5 Personal annotations.** `annotations` table (Drift v6): page-anchored notes on a document, surfaced in
  the reader and the preview panel, exported into the P1.7 handover bundle. **The genuinely useful remainder of
  "collaboration" for a single-operator tool**, and it works offline.
- [ ] **P3.6 On-device thumbnails.** Render page 1 to an image, cached by source blob hash (so a new version
  invalidates correctly). **Local, not a server sidecar** — the server has no file (§2.2.1). Bounded concurrency and
  a size ceiling so one large PDF cannot stall the UI.
- [ ] **P3.7 Desktop reader.** `flutter_pdfview` is mobile-only, and civil servants work on Windows desktops — so
  F3's preview is unreachable on the primary platform today. Evaluate `pdfrx` (MIT) before `syncfusion_pdfviewer`
  (commercial = a budget decision, not a code one); gate on verified Windows rendering. Until accepted, the preview
  column shows the thumbnail + "buka di aplikasi luar" and states the limitation. **No web rewrite to satisfy a
  plugin gap** (roadmap 9.6).
- [ ] **P3.8 Search latency budget.** Using P0 counters, demonstrate p95 < 300 ms local (roadmap 5.7's proposed
  figure) and the 2-second NFR for search *and* open — or record honestly which surface misses.
- [ ] **P3.9 Text extraction** (roadmap 5.3–5.4, ❌ Not started — this is why F3's content search is thin in
  practice). Order matters: **digital-PDF text layer first** (cheap, high hit rate), then on-device MLKit OCR for
  image-only pages (dep already present), then Indonesian/English as an explicit user choice with correction before
  accept. Job state keyed to the version's content hash so a new version invalidates prior work. **No document
  content to any external OCR/AI service without explicit consent** (roadmap 5.4) — a rule the personal posture
  makes easy, since there is no server to send it to.

**Files:** `server/src/database/migrations/005_*.sql`, `009_*.sql`, `client/lib/core/database/tables/annotations.dart`,
`client/lib/core/services/text_extraction_service.dart`, `client/lib/features/{annotations,reader}/`,
`client/test/{phase55_search_test,annotation,thumbnail_extraction,text_extraction}_test.dart`.

**Acceptance gate:** a phrase present only in OCR text is discoverable; snippets highlight the matched term; a
10 000-document library returns first results within the P0.2 budget with scrolling still responsive; combined
palette prefixes still parse (`phase55_search_test.dart` stays green); annotations survive restart, export into a
handover bundle, and never appear in a sync payload as document content.

---

### Phase P4 — Personal security and privacy *(elevated from Rev. 1's M7)*

**Outcome:** losing the device is not losing the records. Under this posture, this is **the** security phase —
there is no server-side ACL to lean on.

**If the deployment's records are classified `rahasia` or `dalam_perhatian_istimewa`, P4 swaps ahead of P2/P3.**
Say so at plan approval rather than discovering it after a laptop goes missing.

- [ ] **P4.1 App lock** (`local_auth`, biometric or device credential) with a configurable timeout.
  **Labelled explicitly as a convenience layer, not encryption** — roadmap 9.10's own words. Do not let the UI,
  the docs, or the privacy policy imply otherwise.
- [ ] **P4.2 Encryption at rest, in the order that buys the most first:**
  1. **Backup folder** (P1.9) — AES-GCM per blob with a KDF-derived key from the user's passphrase + salt, header
     recording the algorithm and parameters, **recoverability proven before anything is marked encrypted** (an
     unrecoverable encrypted backup is worse than an honest plaintext one). Roadmap 1.6's "not encrypted" warning
     is deleted only when this test passes.
  2. **Sensitive columns** (`extracted_text`, `notes`, `annotations`) — application-layer, key held in
     `flutter_secure_storage`. Note the real cost: encrypted `extracted_text` **cannot be FTS-indexed as plaintext**,
     so either the index keeps a derived plaintext copy (and inherits the exposure) or content search is disabled for
     encrypted profiles. **Make the user choose; do not pick silently** — this is the trade Rev. 1 blurred.
  3. **Whole managed store** — only as an opt-in "confidential mode" with the same recoverability gate.
  4. **Client SQLite via SQLCipher — recommended AGAINST** (R-05): a plain SQLite file cannot be converted in place,
     so it needs read-all/write-all plus key escrow for every existing install. Prefer device-level volume
     encryption, which the OS provides and this project does not have to get wrong.
- [ ] **P4.3 Cloud off by default, per-document policy.** A new import is local unless the user opts in. A
  `classification` of `rahasia` **blocks** consumer-cloud upload with a visible reason (P5.1 supplies the field).
- [ ] **P4.4 Transport hardening** (roadmap 3.6, undone). HTTPS required outside loopback, HSTS, bounded timeouts,
  per-identity throttling, allowlisted browser origins via the existing `CORS_ORIGINS`, and removal of manual token
  entry from release UX (keep it debug-only).
- [ ] **P4.5 Threat model + truthful disclosures.** A short written threat model (asset: the record; adversary:
  device loss, shoulder-surfing, a synced consumer cloud, a restored backup) mapped to what P4 actually implements.
  Rewrite `PRIVACY_POLICY.md` to state: local-first storage, what exactly leaves the device and when, that a synced
  provider holds copies **we cannot recall**, that P0 counters are local unless opted in, and the P4.1
  lock-is-not-encryption distinction. Roadmap 3.7 is undone; do it here.

**Files:** `client/lib/features/privacy/`, `client/lib/core/services/backup_crypto_service.dart`,
`client/lib/core/services/library_backup_service.dart`, `PRIVACY_POLICY.md`, `docs/THREAT_MODEL.md` (new),
`client/test/{backup_encryption_roundtrip,confidential_mode,cloud_optout}_test.dart`.

**Acceptance gate:** every encryption claim in the policy matches code behaviour and is backed by a passing
round-trip test; a lost passphrase is either recoverable by design or the UI says recovery is impossible; a
`rahasia` document cannot reach any consumer cloud through any code path; no route is reachable over plain HTTP
outside loopback; P4.1's UI never uses the word "encrypted".

---

### Phase P5 — Records discipline and adoption UX

**Outcome:** the office-workflow parts of the PRD that a single clerk controls, plus the UX the adoption and
satisfaction metrics depend on.

- [ ] **P5.1 Records metadata.** Incoming/outgoing register, sender/recipient, responsible unit, classification
  (`biasa` / `terbatas` / `dalam_perhatian_istimewa` / `rahasia`), related-document links. Local-first, mirrored to
  the user's workspace (`010`). **Register numbers:** allocated transactionally when online; **offline drafts use a
  temporary ID and never claim an official sequence number** (roadmap 8.5) — the easiest place in this plan to
  create a legally wrong artifact, so it needs an explicit test.
- [ ] **P5.2 Retention, single-user scale.** Owner-set schedules by class, retention-due list on the sidebar,
  **manual** disposal approval with a record of what was actually removed, `legal_hold` flag on a version that blocks
  prune (which also closes P1.6's loophole). **Automated destruction stays off by default.**
- [ ] **P5.3 Category management** (F1 completion). Create / rename / archive / merge, per-workspace, with
  user-confirmed merge only — `organization.dart:8-11` already encodes the never-auto-merge rule; extend it to the
  server, where `document_categories` is currently global and unwritable (§1.1).
- [ ] **P5.4 First-run experience** (roadmap 9.9). Explain local vs cloud vs index in one screen, offer optional
  connect/restore, show last-successful-backup status, and **never require sign-in to import locally**.
- [ ] **P5.5 Help centre** (N4). Searchable in-app help, per-feature contextual entry points, honest statements of
  what is not guaranteed (exported copies, Drive revision retention, app lock).
- [ ] **P5.6 Accessibility + localization** (roadmap 9.8). Screen-reader names, predictable focus order, non-colour
  status cues (version/sync/classification chips currently lean on colour), `prefers-reduced-motion`, 200 % text
  scale, strings extracted to `app_id.arb` **preserving existing Indonesian terminology**.
- [ ] **P5.7 CI** (roadmap 9.1 — "start early", never started). `.github/workflows/ci.yml`: `flutter analyze` +
  `flutter test`, `tsc --noEmit` + `npm run test:ts`, a real Postgres service for migration + tenancy tests, and
  the authz matrix. **Everything in this plan is a manual-verification claim until CI runs it on every change.**

**Acceptance gate:** register numbers show no gap and no duplicate after a simulated offline drafting storm; a legal
hold blocks prune across original + versions + Drive-mirrored references; retention-due counts come from the
database, not a Dart scan; CI runs the full suite and fails on a tenancy or migration-drift violation; a screen
reader can complete import → search → open → create version → restore using the keyboard alone.

---

### Phase P6 — Optional multi-cloud *(P3 priority: only if a real cohort needs it)*

**Outcome:** F5's provider breadth, sequenced so it cannot become the reason the plan stalls.

- [ ] **P6.1 `RemoteContentProvider` seam, behaviour-preserving.** Wrap `gdrive_service.dart` behind
  `drive_content_provider.dart`. **P6.1 adds zero features** and must prove no behaviour change against the existing
  resumable-session, app-properties-dedup, and folder-resolution tests. Keep `IStorageService` as the *local* seam
  (correctly implemented today) — the two interfaces are different things and should not be merged.
- [ ] **P6.2 Capability + policy model.** `capabilities()` per provider; per-document and per-classification
  location policy; provider choice stored server-side so device 2 inherits it.
- [ ] **P6.3 OneDrive** (recommended first new provider — Microsoft 365 is the most common estate in Indonesian
  local-government IT). Graph `uploadSession`, chunk boundaries aligned to the protocol's multiples, conflict
  behaviour explicit, `/versions` for revision evidence, and `immutableRevisions` reported truthfully.
- [ ] **P6.4 Dropbox.** Last, and only after P6.3 passes the contract suite. Block sizes and the `rev` versioning
  model verified against current docs at implementation time, not assumed from memory.
- [ ] **P6.5 Provider migration.** Copy → verify SHA-256 → repoint → only then drop the old reference. Version
  identity invariant across a Drive→OneDrive move; `provider_version_ref` updated with the previous value retained
  while the old copy still exists.
- [ ] **P6.6 Large files** (PRD open question 2). Streaming everywhere; resumable across restarts via the
  `drive_upload_sessions` pattern generalized with a `provider` column; a documented size ceiling with an Indonesian
  over-limit message; **never buffer a whole file** — `storeBytes` (`storage_service.dart:135-172`) is the existing
  counter-example to fix, not to copy.

**Acceptance gate:** one identical contract suite (upload / resume-after-kill / dedup / rename-does-not-move-file /
recoverable-trash / verify-detects-change) passes for every provider; a Drive-only personal user notices nothing;
**a provider failing the suite is hidden in the UI rather than half-enabled** (the rule already applied to
`flutter_pdfview`); a migration leaves version IDs and history intact.
