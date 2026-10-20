# Homepage UI/UX Redesign Implementation Plan

> **Status:** Proposed design and implementation plan. Creating this document does not authorize or start UI implementation.
> **For agentic workers:** After design approval, use the `executing-plans` workflow and complete the checkboxes in dependency order. Keep implementation in the existing Flutter application. Do not automatically commit, create a worktree, or launch parallel agents.

**Goal:** Entirely redesign the RDMS Ultimate homepage into a modern, calm, accessible document workspace that makes finding, importing, opening, and backing up documents straightforward.

**Architecture:** Retain the existing Flutter/Riverpod presentation architecture, document repository, Drift database, and cloud services. Recompose the document explorer around a shared theme, adaptive shell, focused browsing controls, live document state, and reusable presentation widgets. Limit behavior changes to the homepage interactions needed by this redesign.

**Tech stack:** Flutter Material 3, Dart, flutter_riverpod, Drift/SQLite, existing file_picker, intl, and native file-opening services. No new runtime dependencies, external font requests, web framework, or database migration.

---

## 1. Scope and Working Assumptions

### Homepage definition

The homepage is `DocumentExplorerScreen`, reached after the existing splash screen. It includes the navigation/sidebar, page header, search and filters, document collection, detail panel, import entry point, cloud controls, and status/feedback surfaces.

### Design assumptions

- Preserve the RDMS Ultimate name, existing logo asset, and recognizable sapphire-blue identity.
- Keep user-facing UI copy in Indonesian; this plan and new code comments remain in English.
- Deliver light and dark appearances together, continuing to follow `ThemeMode.system`.
- Treat document browsing as the primary task, not analytics or marketing.
- Preserve offline import, local search, external file opening, individual/bulk Drive uploads, status checks, and separate local/Drive deletion workflows.
- Support adaptive layouts in Flutter without claiming that missing native desktop runners or web storage support are implemented by this work.
- Use the selected direction below as the proposed baseline. User approval is required before coding the redesign.

### Included

- A complete visual and layout replacement of the homepage's current regions.
- Centralized colors, typography, spacing, control styles, icons, and motion rules.
- Cleaner document rows, visible filter state, sorting, and coherent selection/detail behavior.
- Accurate summary counts and cloud status wording based on existing local data.
- Empty, loading, error, missing-file, disconnected, busy, and large-text states.
- Visual alignment of dialogs opened from the homepage, without replacing their service integrations.
- Targeted provider changes to make search, filters, sorting, counts, and selected details consistent.
- Accessibility, widget, provider, and regression verification.

### Excluded

- Backend authentication, roles, organizations, collaboration, or tenant isolation.
- Changes to API contracts, SQLite/PostgreSQL schemas, cloud reconciliation rules, or upload-resume behavior.
- OCR, embedded PDF rendering, automatic previews, file versioning, real-time collaboration, or downloads from Drive.
- New dashboard charts, grid mode, favorites, folders, bulk selection, bulk deletion, or an activity-history feature.
- OS drag-and-drop integration: use truthful file-picker wording until a real drop handler exists.
- A new splash-screen animation, native platform scaffolding, deployment changes, or a web rewrite.
- Promising undo for deletion when the current repository permanently removes local files.

## 2. Current Implementation Evidence

| Area | Current implementation | Redesign response |
| --- | --- | --- |
| Shell | `client/lib/features/document_explorer/presentation/document_explorer_screen.dart` uses a fixed three-pane layout from 1024 logical pixels, including an always-present 380-wide detail panel. | Reserve inline details for genuinely wide layouts and an actual selection. Give the collection usable width first. |
| Header/actions | `document_list_view.dart` owns search, command-palette, and import controls; the mobile scaffold also exposes search/import actions. | Give header, toolbar, and mobile primary action explicit, noncompeting responsibilities. |
| Navigation | `document_sidebar.dart` combines branding, storage configuration, categories, year/status filters, progress, and bulk upload. | Keep categories and utilities in navigation; move filtering and progress next to the collection. |
| Row density | `document_list_view.dart` uses several colored badges, gradients, and 9.5–11-point metadata. | Establish a readable title-first hierarchy, flatter file icons, quieter metadata, and fewer competing accents. |
| Search state | `document_providers.dart` switches to a one-shot search future and bypasses category/year/status filtering when a query is present. | Compose FTS matches with all selected filters and refresh results when local documents change. |
| Search clearing | The search field changes provider state without a controller that clears the visible input. | Keep the field controller and provider query synchronized, including clear/reset actions. |
| Selection | Selection stores a document snapshot; detail freshness depends on individual action handlers. | Resolve the selected ID against the live document source before displaying details. |
| Status | `sync_status_badge.dart` mixes English labels and animated queued/syncing indicators. | Use consistent Indonesian labels and animate active work only. |
| Cloud semantics | `sync_queue_service.dart` marks a Drive upload synced even when backend metadata submission fails. | Describe Drive backup status only; never claim the server or every replica is synchronized. |
| First run | The explorer automatically invokes `DummyDataSeeder.seedIfEmpty`. | Show a real first-run empty state; retain sample loading only as an explicit debug action. |
| Preview | `document_preview_panel.dart` displays metadata and an external-open action, not a PDF renderer. | Call this surface document details and do not promise an embedded preview. |

The visual observations above are source-based. Capture actual before/after screenshots during implementation; no approved visual baseline exists yet.

## 3. Visual Direction: Sapphire Workspace

### Approaches considered

| Direction | Benefit | Trade-off | Decision |
| --- | --- | --- | --- |
| Calm document workspace | Clear hierarchy, professional appearance, efficient repeated use, strong light/dark support. | Less decorative than a showcase dashboard. | **Selected baseline.** |
| Dashboard-first command center | Prominent summaries and quick actions. | Pushes the document collection down and suggests analytics the app does not provide. | Do not use as the homepage structure. |
| Glass/bento showcase | Visually expressive cards and translucent surfaces. | More visual noise, rendering cost, and contrast complexity for a file-management tool. | Do not use. |

### Visual principles

- Use a cool neutral canvas, clean surfaces, thin separators, moderate radii, and sapphire for primary actions and selection.
- Use spacing and typography to group content; avoid wrapping every label in a colored pill.
- Keep the existing logo, without adding a glowing gradient container around it.
- Use Flutter Material outlined/rounded icons consistently. Do not use emoji for navigation or state icons.
- Use subtle elevation for overlays; ordinary rows and summary cards remain flat or outlined.
- Avoid a large welcome hero, invented user avatar, fake organization switcher, decorative charts, and continuous background animation.
- Keep exactly one prominent import CTA in each homepage layout.

### Color tokens

Define these centrally in `client/lib/core/theme/app_theme.dart`. Use `ColorScheme` for standard roles and a `ThemeExtension` named `RdmsStatusColors` for the status foreground/background pairs.

| Role | Light | Dark |
| --- | --- | --- |
| Canvas / scaffold | `#F6F8FC` | `#0B1220` |
| Surface | `#FFFFFF` | `#111C2E` |
| Raised/secondary surface | `#EEF2F8` | `#1A2940` |
| Primary | `#0F52BA` | `#93B8FF` |
| On primary | `#FFFFFF` | `#08234F` |
| Primary container / selection | `#EAF1FF` | `#18335E` |
| On primary container | `#153E75` | `#DCE8FF` |
| Primary text | `#172338` | `#F0F4FC` |
| Secondary text | `#526176` | `#B2BED1` |
| Subtle separator | `#DCE3EE` | `#2B3B53` |
| Interactive outline | `#718096` | `#8191AB` |
| Success foreground / container | `#166534` / `#ECFDF3` | `#86EFAC` / `#123522` |
| Warning foreground / container | `#92400E` / `#FFFBEB` | `#FCD34D` / `#392D12` |
| Error foreground / container | `#B91C1C` / `#FEF2F2` | `#FCA5A5` / `#3D1C25` |
| Information foreground / container | `#1D4ED8` / `#EFF6FF` | `#93C5FD` / `#172F52` |

These are specified implementation colors, not a claim of certified contrast. Verify actual rendered pairs, including hover/disabled/selected states, during final acceptance. Subtle separators must not be the only way to identify an interactive control.

### Typography, dimensions, and motion

- Use Flutter's default Material typography and platform fallbacks; remove the global hard-coded `Segoe UI` override. No network-loaded fonts.
- Map all text through `TextTheme`: page title 28/34, section title 18/26, document title 16/24, body 14/21, supporting label 12/18 logical pixels at scale 1.0.
- Weights: 600–700 for titles, 500 for labels, 400 for normal content. Use tabular figures for counts and file sizes.
- Minimum functional text size is 12; document titles and primary mobile controls use 16.
- Spacing scale: 4, 8, 12, 16, 24, 32, 48. Screen padding: 16 compact, 24 medium, 32 wide.
- Radii: 8 for small chips, 12 for controls/rows, 16 for panels, 24 for sheets/dialogs.
- Controls have at least 48-by-48 logical-pixel hit targets. Row heights are minimums, never fixed heights that clip enlarged text.
- Focus: a clearly visible 2-pixel primary outline, separate from hover and selection treatment.
- Motion tokens: 120 ms feedback, 180 ms selection/content fade, 240 ms overlay transitions; use ease-out entrance and shorter exits.
- Respect `MediaQuery.disableAnimationsOf(context)`. Under reduced motion, show static status icons and immediate state changes; do not use shimmer or decorative scaling.

## 4. Homepage Composition

### A. Navigation/sidebar

- Header: existing logo, `RDMS Ultimate`, and a quiet local-workspace descriptor.
- Primary item: `Semua Dokumen`; below it, document categories with icons and actual category counts.
- Category counts come from the full local collection, not the currently filtered search result.
- Build categories from the existing category constants plus distinct stored categories. Do not merge or rename stored category values.
- Remove fiscal-year and sync-status dropdowns from the sidebar; those belong to the browsing toolbar.
- Bottom utilities: `Pengaturan Cloud` and `Lokasi Penyimpanan`, with the current path available in an expandable section.
- Do not render a green storage-health dot or a storage-capacity meter without measured supporting data.
- On compact/medium layouts use a drawer; close it after a category selection and preserve search/year/status filters.

### B. Workspace header

- Title: `Pusat Dokumen`.
- Subtitle: `Kelola dokumen lokal dan cadangan Google Drive.`
- Large layouts: one primary `Tambah Dokumen` button, a secondary `Unggah Semua` action, and a cloud-settings control.
- Compact layout: drawer trigger, concise title, and cloud-settings icon with tooltip; import moves to a labeled floating action button.
- `Unggah Semua` remains available in compact overflow navigation and explicitly means all eligible local/error documents, independent of current filters.
- Do not add a separate homepage, analytics, or sync-center destination with no implemented screen behind it.

### C. Compact collection summary

Use four noninteractive summary items. They provide context and must not look like filter buttons.

| Label | Exact source |
| --- | --- |
| `Total Dokumen` | Count of all local document records. |
| `Lokal Saja` | Records whose status is `local_only`. |
| `Tersimpan di Drive` | Records whose last known status is `synced`. |
| `Perlu Perhatian` | Records whose status is `error`, `deleted`, or `lost`. |

- These values are not a partition: queued/syncing documents are included in the total, not the other three counts.
- Display the caption `Berdasarkan status lokal terakhir`; do not imply live Drive verification.
- Show loading placeholders until a local snapshot exists; do not temporarily display fabricated zero values.
- Wide: four items in one row when space allows. Medium: two columns. Compact: show the total and an expandable `Ringkasan` section, collapsed by default.
- Derive counts once per source update; do not issue one query per card or navigation item.

### D. Search and filter toolbar

- Search hint: `Cari judul, nomor, atau teks dokumen…` with a persistent accessible label.
- Search occupies a dedicated full-width line on compact layouts; do not squeeze it between three icon buttons.
- Large layouts place search and the command-palette shortcut together; filtering occupies the next line when needed.
- Filters: category, fiscal year, and all seven existing sync statuses. Category shares state with sidebar selection.
- Fiscal-year options are the current year plus all years present in the full collection, unique and descending, with `Semua Tahun` first.
- Show removable chips for active filters and `Reset Filter`. Reset removes category/year/status constraints but preserves the typed query; the search clear button clears both controller and provider query.
- On compact layouts use a `Filter` button with an active-count badge to open an adaptive sheet. Changes apply immediately; `Selesai` closes the sheet.
- Sorting: `Terbaru` by `createdAt` descending (default), `Terlama` by `createdAt` ascending, `Judul A–Z`, and `Tanggal Dokumen` descending. Break ties by document ID for deterministic order.
- Preserve the existing 150 ms typing debounce. Clearing a query is immediate and cancels a pending debounce.
- Match search AND category AND fiscal year AND status. Do not silently drop filters when searching.
- Show the visible result count next to the collection heading; distinguish it from the total summary count.

### E. Document collection

- One list presentation that adapts between aligned desktop rows and stacked compact rows; no new grid/list preference.
- Wide collection columns: document title/number, category, document date, status, and overflow actions.
- A 40-pixel flat/tinted file-type icon anchors each row. Make title the strongest text and keep document number secondary.
- Below 840 pixels of actual collection width, use a stacked row: title and menu first, document number next if present, then wrapping category/date/status metadata.
- Size and fiscal year remain available in details; do not force them into narrow rows.
- Allow two title lines on compact rows. Full title, filename, and number remain selectable/readable in details; tooltips supplement desktop truncation.
- Hover, keyboard focus, pressed state, and selected state are distinct. Selection uses a subtle primary background and leading indicator.
- Use a lazily built list/sliver list with stable document-ID keys. Do not replace it with an eagerly built `DataTable`.
- Keep scroll position when opening/closing details, resizing, checking status, or returning from an external viewer.
- Menu actions retain external open, show in folder, Drive check/rename/delete, and add a visible local-delete alternative to swipe.
- Keep `Open With` absent, matching the current tests and UI. Do not reintroduce it merely because a service method exists.

### F. Document details

- Present an actual selection only; no permanently reserved empty preview pane on the homepage.
- Header: file-type icon, full document title, status, and a clearly labeled close/back action.
- Primary action: `Buka Dokumen`, using the existing external opener.
- Group metadata into `Informasi Dokumen`, `Penyimpanan Lokal`, and `Cadangan Google Drive`.
- Show title, number, category, document date, fiscal year, filename, size, local path, and last-known Drive status. Put checksum/technical identifiers behind `Detail Teknis`.
- Display supplied indexed text when available; label it `Teks Terindeks`, not automatically extracted OCR.
- Keep upload/reupload and Drive management available; clearly separate local deletion from Drive deletion.
- Use an explicit close callback owned by the hosting shell/route. An inline detail panel must never pop the homepage route.
- On every local snapshot, resolve the selected ID to the latest document. If deleted, clear selection and close its details. If a filter excludes it, close its details without altering the remaining filters.

### G. Cloud and operation feedback

- Use a compact status strip near the collection during uploads: completed, failed, total, and current document title when available.
- Label progress as processed items when its numerator is `completed + failed`; never present that value as successful uploads.
- Disable duplicate upload actions while a queue or individual upload is active. Keep browsing/search/import usable.
- An idle, never-connected account shows `Google Drive belum dikonfigurasi`; saved credentials show `Google Drive dikonfigurasi`, not proof that the account or network is healthy.
- Demo mode is labeled `Mode Demo — upload tidak tersedia`. Do not present demo mode as a successful connection or backup.
- An unreachable check preserves last-known document status and explains that verification could not be completed.
- Pull-to-refresh and the desktop refresh control perform the existing Drive-status check. Copy must not imply downloading documents from Drive.
- Import or local search never requires a cloud connection.
- Show actionable messages without exposing tokens or dumping raw exceptions into the main UI.

## 5. Responsive Layout Contract

All dimensions below are logical pixels. Use `LayoutBuilder` constraints rather than operating-system names to select the layout.

| Available shell width | Navigation | Collection | Details | Import action |
| --- | --- | --- | --- | --- |
| 320–599 | Drawer | Stacked rows; expandable summary | Full-screen detail route | Labeled FAB; reserve bottom inset |
| 600–1023 | Drawer | Stacked/aligned rows by collection width | Right-aligned modal, max width 420 | Header button |
| 1024–1439 | 240-wide sidebar | Remaining width; no permanently reserved detail panel | Right-aligned modal, max width 420 | Header button |
| 1440+ | 256-wide sidebar | Flexible collection | 360-wide inline panel only when selected and center remains at least 600 wide | Header button |

Additional rules:

- Detail modals never exceed viewport width minus 32 or viewport height minus 48. Use safe-area insets and scrolling.
- With text scaling above 1.3, use stacked rows and overlay details instead of squeezing three panes. At scale 2.0 and above use full-screen details for readable metadata.
- Collapse the four-item summary when content height is below 600 so controls and documents remain reachable in landscape/keyboard layouts.
- Main content uses one vertical scroll surface for header, summary, and rows; keep search/filter controls available with a pinned toolbar that can grow for wrapped controls. Sidebar and detail content may scroll independently.
- No page-level horizontal scrolling. Make toolbar/chips wrap and adapt row content instead.
- If a window resize changes details from inline to overlay, close inline details but retain the selected ID; do not automatically open a modal during resize. The next activation opens the appropriate presentation. Existing open overlays remain until dismissed, preventing duplicate detail surfaces.
- Preserve search/filter/sort/scroll state across resize and detail navigation. No new restart-persistence requirement is introduced.

## 6. Interaction and Accessibility Contract

### Browsing and keyboard behavior

- Single click/tap selects and opens details in the appropriate presentation; desktop double-click retains external open.
- Use one shell-owned document-activation callback for collection rows and command-palette results. This also makes mobile command-palette selection open usable details.
- The command palette remains a global search. Choosing its result resets the homepage query/category/year/status through the existing full reset before activating that document, so the target is visible; retain the chosen sort. This explicit global navigation is the exception to preserving filters when simply opening/closing details.
- `Ctrl+K` / `Cmd+K`: command palette. `Ctrl+F` / `Cmd+F`: focus homepage search when the homepage is active.
- Arrow keys move among focused document rows; Enter opens details; Shift+F10 opens the focused row's action menu.
- Escape closes the topmost overlay, otherwise closes inline details. It must not silently discard an edited import form.
- Do not process row shortcuts while focus is in a text field, dialog, or editable control.
- When overlays close, restore focus to their invoking control/row; if that row was deleted, focus the collection heading.
- Use Flutter `Shortcuts`, `Actions`, `FocusTraversalGroup`, `Tooltip`, and `Semantics` rather than raw gesture-only controls.

### Status presentation

Keep persisted enum values unchanged. Define presentation labels and icons in the shared document-visuals helper.

| Existing value | Label | Presentation |
| --- | --- | --- |
| `local_only` | `Lokal Saja` | Neutral icon and label; not an error. |
| `queued` | `Dalam Antrean` | Static schedule icon and information colors. |
| `syncing` | `Mengunggah` | Activity indicator only while actually uploading. |
| `synced` | `Tersimpan di Drive` | Success icon and last-known-status explanation. |
| `error` | `Gagal Mengunggah` | Error icon plus separate `Coba Lagi` action. |
| `deleted` | `Dihapus di Drive` | Warning/error icon; does not imply local deletion. |
| `lost` | `Nama Berubah di Drive` | Warning icon; explain the filename mismatch. |

Retry must await the queued-state update and start the existing queue processor; changing only the badge is not a completed retry interaction. When credentials are absent or demo mode is enabled, offer cloud settings first and do not silently start a known-unavailable upload.

### Destructive actions

- Local delete confirmation explicitly states that the local record/file is removed and the Drive copy is unaffected.
- Drive delete/trash confirmation explicitly states that it affects Drive and does not delete the local copy.
- Preserve mobile end-to-start swipe-to-delete with confirmation. Add the same local-delete action to the overflow menu for keyboard/desktop access.
- Do not dismiss a row or announce success until the repository operation completes. On a reported error, retain the row and provide retry feedback.
- Never claim secure erasure or successful physical-file removal beyond the existing repository's returned outcome.

### Accessibility requirements

- Text contrast at least 4.5:1 for ordinary text, 3:1 for large text; visible control/focus boundaries at least 3:1 where required.
- All actionable icons have labels/tooltips and keyboard access. Status uses text plus icons, not color alone.
- Support 200% text scaling without clipped actions, hidden information, or horizontal overflow.
- Announce import, upload completion/failure, and deletion outcome through a polite semantic live region; do not announce every progress tick.
- Use standard Material buttons/menu controls with disabled semantics for unavailable actions.
- Respect screen-reader order, system back gestures, keyboard insets, and safe areas.

## 7. State and Data Design

### Provider responsibilities

Keep these definitions in `client/lib/features/documents/presentation/providers/document_providers.dart`:

| Provider/type | Responsibility |
| --- | --- |
| Existing `documentFilterProvider` | Category, fiscal year, exact sync status, and debounced search query. Add an explicit filter-only reset while retaining full reset for callers that need it. |
| New `DocumentSort` enum / `documentSortProvider` | `newest`, `oldest`, `titleAscending`, `documentDateDescending`; default `newest`. |
| New `allDocumentsStreamProvider` | One unfiltered `repository.watchDocuments()` source for summary, categories, selection resolution, and browsing invalidation. |
| Existing `documentsListStreamProvider` | Derive visible documents from the current source snapshot, FTS match IDs, filters, and selected sort. Keep the public StreamProvider shape for existing consumers/tests. |
| New `DocumentSummary` / `documentSummaryProvider` | Total, local-only, last-known-synced, and attention counts from the full collection; preserve loading/error states. |
| Existing `selectedDocumentProvider` | Retain its selection API so existing callers/tests continue working; use the selected ID as identity, not its stale snapshot for display. |
| New `selectedDocumentDetailsProvider` | Resolve the selected ID from the current full collection; return the latest record or null. |
| New `homeOperationProvider` | Presentation-only guard for active document upload IDs, starting/running bulk upload, and active refresh. Clear guards in `finally`. |
| New `cloudConfigurationProvider` | Load demo/token-presence configuration through existing services; expose loading, unconfigured, configured, or demo, without exposing the token to widgets. |

### Visible-document derivation

1. Subscribe to the unfiltered source and preserve its loading/error semantics.
2. On a query, filter, sort, or source-data change, recompute the visible result. Only nonempty queries call `repository.searchDocuments(query)`.
3. Build a set of FTS match IDs and intersect it with the newest source snapshot. Without a query, every source ID is eligible.
4. Apply category, year, and exact status as AND predicates, then apply the selected deterministic sort.
5. Discard obsolete asynchronous results when a newer query/source snapshot is active; use provider invalidation/disposal plus a request generation guard if asynchronous work lives in a notifier.
6. Keep previous valid content during an in-place refresh, with an inline loading indicator. Initial loading shows placeholders; first-load failure shows recovery UI.
7. Do not write provider state or create network requests inside widget `build` methods.

No repository interface change is needed: use existing `watchDocuments`, `searchDocuments`, and action methods. No generated Drift code should change.

### Presentation-only operation orchestration

- Move upload/refresh initiation used by rows, details, header, and palette behind the same homepage action handling and operation guards.
- Reuse `syncSingleDocument`, `processQueue`, `reconcileAllDocuments`, and existing Drive dialogs; do not duplicate their HTTP or persistence logic in widgets.
- After cloud settings/sign-in/sign-out return, invalidate `cloudConfigurationProvider` so the header and upload gates agree.
- Treat demo mode independently from `TokenStorageService.isConfigured`, since that method also returns true for demo mode.
- Local summary counts and document viewing do not trigger live Drive requests.

## 8. Empty, Loading, Error, and Boundary States

| State | Required UI | Recovery/action |
| --- | --- | --- |
| First run, no records | Quiet document illustration/icon, `Belum ada dokumen`, explanation that imports stay local. | Primary `Tambah Dokumen`; no automatic sample insertion. |
| Query has no matches | `Dokumen tidak ditemukan` plus the current query and active filters. | Clear query or reset filters independently. |
| Filter-only empty result | `Tidak ada dokumen untuk filter ini`. | `Reset Filter`; preserve the search field. |
| Initial local loading | Six static row placeholders; unavailable summary values remain placeholders. | Keep header and import entry point visible. |
| Local read/search failure | Friendly message and `Coba Lagi`; no full stack trace in the layout. | Retry invalidates the relevant local/result provider without cloud reconciliation. |
| Cloud unconfigured | Neutral configuration notice, not a full-page error. | Open existing cloud settings; continue local work. |
| Drive unreachable | Nonblocking warning, with last-known statuses retained. | Explicit status-check retry. |
| Active upload | Progress strip and disabled duplicate upload actions. | Continue browsing/search/import; no unsupported cancel button. |
| One or more failed uploads | Separate successful/failed counts and affected-document state. | Retry eligible failed items; never announce an all-success result. |
| Local file missing | Clear opener warning; details retain metadata. | Show known path; do not invent a working redownload/locate capability. |
| Very long title/path/number | Wrapping where useful, tooltip on truncated desktop text, full value in details. | Read/copy full metadata without shrinking text. |
| Dialog with dirty import fields | Do not silently discard on close/back/outside tap. | Confirm discard or keep editing; retain existing import validation. |

## 9. File-Level Implementation Map

All paths are relative to the repository root. New files below are proposed for the later implementation, not created by this planning task.

### Shared theme and shell

| Action | Path | Responsibility |
| --- | --- | --- |
| Create | `client/lib/core/theme/app_theme.dart` | Light/dark theme factories, spacing/radius/motion constants, status-color extension, shared Material component themes. |
| Modify | `client/lib/main.dart` | Consume shared theme; preserve app initialization, title, system theme mode, and splash navigation. |
| Create | `client/lib/features/document_explorer/presentation/home_layout.dart` | Pure layout policy for widths, text scaling, inline details, and compact presentation. |
| Modify | `client/lib/features/document_explorer/presentation/document_explorer_screen.dart` | Adaptive shell, action orchestration, shortcuts, detail hosting, and removal of automatic demo seeding. |
| Create | `client/lib/features/document_explorer/presentation/widgets/home_header.dart` | Workspace title, primary action, cloud control, compact overflow. |
| Create | `client/lib/features/document_explorer/presentation/widgets/home_summary.dart` | Responsive summary presentation; accepts provider-derived counts/loading state. |
| Create | `client/lib/features/document_explorer/presentation/widgets/home_status_bar.dart` | Honest operation/progress/configuration presentation without direct networking. |

### Document presentation and dialogs

| Action | Path | Responsibility |
| --- | --- | --- |
| Modify | `client/lib/features/documents/presentation/providers/document_providers.dart` | Composed filtering/sorting, summary and live selection, configuration state, operation guards. |
| Modify | `client/lib/features/documents/presentation/widgets/document_sidebar.dart` | Category navigation, shared category counts, storage/cloud utilities; remove duplicate progress/filter controls. |
| Create | `client/lib/features/documents/presentation/widgets/document_toolbar.dart` | Controlled search input, filter chips/sheet, sort selector, result count, keyboard focus target. |
| Modify | `client/lib/features/documents/presentation/widgets/document_list_view.dart` | Collection/sliver composition, lazy rows, empty/error/loading state, explicit activation callbacks. |
| Create | `client/lib/features/documents/presentation/widgets/document_list_item.dart` | Extract existing private row into an adaptive, focusable component; retain actions and confirmation behavior. |
| Create | `client/lib/features/documents/presentation/widgets/document_visuals.dart` | Shared file/category icons, status presentation labels, and metadata formatting. |
| Modify | `client/lib/features/documents/presentation/widgets/document_preview_panel.dart` | Grouped live details and explicit host-controlled close/action callbacks; retain class name to limit churn. |
| Modify | `client/lib/features/documents/presentation/widgets/sync_status_badge.dart` | Token-based, accessible, text-plus-icon states; no spinning queued badge. |
| Modify | `client/lib/features/command_palette/presentation/command_palette_modal.dart` | Shared theme, keyboard handling, shell-owned result activation; preserve existing search prefixes and commands. |
| Modify | `client/lib/features/documents/presentation/widgets/add_document_modal.dart` | Shared form styles, adaptive dimensions, truthful picker wording, dirty-form dismissal protection. |
| Modify | `client/lib/features/documents/presentation/widgets/cloud_sync_settings_modal.dart` | Shared styles, clear configured/demo wording, advanced configuration grouping, configuration invalidation callback. |
| Modify | `client/lib/features/documents/presentation/widgets/drive_file_action_dialogs.dart` | Consistent confirmation typography, danger treatment, safe areas, and clear local-versus-Drive copy. |
| Modify | `client/lib/core/widgets/custom_toast.dart` | Shared tokens, readable messages, accessible live-region announcements without stealing focus. |

### Tests

- Modify `client/test/widget_test.dart`: shell layouts, first-run behavior, shared themes; keep splash regression coverage.
- Modify `client/test/document_overflow_and_open_with_test.dart`: row layouts, menus, detail hosting, confirmations, and enlarged text.
- Modify `client/test/add_document_modal_test.dart`: refreshed form/picker copy and dirty-close behavior.
- Create `client/test/document_home_state_test.dart`: provider filtering, sorting, reactive updates, counts, selection resolution, and operation guards.
- Create `client/test/homepage_redesign_test.dart`: breakpoint boundaries, search/reset UX, keyboard/focus, status/empty/error states, and semantic checks.
- Keep storage/database, seeder, and sync-queue suites as unchanged regression coverage unless a test fixture must adapt to the presentation API.

## 10. Implementation Sequence

### Phase A — Establish the visual foundation

**Depends on:** User approval of this plan.

- [ ] Capture the existing homepage in light/dark at 390, 1280, and 1440 widths, including one selected document.
- [ ] Add `app_theme.dart` with the exact semantic token roles and shared Material component themes specified above.
- [ ] Move homepage colors/text styles to the theme and remove the global forced font family from `main.dart`.
- [ ] Add `document_visuals.dart` and make file/category/status presentation use it consistently.
- [ ] Prepare theme contrast and status-label assertions for the final test batch.

**Exit condition:** One shared source controls the homepage's visual system; no dependency/schema changes are required.

### Phase B — Make homepage state coherent

**Depends on:** Phase A.

- [ ] Add the unfiltered document source, summary, sort, selected-details, configuration, and operation providers from Section 7.
- [ ] Implement FTS-ID intersection plus AND filtering and stable sorting; preserve previous content during refresh.
- [ ] Make clear/reset actions synchronize the visible search controller and provider state correctly.
- [ ] Resolve selected details from live records and close deleted/filtered-out selections through shell-owned behavior.
- [ ] Centralize guarded upload/refresh actions and ensure retry actually starts processing.
- [ ] Prepare provider tests for all search/filter/sort combinations and stale asynchronous results before moving to presentation composition.

**Exit condition:** Summary, visible documents, badges, and selected details describe the same local data snapshot.

### Phase C — Replace the adaptive homepage shell

**Depends on:** Phases A–B.

- [ ] Implement the layout policy and all width/text-scale rules from Section 5 in `home_layout.dart`.
- [ ] Recompose the explorer with the new header, summary, collection toolbar, and status strip.
- [ ] Simplify the sidebar to categories and utilities; move year/status filtering into the toolbar/sheet.
- [ ] Establish a single scrollable main surface, safe-area handling, and one import CTA per layout.
- [ ] Remove automatic seeding from homepage initialization; retain an explicit sample-data command only under `kDebugMode`.
- [ ] Add shell-owned detail activation/close callbacks and use them for both rows and palette results.

**Exit condition:** Wide and compact layouts are intentionally different, with no permanently empty detail pane or duplicate primary action.

### Phase D — Rebuild browsing and details

**Depends on:** Phase C.

- [ ] Extract and restyle document rows using the title-first hierarchy and actual collection-width thresholds.
- [ ] Add search/filter/sort controls, result count, and distinct empty-result states.
- [ ] Add accessible row focus, selection, menu, external-open, and local-delete affordances.
- [ ] Reorganize the details surface into the defined sections, keeping all existing useful metadata/actions.
- [ ] Preserve scroll state through details navigation, refresh, and resizing; prevent duplicate modal/inline detail surfaces.
- [ ] Replace queued spinners and mixed status labels with the new presentation contract.

**Exit condition:** A user can find a document, inspect its complete metadata, open it externally, and return without losing their browsing context.

### Phase E — Align feedback and connected dialogs

**Depends on:** Phase D.

- [ ] Implement the state matrix and accurate cloud configuration/last-known-status language.
- [ ] Update import, cloud settings, Drive action dialogs, and command palette to shared theme/spacing/focus rules.
- [ ] Replace drag-and-drop claims with picker wording; preserve actual file-picker behavior.
- [ ] Add dirty-form close protection and distinguish local versus cloud destructive actions.
- [ ] Apply operation guards to every homepage upload entry point, including keyboard/palette paths.
- [ ] Add reduced-motion handling and semantic announcements to status/feedback components.

**Exit condition:** Every visible control has a working behavior or an explicit disabled explanation, and messaging does not overstate cloud/server guarantees.

### Phase F — Batch verification and visual acceptance

**Depends on:** Phases A–E.

- [ ] Complete the test cases in Section 11 and update existing tests to the agreed UI contract without weakening service regressions.
- [ ] Format touched Dart files and run static analysis once the implementation batch is assembled.
- [ ] Run the complete Flutter test suite once at the end of the batch, per the existing project preference. Do not run it after every small edit; occasional static analysis during implementation is acceptable.
- [ ] Check screenshots in both themes at all representative widths and selected boundary cases.
- [ ] Manually exercise keyboard navigation, system back, text scaling, import, external open, and mocked/local cloud failure states.
- [ ] Record which platform and integration checks were actually performed; do not imply native/Drive verification from widget tests.

**Exit condition:** Acceptance criteria pass, regressions are resolved, and the user receives a concise summary of changed files and verified behavior. Commit only if explicitly requested.

## 11. Verification Matrix

### Automated scenarios

| Area | Required cases and expected outcome |
| --- | --- |
| Layout policy | Widths 320, 390, 599, 600, 1023, 1024, 1280, 1439, 1440, 1920; sidebar/details mode follows the contract. |
| Small screens | 320x640 and 390x844: no RenderFlex overflow, primary action reachable, no page-level horizontal scrolling. |
| Large text | 390x844 and 1280x800 at 1.0, 1.3, and 2.0 text scaling; controls remain readable and details fall back appropriately. |
| Theme | Light/dark status pairs, selected rows, disabled actions, focus outline, and summary/error surfaces use semantic tokens. |
| Search clearing | Type a query, clear it, wait beyond debounce; both displayed text and provider query stay empty. |
| Composed filters | Search + category + fiscal year + status returns only the intersection; clearing one constraint preserves the rest. |
| Reactive search | Import/update/delete and status changes refresh results while a query is active; an older delayed search must not replace newer results. |
| Sort | All four sorts, equal titles/dates, null document number, and stable ID tie-breaks produce deterministic results. |
| Summary | Counts use the full source, not search results; queued/syncing do not inflate success; failed/deleted/lost contribute to attention. |
| Selection | Update selected record: details refresh. Delete/filter it out: details close. Dismissing inline details never pops the homepage. |
| Palette | Existing `nama:`, `tahun:`, `kategori:`, and command modes remain usable; selecting a result resets homepage query/filters, preserves sort, and opens details on compact screens. |
| Empty states | Empty database triggers no seed/import writes; unmatched query and filter-only empty results show the correct independent reset actions. |
| Errors | Local read failure offers local retry; unreachable Drive checks preserve local content and do not announce verified synchronization. |
| Busy operations | Repeated upload/retry taps result in one active operation; guards clear on success/failure; retry queues and invokes processing. |
| Cloud configuration | No credentials, saved credentials, and demo mode render distinct truthful states; settings return refreshes the header/gates. |
| Deletion | Cancel keeps the document; confirmed local/Drive actions call their respective existing handlers; failure feedback does not claim success. |
| Keyboard | Palette/search shortcuts, row arrows/Enter/menu, Escape, focus restoration, and exclusion of shortcuts from editable fields. |
| Semantics | Action labels, selected state, status text, 48-pixel hit targets, and polite operation announcements are present. |
| Motion | Reduced-motion settings disable custom transitions/queued animations; active status remains understandable. |

Use deterministic document fixtures, in-memory Drift where storage-backed behavior is required, and provider/service overrides. Widget tests must not invoke real Google sign-in, upload to Drive, open external applications, or write to the user's real document directory. Use bounded `pump` durations for active progress tests rather than waiting indefinitely for animations to settle.

### Final commands

Execute from the `client` directory after the implementation batch. Format the touched presentation areas and the specific UI/state test files; do not reformat the unchanged storage/sync test suites:

```powershell
dart format lib/main.dart lib/core/theme lib/core/widgets lib/features/document_explorer lib/features/documents/presentation lib/features/command_palette
dart format test/widget_test.dart test/document_overflow_and_open_with_test.dart test/add_document_modal_test.dart test/document_home_state_test.dart test/homepage_redesign_test.dart
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

Expected: formatting completes, analysis reports no issues, and the full existing-plus-new test suite passes. These are future implementation checks; no application test run is required just to add this Markdown plan.

### Visual/manual acceptance

- [ ] Capture light/dark homepage screenshots at 390x844, 768x1024, 1280x800, and 1440x900.
- [ ] Capture selected details, active filters, no results, uploading, and failure states; include one 200% text-scale screenshot.
- [ ] Confirm that the first document remains easy to reach without a large decorative header or oversized summary section.
- [ ] Verify imported files, local search, external open, category/year/status filtering, and local-delete confirmation with disposable test documents.
- [ ] Confirm all modified dialogs fit with the onscreen keyboard and system navigation areas.
- [ ] Do not perform destructive tests against real user Drive files. Use mocks unless a disposable integration account/document is explicitly authorized.
- [ ] Treat desktop-widget layouts as layout validation, not proof of a supported Windows/macOS production build.

## 12. Definition of Done

- [ ] Every homepage region follows the Sapphire Workspace visual system in both themes.
- [ ] Import, browse, search, filter, sort, inspect, open, upload, retry, and delete remain discoverable and functional.
- [ ] Search, filters, summary counts, and selected details agree with current local data.
- [ ] The homepage remains useful without a network connection or Google credentials.
- [ ] Cloud labels distinguish configured credentials, last-known Drive backup state, active work, and verification failures.
- [ ] No new backend/domain capability is implied by decorative UI, misleading copy, or fabricated metrics.
- [ ] No clipped essential content at the specified widths or text scales; keyboard and screen-reader paths are supported.
- [ ] No database schema, generated Drift file, backend endpoint, runtime dependency, or user document is changed solely for visual styling.
- [ ] All automated and manual checks actually performed are reported accurately; untested integrations are identified.
- [ ] This plan is approved before any UI implementation starts.
