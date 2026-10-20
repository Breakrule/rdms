# RDMS Ultimate

> **Records & Document Management System** — An offline-first, local-first enterprise document workspace with optional Google Drive cloud sync and a Node.js/PostgreSQL metadata backend.

---

## 🏛️ Overview

**RDMS Ultimate** is engineered for reliable, offline-first document organization, indexing, and synchronization. Built primarily for office and government records workflows (such as *Surat Keputusan (SK)*, *Laporan*, *Notula*, *Teknis*, and *Peraturan*), it ensures that all file operations, searches, and metadata entries happen immediately on the local device without network latency or dependency.

When connected, the client seamlessly reconciles with a personal **Google Drive** storage account for binary backups and an optional **PostgreSQL/Node.js** metadata server.

```
+-------------------------------------------------------------------------+
|                        FLUTTER CLIENT (DESKTOP & MOBILE)                |
|                                                                         |
|  +--------------------+   +-----------------------+   +---------------+ |
|  | Modern 3-Pane UI   |   | Drift ORM + SQLite    |   | Local Storage | |
|  | - Dark/Light Theme |<->| - Metadata Tables     |<->| Manager       | |
|  | - Command Palette  |   | - FTS5 Virtual Search |   | (Custom Path) | |
|  +--------------------+   +-----------------------+   +---------------+ |
|                                       ^                       ^         |
+---------------------------------------|-----------------------|---------+
                                        | Sync Queue            | Resumable
                                        v Worker                | Upload
                 +----------------------+--------------------+  |
                 |                                           |  |
                 v                                           v  v
+----------------------------------+     +-------------------------------+
|         BACKEND NODE.JS          |     |     GOOGLE DRIVE API (v3)     |
| - Express / TypeScript           |     | - Direct client upload via    |
| - PostgreSQL (Metadata & FTS)    |     |   OAuth 2.0 PKCE              |
| - Sync Reconciliation Engine     |     | - Resumable Upload Protocol   |
+----------------------------------+     +-------------------------------+
```

---

## ✨ Key Features

* **Offline-First & Local Storage:**
  * Files are stored in a managed local directory with SHA-256 hash validation and MIME inspection.
  * Local database powered by **Drift (SQLite)** with built-in **FTS5** (Full-Text Search) for sub-16ms search indexing.
* **Intelligent Cloud Synchronization:**
  * Direct client-to-cloud upload via Google Drive v3 Resumable Upload API.
  * Outbox retry queue with auto-resume across app restarts.
  * Sync Center dashboard monitoring active sync workers and replica rollups.
* **Modern & Adaptive UI:**
  * Responsive 3-pane layout for desktop/tablet and bottom-sheet drawer for compact mobile screens.
  * System-reactive Light and Dark themes with animated theme switching.
  * Quick-access Command Palette (`Ctrl/Cmd + K`) for instant multi-token filtering (`tahun:`, `kategori:`, `status:`).
* **Document Productivity & Tools:**
  * Tags, Collections, and Saved Filter Views.
  * Bulk import and formula-safe UTF-8 CSV register exports.
  * Built-in PDF reader (`flutter_pdfview`) and image viewer with rotate/zoom.
  * Local Recycle Bin (Trash) with one-click restore and full library backup/integrity checks.

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Client** | Flutter (Dart 3.x), Material 3, Riverpod 3, Drift (SQLite + FTS5), Dio, Google Sign-In, Flutter Secure Storage, File Picker |
| **Server** | Node.js (LTS), Express, TypeScript, Zod, `pg` (PostgreSQL client), `jose` (JWT/OIDC) |
| **Database** | PostgreSQL 16 (Server metadata index), SQLite 3 (Client local cache) |
| **Identity & Auth**| Keycloak OIDC (optional backend enforcement, `REQUIRE_AUTH=false` default in development) |
| **Deployment** | Docker Compose v2 (`compose.yaml`) |

---

## 📂 Repository Structure

```text
.
├── client/                     # Flutter multiplatform application
│   ├── assets/                 # App icons and graphics
│   ├── lib/
│   │   ├── core/               # Database (Drift), theme, services, utils
│   │   └── features/           # Feature slices (explorer, recovery, sync_center, etc.)
│   └── test/                   # Comprehensive widget and unit tests (119 tests)
│
├── server/                     # Node.js TypeScript metadata server
│   ├── src/                    # API routes, modules (auth, documents, sync), database migrations
│   └── Dockerfile              # Production container build
│
├── keycloak/                   # Keycloak realm configuration for OIDC auth
│   └── realm-import/
│
├── docs/                       # Project documentation & architectural plans
│   ├── ROADMAP.md              # Unified phase status & complete technical roadmap (Phases 0–9)
│   └── UI_DESIGN.md            # Comprehensive UI/UX redesign specification
│
├── compose.yaml                # Docker Compose stack (PostgreSQL + Keycloak + Node API)
├── PRIVACY_POLICY.md           # Google Drive OAuth privacy disclosure
└── README.md                   # Project overview & quickstart (this file)
```

---

## 🚀 Quickstart Guide

### 1. Client (Flutter)

Ensure you have [Flutter SDK](https://flutter.dev) (v3.24+ / Dart 3.5+) installed.

```bash
cd client

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit and widget test suite
flutter test

# Launch the app
flutter run
```

### 2. Server (Node.js & PostgreSQL)

Ensure you have [Node.js](https://nodejs.org) (v20+) and [Docker](https://www.docker.com) installed.

```bash
# Start PostgreSQL & Keycloak services
docker compose up -d postgres keycloak

cd server

# Install dependencies
npm install

# Run TypeScript compile check
npx --no-install tsc --noEmit

# Run unit tests
npm run test:ts

# Start the development server
npm run dev
```

The metadata API will be accessible at `http://127.0.0.1:4000/api/v1`.

---

## 📖 Documentation

* [Roadmap & Phase Specifications](docs/ROADMAP.md) — Detailed feature roadmap (Phases 0 through 9), completion matrix, and architectural conventions.
* [UI/UX Design Specification](docs/UI_DESIGN.md) — Visual styling, layout breakpoints, design tokens, and state machines.
* [Privacy Policy](PRIVACY_POLICY.md) — Google Drive API data access and privacy disclosures.

---

## 📄 License

This project is licensed under the MIT License.
