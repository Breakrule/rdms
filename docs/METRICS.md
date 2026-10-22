# RDMS Ultimate — Metric Definitions

> Authoritative source for every number this project claims. Written as **P0.1** of
> `implementation_plan_major.md`; that plan's acceptance gate for Phase P0 is that each metric below maps to an
> event that existing code actually emits, and to a formula that is computed in code rather than in a slide.
>
> If a document, screen, or report states a figure that is not derivable from this file, the figure is wrong.

---

## 1. What this product is measuring, and for whom

RDMS Ultimate is an **offline-first personal document library**. Metrics are therefore computed **on the device**,
from counters stored in the local `usage_counters` table, and surfaced to that one user in
**Ringkasan Produktivitas** (`features/metrics/presentation/productivity_summary_screen.dart`).

The CivilDoc PRD's metrics were written for a *mandated institutional rollout* ("80 % of local government
employees"). Under this posture there is no central server that observes users, so **org-wide adoption is not
measurable here** and is not claimed. What is measurable — and what the plan actually optimises — is the individual
delta: does this tool make finding and filing a record faster for the person holding the device.

### 1.1 Prohibited fields (enforced by test, not policy)

No counter, event, aggregate, or opt-in report may contain any of the following. `client/test/p0_metrics_test.dart`
asserts this by attempting to record a prohibited value and reading the stored row back.

| Prohibited | Why |
|---|---|
| Document title, notes, or any user text | Content. `search_executed` stores a **token count**, never the query |
| `extractedText` or any OCR output | Content, and potentially the most sensitive data in the system |
| File name, original file name, extension | Filenames in this domain *are* content (`PERATURAN_2026_...`) |
| Category code, tag name, classification level | Reveals record types held by a person; derivable by the holder, not by us |
| Absolute or relative local path | Established privacy rule — `backend_sync_client.dart:119-121` already omits paths from sync |
| Credential, token, Drive file id, backend URL | Never a metric input in any code path |
| Free-text error message | Only a bounded `code` from a fixed vocabulary is stored |

Permitted: event name, timestamp, workspace/profile UUID, latency and count integers, MIME *type family*
(`pdf` / `image` / `other`), a bounded enum for source and outcome, and an optional `documentId` UUID (see §4.3).

---

## 2. The PRD's four success metrics, as actually computed

### M1 — User adoption
**PRD target:** 80 % of local government employees use the app within the first year.
**Status: NOT MEASURABLE under this posture.** There is no server-side observability of installations by design
(commitment 3 of §0.1: the server holds metadata only and no user is required to sign in). Reporting the institutional
figure would require every user to opt in to P0.5, and even then it measures *installs that report*, not adoption.

**Local proxy** — `days_active_30d`:
```
days_active_30d = COUNT(DISTINCT DATE(occurred_at)) WHERE occurred_at > now - 30d AND event IN ('session_start','document_opened','search_executed')
```
Labelled in the UI as *Hari aktif (30 hari)* with an explicit note that it is a self-view, not a utilisation report.

### M2 — Time savings: "reduce document search time by 50 %"
**Primary metric.** Fully measurable, fully local, and attributable to the discovery work in P3.

```
time_to_open_ms = ms from search_executed.occurred_at to the matching document_opened
                  (same session, same documentId, bounded to 120 s)
median_time_to_open = MEDIAN(time_to_open_ms) over the last 30 days
```
Search-time improvement is reported as `1 - (current_median / baseline_median)`. The **baseline is the recorded
value in §3**, not a re-measurement of the new build, so the comparison is genuine rather than self-referential.

Supporting counters:
- `search_executed` — `{latency_ms, result_count, token_count, source}` where `source ∈ {palette, list_search, sidebar, tag, collection}`
- `document_opened` — `{source, mime_family, local_available}`
- `search_abandoned` — emitted when a search returns results and the session then ends or a new query replaces it
  without an open. A falling abandonment rate is a better signal of search quality than raw latency.

### M3 — Error reduction: "decrease document-related errors by 30 %"
The PRD does not define "error". **Defined here as four countable categories**, because an undefined metric cannot
move:

| Code | Definition | Event | Counterpart that prevents it |
|---|---|---|---|
| `duplicate_filed` | Import where content SHA-256 already exists in the library and the user chose to keep it anyway | `duplicate_detected{action ∈ {skip, open_existing, keep_separate}}` | Phase 4.5 hash check (exists) |
| `superseded_version_distributed` | A version other than `current_version_id` opened, exported, or included in a handover | `version_opened{is_current}` / `handover_exported{version_count}` | **P1 versioning** — this is the error class the PRD's metric really describes |
| `misfiled` | Category or classification corrected within 7 days of import | `metadata_edited{field, days_since_created}` | P5.1 classification + register validation |
| `document_lost` | Managed file missing or hash-changed with no recoverable copy | `integrity_finding{kind ∈ {missing, changed, orphan}}` | P1 blobs + P4 encrypted backup |

```
error_events_per_1k_docs = COUNT(*) WHERE event IN ('duplicate_detected','metadata_edited','integrity_finding','version_opened') AND <counts as an error per the table above>
                           / COUNT(DISTINCT documentId) * 1000
```
Reported per category, never as a single blended number — a blended "errors down 30 %" is unfalsifiable.

### M4 — Satisfaction: "4.5/5 in quarterly user surveys"
**Status: an operational process, not a code deliverable.** P5.6 supplies the instrument:
`survey_response{score ∈ 1..5, comment_present}` stored locally. No code in this plan can produce the quarterly
figure; someone must run the survey. Stated plainly so the number is never implied by a dashboard.

---

## 3. Performance baseline and budgets

### 3.1 Provenance of these numbers — read before quoting them

`P0.2` established the baseline as a **host-side benchmark**, executed by:

```powershell
cd d:\Developers\Projects\document-management-system\client
$env:DMS_BENCHMARK="1"; flutter test test/p0_baseline_benchmark_test.dart
```

Environment recorded at run time by the benchmark itself and written into `docs/METRICS.md` §3.2 only by a human
copying real output — the test prints values, it never edits this file.

**What these numbers are:** SQLite/Drift query costs on the development host at 10 000 metadata rows, plus
file-level SHA-256 and copy costs. They are the operations `docs/ROADMAP.md` Phase 5.6 identified as the cause of
the earlier UI freezes (whole-library Dart remap and sort), so they are the operations a P1–P3 regression would
show up in first.

**What these numbers are not:** a mobile, desktop-app, or cold-start measurement, and not the PRD's
"load documents and search results within 2 seconds" satisfied. This project targets Android/iOS/web; there is no
desktop target in the repository, and `docs/ROADMAP.md:70-71` already lists real-device verification as blocked in
this environment. **NFR N1 remains UNVERIFIED until measured on hardware.** The budgets below are therefore
provisional regression guards, not compliance claims.

### 3.2 Baseline (measured)

Recorded from a real `DMS_BENCHMARK=1` run of `test/p0_baseline_benchmark_test.dart`.

- **Host:** Windows 11 Home Single Language, 10.0 (Build 26300) — development machine, **not a target device**
- **Toolchain:** Dart 3.13.4, Flutter 3.47.5, Drift `NativeDatabase.memory()`
- **Corpus:** 10 000 documents across the five real categories, a decade of dates, OCR-length text on 10 % of rows, 1 000 rows tagged
- **Seeding time:** 2 253 ms including FTS trigger writes
- **Samples:** 21 per operation, microsecond-resolution stopwatch, sorted percentiles

| Operation | p50 (ms) | p95 (ms) | Budget = 2× p95 |
|---|---|---|---|
| `watchDocumentPage` first page, no filters | 8.10 | **18.72** | 37.43 |
| `watchDocumentPage` first page, FTS search | 3.48 | 4.48 | 8.97 |
| `watchDocumentPage` deep page (offset 5 000) | 7.50 | 10.50 | 21.00 |
| `watchDocumentPage` tag filter (EXISTS) | 3.85 | 4.88 | 9.76 |
| `watchDocumentPage` category + fiscal year | 0.23 | 0.54 | 1.08 |
| `watchDocumentCount` with tag filter | 0.21 | 0.59 | 1.18 |
| `watchCategoryCounts` | 0.59 | 1.07 | 2.14 |
| `watchStatusSummary` | 0.20 | 0.73 | 1.46 |
| `watchDocumentById` | 0.42 | 0.88 | 1.76 |
| `HashUtil.calculateFileSha256` 1 MB | 24.00 | 26.32 | 52.64 |
| `HashUtil.calculateFileSha256` 10 MB | 206.51 | 217.12 | 434.24 |
| `LocalStorageService.storeFile` copy 1 MB | 47.91 | 55.27 | 110.53 |

**What this baseline already tells us — read before starting P1.**

1. **The first page at `limit: 100` exceeds the 60 fps frame budget.** p95 = 18.72 ms against §3.3's 16 ms frame
   ceiling. It is not a freeze (Phase 5.6 removed those) but it is one frame of dropped work on the hottest path,
   and it will grow with every column added to the row mapping. **P1 must not add work to this path without
   re-measuring it** — that is precisely the R-10 mechanism.
2. **Deep offset paging costs 7.5 ms at offset 5 000 where the filtered page costs 0.23 ms.** The `OFFSET` penalty
   is real and already 30× the equivalent filtered query, which is the empirical support for §2.3's cursor-paging
   rule rather than a stylistic preference.
3. **Version creation has a known, non-trivial cost: ~50 ms copy + ~25 ms hash per MB**, so a 10 MB replace costs
   roughly **260 ms** on this host. It stays inside the PRD's 2 s budget and runs in an isolate (`calculateFileSha256`
   already does), but P1.1 must not regress it into a buffered path.
4. **Count/aggregate queries are all sub-millisecond.** Sidebar counts and summaries are not a scaling risk at
   10 000 rows; the plan's scaling attention belongs on the page query and on `audit`/`usage` table growth.

### 3.3 Standing budgets

- No single DB operation on the UI hot path may exceed its §3.2 budget, or exceed **16 ms** for anything that runs
  during a scroll frame — the latter is the frame-budget rule from `docs/ROADMAP.md` Phase 5.7. **The first-page
  query is already over that line at p95; it is listed as a known condition, not as a passing budget item.**
- Library first-paint and search round-trip target the PRD's **2 000 ms** on-device, *pending real hardware
  measurement*; provisional local guard is p95 < **300 ms** per roadmap 5.7 — met by every query above with a wide
  margin.
- Re-run the benchmark at every phase gate. A p95 regression greater than **2×** the recorded baseline fails the
  gate (plan risk R-10).

---

## 4. Storage model for counters

### 4.1 Table
`usage_counters` (Drift `v5`, `client/lib/core/database/tables/usage_counters.dart`):

| Column | Type | Notes |
|---|---|---|
| `id` | text | UUID |
| `workspace_id` | text | Profile scoping; defaults to the personal workspace UUID |
| `event` | text | Bounded vocabulary (§2), indexed with `occurred_at` |
| `occurred_at` | datetime | Device-local time, stored UTC |
| `session_id` | text nullable | Groups `search_executed` → `document_opened` for M2 |
| `document_id` | text nullable | Random UUID; **stripped before any upload** (§4.3) |
| `latency_ms` | int nullable | |
| `count_value` | int nullable | `result_count`, `version_count`, etc. |
| `context` | text nullable | Fixed enum only — source, action, kind. Never free text, never content |
| `pending_report` | bool | Default `false`; set `true` only while opt-in reporting is enabled |

### 4.2 Emission points in existing code
The P0 acceptance gate requires that metrics are emitted by **real call sites**, so these are wired in P0.3:

| Event | Emitted from |
|---|---|
| `session_start` | `features/splash/presentation/splash_screen.dart` completion |
| `search_executed` | `features/documents/presentation/providers/document_filter_providers.dart` (debounced query path) and `features/command_palette/presentation/command_palette_modal.dart` |
| `document_opened` | `features/documents/presentation/widgets/document_list_item.dart` open action and `core/services/file_opener_service.dart` |
| `duplicate_detected` | `features/documents/presentation/widgets/duplicate_check_dialog.dart` decision |
| `metadata_edited` | `DriftDocumentRepository.updateDocumentMetadata` |
| `integrity_finding` | `core/services/library_integrity_service.dart` |
| `error_shown` | `core/widgets/custom_toast.dart` error variant, with a bounded code |

### 4.3 Opt-in reporting
`MetricsService` never transmits. Only when a user enables *Laporkan ringkasan penggunaan* (P0.5) are **aggregates**
batched to the configured backend, and the aggregator drops `document_id` and `session_id` and keeps only counts,
medians, and event names. There is deliberately no server table for this in P0–P6: the plan does not create
infrastructure for a feature that is switched off by default.

---

## 5. Change log

| Date | Change |
|---|---|
| (P0.1) | File created with metric definitions, prohibited-field list, and provisional budget framework. Baseline values pending the P0.2 run. |
