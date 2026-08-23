# TaskFlow — Flutter Project Management Mobile Application

TaskFlow is a project management mobile application built with Flutter using Clean Architecture, Riverpod state management, JWT session authentication with token refresh, role-based authorization, offline caching, and automated unit/widget testing.

---

## Technical Overview & Architecture Highlights

- **Framework**: Flutter (Dart 3.x)
- **Architecture**: Clean Layered Architecture (`core`, `data`, `domain`, `presentation`)
- **State Management**: Riverpod (`StateNotifier`, `NotifierProvider`, `AsyncValue`, `FutureProvider`)
- **Navigation**: `go_router` with redirection guards for authentication & role checking
- **Data Layer**: Centralized repository layer (`TaskFlowMockDataSource`) with local cache persistence (`SharedPreferences`).
- **JWT Authentication**: Token storage in `FlutterSecureStorage`, automatic token refresh handling prior to expiration, and session restoration on app launch.
- **Role-Based Authorization**: Non-admin users are strictly blocked at the domain/repository layer from performing admin actions (e.g. deleting projects).
- **Cross-Org Safety**: Business-logic validation prevents assigning users to tasks outside their active organization.

---

## Demo Accounts & Test Credentials

| Organization | Role | Email | Password | Allowed Actions |
|---|---|---|---|---|
| **Org A (Acme Corp)** | `org_admin` | `alex@acme.com` | `password123` | Full access, create/edit/delete projects & tasks, assign members |
| **Org A (Acme Corp)** | `member` | `sarah@acme.com` | `password123` | View projects/tasks, create/edit tasks, cannot delete projects |
| **Org B (Stark Industries)** | `org_admin` | `bruce@stark.com` | `password123` | Full admin access for Org B |
| **Org B (Stark Industries)** | `member` | `peter@stark.com` | `password123` | Standard member access for Org B |

> **Quick Credentials Picker**: On the Login screen, tap **"Select Test Credentials"** to auto-fill any of these accounts with 1 click.

---

## Features Implemented

1. **Authentication**:
   - Login, Register, Splash / Session Check screens.
   - Secure token storage using `FlutterSecureStorage`.
   - Access token expiry simulation (15 mins) with automatic background token refresh flow.
   - Logout clears local session state.
2. **Projects Management**:
   - Project List & Project Details (task summary counts grouped by status: To Do, In Progress, In Review, Completed).
   - Create / Edit / Delete project with confirmation dialog.
   - Restricted project deletion to `org_admin` enforced in domain layer.
3. **Tasks Management**:
   - Task List with multi-select filters: Project, Status, Priority, Assignee.
   - Task detail screen, inline status popover, comments thread.
   - Task assignment modal restricted to org members with business-logic validation check.
4. **Notifications Inbox**:
   - Lists task assignment events. Tapping a notification navigates directly to the target task detail.
5. **UI/UX Excellence**:
   - Slate dark & light theme modes, custom typography, status badges, priority chips, skeleton loaders, empty/error state views with retry buttons.

---

## How to Run & Test the Application

### 1. Prerequisites
- Flutter SDK (3.12.0 or higher)
- Dart SDK (3.0.0 or higher)

### 2. Required Terminal Commands

```bash
# Get dependencies
flutter pub get

# Run unit & widget tests
flutter test

# Run application on simulator/device
flutter run

# Build production release APK
flutter build apk --release
```

---

## Technical Decisions & Architectural Trade-offs

1. **Riverpod vs Bloc**: Riverpod was chosen for its lightweight boilerplate, compile-time safety, and first-class support for `AsyncValue` (which cleanly encapsulates initial, loading, data, and error states).
2. **Data Source & Persistence**: Data operations sync into `SharedPreferences` on state mutations. This guarantees that user modifications persist across hot reloads and app restarts while keeping the repository interface 100% agnostic to data sources.
3. **Repository Interface Abstraction**: All UI screens interact exclusively with domain repository interfaces (`AuthRepository`, `ProjectRepository`, `TaskRepository`). If swapped for HTTP/REST endpoints in the future, zero UI widget code would need to change.

---

## Repository Folder Structure

```
lib/
├── core/
│   ├── errors/           # Custom exception & failure classes
│   ├── network/          # DebugOptionsManager
│   ├── router/           # GoRouter setup with auth & role guards
│   ├── storage/          # SecureStorageService & LocalStorageService
│   └── theme/            # AppColors, ThemeData (Dark/Light), Glassmorphism styles
├── data/
│   ├── datasources/      # TaskFlowMockDataSource (Reads TaskFlow-MockData.json asset)
│   ├── models/           # Data models with JSON serialization
│   └── repositories/     # Repository implementations (Auth, Project, Task, User, Notification)
├── domain/
│   ├── entities/         # Pure domain entities (Organization, User, Task, Project, etc.)
│   ├── repositories/     # Abstract repository interfaces
│   └── usecases/         # Domain use cases and validation
└── presentation/
    ├── providers/        # Riverpod Providers & StateNotifiers
    ├── screens/          # Splash, Login, Register, Dashboard, Projects, Tasks, Notifications, Settings
    └── widgets/          # Reusable UI widgets (StatusBadge, PriorityChip, UserAvatar, OfflineBanner, etc.)
```
