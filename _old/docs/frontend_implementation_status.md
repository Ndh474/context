# FUACS - Frontend Web Application Implementation Status

**Project Name**: frontend-web  
**Last Updated**: 2025-10-07T13:45:00Z  
**Description**: FUACS - Frontend Web Application Implementation Manifest. This document reflects the exact state of the implemented codebase, not a project plan.

**Platforms**: web_lecturer, web_admin_portal  

---

## Technology Stack

### Framework

- **Name**: Next.js
- **Version**: 15.5.4

### UI Framework

- **Name**: React
- **Version**: 19.1.0

### Styling

- **Primary**: Tailwind CSS
- **UI Library**: shadcn/ui
- **Icon Library**: Lucide React
- **Theme System**: next-themes
- **Utility Classes**: clsx, tailwind-merge

### State Management

- **Server State**: @tanstack/react-query
- **Client State**: zustand
- **Form Validation**: zod
- **Form Handling**: react-hook-form

### HTTP Client

- **Library**: axios

### Authentication Libraries

- **OAuth**: @react-oauth/google
- **Notes**: Google Identity Services used via @react-oauth/google with client ID sourced from NEXT_PUBLIC_GOOGLE_CLIENT_ID.

### UI Component Libraries

- **Notifications**: sonner

### Type System

- **Language**: TypeScript
- **Validation**: zod

---

## Architecture Patterns

### Data Flow Architecture

**Description**: Three-layer data flow with type-safe validation at the boundaries.

**Layers**:

1. **Data Contract Layer (Validation)**
   - **Files**: lib/zod-schemas.ts
   - **Responsibility**: Defines data contracts and validation rules using Zod schemas.

2. **Type Definition Layer (Typing)**
   - **Files**: types/index.ts
   - **Responsibility**: Derives static TypeScript types from Zod schemas for full type safety.

3. **Transport Layer (API Comms)**
   - **Files**: lib/api-axios.ts, lib/auth.ts
   - **Responsibility**: Handles API communication, authentication, and error handling.

### Component Architecture

**Description**: Provider-based architecture for wrapping the application with global context.

**Providers**:

- **AppProviders**
  - **File**: components/providers/app-providers.tsx
  - **Responsibility**: Root provider that composes GoogleOAuthProvider (when client ID is set), ThemeProvider, and QueryProvider.

- **ThemeProvider**
  - **File**: components/providers/theme-provider.tsx
  - **Responsibility**: Manages theme (light/dark/system).

- **QueryProvider**
  - **File**: components/providers/query-provider.tsx
  - **Responsibility**: Configures React Query client and devtools.

---

## Data Models

### Implemented Entities

#### Semester

- **DB Table**: semesters
- **Related Business Rules**: BR-12
- **Related Files**:
  - Schema Definition: lib/zod-schemas.ts
  - Type Definitions: types/index.ts
  - API Endpoints: lib/constants.ts
  - Query Keys: lib/constants.ts
  - React Query Hooks: hooks/api/useSemesters.ts
- **Operations**: CRUD, Validation, Type Safety

---

## API Integration

### Authentication Configuration

- **Method**: JWT Bearer Token
- **Storage**: localStorage
- **Auto Redirect on 401**: conditional
- **Redirect Target**: /login
- **Providers**: Username/password form, Google Identity Services (OAuth)
- **Keys**:
  - Access: fuacs-auth-token
  - Refresh: fuacs-refresh-token
  - User: fuacs-auth-user
- **Auto Redirect Notes**: 401 responses from authenticated API calls clear the session and route to /login; login failures keep the user on the form; Google login exchanges the Google ID token for FUACS JWT and mirrors inactive/not-found error handling.

### Caching Strategy

- **Library**: @tanstack/react-query
- **Stale Time**: 5 minutes
- **Cache Invalidation**: Automatic on mutations via queryClient.invalidateQueries

---

## UI Components

### Base Components

- **Button** (components/ui/button.tsx): Primary action button primitive
- **DropdownMenu** (components/ui/dropdown-menu.tsx): Menu trigger for theme toggle
- **Input** (components/ui/input.tsx): Text input field used across forms
- **Form** (components/ui/form.tsx): React Hook Form bindings and field primitives
- **Label** (components/ui/label.tsx): Accessible form labels
- **Card** (components/ui/card.tsx): Container for auth layouts
- **Separator** (components/ui/separator.tsx): Divider used in auth forms
- **Sonner** (components/ui/sonner.tsx): Toast notifications

### Custom Components

#### ModeToggle

- **File**: components/mode-toggle.tsx
- **Dependencies**: Button, DropdownMenu
- **Purpose**: Theme switching (light/dark/system)

#### LoginForm

- **File**: components/auth/login-form.tsx
- **Dependencies**: useLogin hook, Form, Input, Button, Separator, Label
- **Purpose**: Username/password form with validation and Google CTA

---

## Feature Status

### FEAT-UI-INFRASTRUCTURE - UI Infrastructure and Theming

**Status**:

- Overall: implemented
- Data Layer: implemented
- UI Layer: implemented

**Use Case IDs**: None

**Related Files**:

- app/layout.tsx: Root layout with providers
- components/providers/app-providers.tsx: Root provider composition
- components/providers/theme-provider.tsx: Theme provider
- components/providers/query-provider.tsx: React Query provider
- components/mode-toggle.tsx: Theme switching component
- lib/utils.ts: Styling utility (cn function)

**AI Notes**: The core infrastructure for UI rendering, theming, and state management is fully operational.

### FEAT-USER-AUTHENTICATION - User Authentication System

**Status**:

- Overall: implemented
- Data Layer: implemented
- UI Layer: implemented

**Use Case IDs**: UC-01, UC-02, UC-04, UC-05, UC-06

**Related Files**:

- lib/api-axios.ts: JWT authentication interceptors with conditional redirect
- lib/auth.ts: Token management utilities (access, refresh, user cache)
- lib/constants.ts: Authentication constants and API endpoints
- hooks/api/useAuth.ts: React Query mutations for login/refresh/logout/Google login with aligned error handling
- components/auth/login-form.tsx: Login form UI, validation, and Google Identity button integration
- app/login/page.tsx: Login screen layout
- app/forgot-password/page.tsx: Forgot password placeholder screen
- components/providers/app-providers.tsx: Wraps GoogleOAuthProvider, ThemeProvider, and QueryProvider
- lib/zod-schemas.ts: Defines Google login payload schema

**AI Notes**: Login UI now supports both username/password and Google Identity Services; Google login shares the same toast-based feedback for inactive or missing accounts. Password reset flow remains a placeholder.

### FEAT-SEMESTER-MANAGEMENT - Semester Management

**Status**:

- Overall: in-progress
- Data Layer: implemented
- UI Layer: planned

**Use Case IDs**: UC-48, UC-49, UC-50, UC-51

**Related Files**:

- hooks/api/useSemesters.ts: React Query hooks for semester CRUD operations
- lib/zod-schemas.ts: Semester validation schemas (Data Contract)
- types/index.ts: Semester TypeScript types
- lib/constants.ts: Semester API endpoints and query keys

**AI Notes**: The data layer, including hooks, validation, and types, is fully implemented. However, no UI screens or components for managing semesters have been created yet.

---

## Screen Status

### SCR-HOME-PAGE - Home Page

**Platform**: web_lecturer  
**SOT Reference**: None  
**Main Route**: /  
**Main Component**: app/page.tsx

**Dependencies**:

- Features: FEAT-UI-INFRASTRUCTURE
- Components: ModeToggle
- Hooks: None

**AI Notes**: A basic home page demonstrating the theme switching functionality. Serves as the root entry point.

### SCR-LOGIN - Login Screen

**Platform**: web_lecturer  
**SOT Reference**: UC-01  
**Main Route**: /login  
**Main Component**: app/login/page.tsx

**Dependencies**:

- Features: FEAT-USER-AUTHENTICATION
- Components: LoginForm, Button, Input, Form, Separator
- Hooks: useLogin

**AI Notes**: Provides username/password login with toast feedback and a functioning Google Sign-In button backed by useGoogleLogin.

### SCR-FORGOT-PASSWORD - Forgot Password Screen

**Platform**: web_lecturer  
**SOT Reference**: UC-04  
**Main Route**: /forgot-password  
**Main Component**: app/forgot-password/page.tsx

**Dependencies**:

- Features: FEAT-USER-AUTHENTICATION
- Components: Button
- Hooks: None

**AI Notes**: Placeholder messaging directing users to administrator support until backend flow is available.

---

## AI Development Guidelines

### Documentation Maintenance

After implementing a new feature, update this manifest file to reflect the new state of the codebase.

### API Integration Workflow

For new entities, first define endpoints in endpoints.ts, then schemas in zod-schemas.ts, types in index.ts, and finally create React Query hooks in hooks/api/.

### Component Development

Build new components by composing existing base components from components/ui/. Place custom, feature-specific components in a structured manner.
