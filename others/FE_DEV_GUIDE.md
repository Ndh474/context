# Frontend Development Guide

Scope: Coding conventions, project structure, and step-by-step flow for adding new admin modules and wiring APIs. Use this as the single source of truth when implementing or reviewing features.

Key references in this repo:

- `lib/constants.ts`
- `lib/zod-schemas.ts`
- `types/index.ts`
- `lib/api-axios.ts`
- `hooks/api/*`
- `components/admin/*`
- `app/admin/*`
- `docs/api/*.txt` (backend API contracts)

---

## Project Structure

High level

- `app/` — Next.js app router pages/layouts.
- `components/` — Reusable UI and feature components (admin tables, dialogs, etc.).
- `hooks/api/` — React Query hooks per module, encapsulating API calls + schema parsing.
- `lib/` — Cross-cutting utilities: API client, constants, schemas.
- `docs/api/` — API specs from backend to implement against.

Per-module pattern (example: semesters, majors)

- Pages
  - `app/admin/<module>/page.tsx` — Page shell, URL params → query params, invokes hooks, renders table and dialogs.
- Components
  - `components/admin/<module>/<module>-table.tsx` — Data table shell + pagination.
  - `components/admin/<module>/<module>-columns.tsx` — Column defs for `@tanstack/react-table`.
  - `components/admin/<module>/<module>-form-dialog.tsx` — Create/Edit dialog.
  - `components/admin/<module>/delete-<module>-dialog.tsx` — Confirm deletion.
  - `components/admin/<module>/<module>-pagination.tsx` — Pagination UI.
- Hooks
  - `hooks/api/use<Module>.ts` — `useGet*`, `useGet*ById`, `useCreate*`, `useUpdate*`, `useDelete*` (+ child endpoints if any).
- Schemas & Types
  - `lib/zod-schemas.ts` — Zod schemas for payloads and responses.
  - `types/index.ts` — TS types inferred from Zod and query param interfaces.
- Endpoints & Query Keys
  - `lib/constants.ts` - `API_ENDPOINTS` and `QUERY_KEYS` entries for the module.
  - Pagination constants: `DEFAULT_PAGE_SIZE` (tables) and `FILTER_PAGE_SIZE` (combobox filters, defaults to 50).

---

## Coding Conventions

API surface

- Endpoints: add under `API_ENDPOINTS.<module>` with these keys when applicable:
  - `all` (collection), `byId(id)`, and nested: `subjects(id)`, `classes(id)`, `students(id)`, etc.
- React Query keys: add under `QUERY_KEYS.<module>` mirroring endpoint structure.

Schemas & types

- Always split payload vs response schemas.
  - Payloads: `create<Module>PayloadSchema`, `update<Module>PayloadSchema`.
  - Response: `<module>Schema` is the canonical shape received from BE.
- Counts or optional computed fields in responses should be resilient:
  - Prefer defaults or nullish transforms, e.g. `z.number().default(0)` or `z.number().nullish().transform(v => v ?? 0)` for fields like `totalClass`, `totalSubject`.
  Example:

  ```ts
  // Coerce null/undefined to 0 for computed counts
  const semesterSchema = z.object({
    // ...
    totalClass: z.number().nullish().transform(v => v ?? 0),
  })

  const majorSchema = z.object({
    // ...
    totalSubject: z.number().nullish().transform(v => v ?? 0),
  })

  const subjectSchema = z.object({
    // ...
    totalClass: z.number().nullish().transform(v => v ?? 0),
    totalActiveClass: z.number().nullish().transform(v => v ?? 0),
  })
  ```

- Define paginated wrappers once per response family: `{ items, totalPages, currentPage, pageSize, totalItems }`.
- Export TS types in `types/index.ts` via `z.infer<typeof ...>` and define explicit query param interfaces (`...QueryParams`).
Sorting policy
- Do not expose or rely on sorting by DB id in FE. Prefer stable, user-meaningful fields and whitelist allowed values in types and page logic.
  - Semesters: `name | code | startDate | endDate`
  - Majors: `name | code`
  - Subjects: `name | code`
  - Classes: `code`
- Pages must guard `sortBy` from URL against an allowlist and default safely when missing/invalid.

Combobox (Server-Side) Search

- Always use server-side search for large option sets (Semesters, Majors, Subjects, Classes, Rooms).
- Use `FILTER_PAGE_SIZE` (50) and pass `search` into the relevant hook.
- Bind `CommandInput` value to local query state and clear it when the popover closes.
- Examples:
  - Slots page: remote search for Semester, Subject, Class, Room.
  - Exams page: remote search for Semester, Subject, Room.
  - Classes page: remote search for Semester, Subject; dialog uses remote search, too.
  - Subjects page: remote search for Major in the filter and in the multi-select.
  - Cameras page: remote search for Room in filter; dialog uses remote search for Room.

Data fetching & errors

- Axios instance: `lib/api-axios.ts`
  - Adds `Authorization` if available.
  - Response interceptor unwraps `{ status, data }` and returns `data`.
  - On 401 (excluding login), clears session and redirects to `/login`.
- Always Zod-parse responses in hooks to enforce contract: `schema.parse(response)`.
- Error handling:
  - Use `formatApiError` from `lib/constants.ts` to convert backend error payloads to user messages.
  - Centralize error codes in `ERROR_CODES` and metadata in `API_ERRORS` (status + default message).

UI patterns

- Page state is driven by URL search params: `page`, `search`, `sort`, `sortBy`, `isActive`.
- Table columns contain: Code, Name, count (if applicable), Status, Action.
- Action menu includes Edit and a navigation to a related list (e.g., “View Classes/Subjects”).
- Create/Edit Dialogs
  - Create: shows all required fields; `code` is editable.
  - Edit: `code` becomes read-only; `isActive` toggle appears.
  - Map backend error codes to field errors inside the dialog.
- Subject/Class codes are uppercase; normalize to uppercase before submit.
- Delete Dialogs
  - Confirm irreversible action; note dependency constraints (FK or business rules).

Dates & formatting

- Persist dates to BE as `YYYY-MM-DD` (use `date-fns/format`).
- Compare dates at day precision when validating in forms on FE.

Performance

- React Query `staleTime`: default 5 minutes for list/detail.
- Key composition: include params in the key for list queries.

Nested endpoints (defer pattern)

- Prefer routing to the generic list view with a filter (e.g., /admin/subjects?majorId=..., /admin/classes?subjectId=...) instead of building per-parent nested views unless UX requires it.
- If a nested endpoint from docs is not used yet:
  - Do not add unused hooks/schemas; avoid dead code.
  - Leave a // TODO comment referencing the API (e.g., GET /majors/{id}/subjects, GET /subjects/{id}/classes) and why it’s deferred.
  - Reintroduce with a paginated schema and hook when an inline view is needed.

---

## Development Flow: Add A New Module (Checklist)

Assume a new entity “Departments” with endpoints similar to majors/semesters.

***1. Understand the contract***

- Read `docs/api/departments.txt` and enumerate endpoints, payloads, responses, errors.

***2. Define schemas***

- Add to `lib/zod-schemas.ts`:
  - `departmentSchema`, `paginatedDepartmentResponseSchema`.
  - `createDepartmentPayloadSchema`, `updateDepartmentPayloadSchema`.
  - Child response schemas if there are nested endpoints (e.g., `departmentSubjectsResponseSchema`).
- Tip: Use defaults on computed counts to avoid parse failures when BE omits them.

***3. Export types***

- In `types/index.ts` export:
  - `Department`, `CreateDepartmentPayload`, `UpdateDepartmentPayload`.
  - `PaginatedDepartmentResponse` and query param interfaces.

***4. Wire endpoints & query keys***

- In `lib/constants.ts` add `API_ENDPOINTS.departments`:
  - `all: "/departments"`, `byId: (id) => \\`/departments/${id}\\``, plus nested if any.
- Add `QUERY_KEYS.departments` with `all`, `detail(id)`, child keys.
- If needed, add error codes to `ERROR_CODES` and messages to `API_ERRORS`.

***5. Implement hooks***

- Create `hooks/api/useDepartments.ts` with:
  - `useGetDepartments(params)`, `useGetDepartmentById(id)`.
  - `useCreateDepartment()`, `useUpdateDepartment()`, `useDeleteDepartment()`.
  - Parse responses via Zod; use `formatApiError` in `onError`.

***6. Build UI***

- Create page: `app/admin/departments/page.tsx` mirroring majors/semesters pages.
  - Read URL params, call `useGetDepartments`, render table and dialogs, push URL on interactions.
- Components under `components/admin/departments/`:
  - `department-table.tsx`, `department-columns.tsx`, `department-pagination.tsx`.
  - `department-form-dialog.tsx`, `delete-department-dialog.tsx`.
  - Follow the same Edit/Read-only/Active toggle behaviors.

***7. Navigation & integration***

- Add menu item to appropriate `lib/menu-configs/*.ts`.
- "View …" actions should navigate to an existing list page with a filter (e.g., `/admin/subjects?departmentId=…`) unless a nested detail view is required.

***8. Validate***

- Ensure Zod schemas match actual payloads from the backend API.

***9. Review consistency (see next section)***

---

## Consistency Rules (Cross-Module)

- URL query params: support `page`, `search`, `sort` (asc|desc), `sortBy` (the subset allowed by BE), and `isActive` (true|false|null).
- Sort defaults: follow BE docs where possible; if FE deviates (e.g., default sort by name), keep that consistent across pages.
- Create vs Edit
  - Edit locks immutable keys like `code`.
  - `isActive` toggle appears only in Edit.
- Error code mapping: always use `ERROR_CODES` and `API_ERRORS` for clarity and consistent UX.
- Counts in response (e.g., `totalClass`, `totalSubject`) should never break parsing; use defaults.
- Nested endpoints: prefer routing to the generic list with a filter (simpler UI) unless a dedicated nested view is needed.

---

## File Reference Map (Examples)

- API endpoints & keys: `lib/constants.ts`
- Axios client & interceptors: `lib/api-axios.ts`
- Zod schemas: `lib/zod-schemas.ts`
- Types & query param interfaces: `types/index.ts`
- React Query hooks (examples):
  - Semesters: `hooks/api/useSemesters.ts`
  - Majors: `hooks/api/useMajors.ts`
- Admin pages:
  - Semesters: `app/admin/semesters/page.tsx`
  - Majors: `app/admin/majors/page.tsx`
- Admin components (pattern): `components/admin/<module>/*`
- API docs: `docs/api/*.txt`

---

## Review Checklist (Before Merge)

***1. Contract***

- Zod schemas reflect docs in `docs/api/<module>.txt`.
- Response counts defaulted; payload schemas validate constraints.

***2. Hooks***

- All endpoints implemented; responses parsed; errors mapped via `formatApiError`.

***3. UI***

- Search, filter, sort, pagination wired to URL params.
- Create/Edit dialogs follow code-lock + isActive-on-edit rules.
- Delete dialog warns about dependencies.

***4. Consistency***

- SortBy options exclude DB id. Whitelist allowed per module (see Sorting policy) and keep defaults consistent across pages.
- Navigation to related lists uses query-string filters.

---

## Notes from Current Implementation

- Semesters and Majors follow the above patterns closely.
- Semesters: `semesterSchema` already defaults `totalClass` to 0.
- Majors: consider defaulting `totalSubject` to 0 to avoid parse issues on create.
- Some nested “child” endpoints are implemented in hooks but not currently surfaced via UI; routing to the generic list with filters is the current UX standard.
