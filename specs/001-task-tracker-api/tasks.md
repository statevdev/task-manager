# Tasks: Task Tracker API

**Input**: Design documents from `/specs/001-task-tracker-api/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/openapi.yaml](contracts/openapi.yaml), [quickstart.md](quickstart.md)

**Tests**: Required by the project constitution. Each user story includes request/form/contract/service tests as appropriate, and tests should fail before implementation.

**Organization**: Tasks are grouped by independently testable user story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Install dependencies and create shared directories/helpers used by all stories.

- [X] T001 Add `dry-validation`, `discard`, and `rswag` runtime dependencies and update `Gemfile.lock` in `Gemfile`
- [X] T002 [P] Configure Rails autoloading for `lib/` helpers in `config/application.rb`
- [X] T003 [P] Add `.call` class helper in `lib/callable.rb`
- [X] T004 [P] Add dry-validation nested-result helpers in `lib/dry_validation_helpers.rb`
- [X] T005 Add dry-validation initializers and messages in `config/initializers/dry_validation.rb`, `config/initializers/dry_types.rb`, and `config/locales/dry_validation.en.yml`
- [X] T006 [P] Create base dry-validation contract in `app/contracts/application_contract.rb`
- [X] T007 [P] Create callable base serializer with list/detail view support in `app/serializers/application_serializer.rb`
- [X] T008 [P] Create API base controller render helpers in `app/controllers/api/v1/application_controller.rb`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared API routing and support objects that block all user stories.

**CRITICAL**: No user story work can begin until this phase is complete.

- [X] T009 Configure `/api/v1` routes for tasks, task tags, task series, and tags in `config/routes.rb`
- [X] T010 [P] Add public task ID parser/formatter service for `tpl_<template_id>_<occurrence_date>` in `app/services/public_task_id.rb`
- [X] T011 [P] Add shared response wrapper helpers for `{ data: ... }` and `{ errors: ... }` in `app/controllers/api/v1/application_controller.rb`
- [X] T012 [P] Add base form behavior for `call`, `valid?`, and `errors` in `app/forms/application_form.rb`
- [X] T013 [P] Add API namespace directories for forms, contracts, and serializers under `app/forms/api/v1/`, `app/contracts/api/v1/`, and `app/serializers/api/v1/`

**Checkpoint**: Foundation ready; user story implementation can now begin.

---

## Phase 3: User Story 1 - Manage Basic Tasks (Priority: P1) MVP

**Goal**: Staff can create, retrieve, update, delete, list, and filter one-time tasks through the public `/api/v1/tasks` API.

**Independent Test**: Create a one-time task, retrieve it by public ID, update it, list by bounded date/status filters, delete it, and verify it returns 404 and is hidden from normal lists.

### Tests for User Story 1

- [X] T014 [P] [US1] Add request specs for one-time task create/show/update/delete/list behavior in `spec/requests/api/v1/tasks_spec.rb`
- [X] T015 [P] [US1] Add contract specs for task create/update/index/public-id validation in `spec/contracts/api/v1/task_contracts_spec.rb`
- [X] T016 [P] [US1] Add form specs for one-time task CRUD orchestration in `spec/forms/api/v1/task_basic_forms_spec.rb`
- [X] T017 [P] [US1] Add serializer specs for compact and detail task responses in `spec/serializers/api/v1/task_serializer_spec.rb`

### Implementation for User Story 1

- [X] T018 [US1] Create `task_templates` and `tasks` database tables with strict `tasks(task_template_id, occurrence_date)` unique index in `db/migrate/001_create_task_templates_and_tasks.rb`
- [X] T019 [US1] Implement `TaskTemplate` model validations and relationships in `app/models/task_template.rb`
- [X] T020 [US1] Implement `Task` model validations, status enum, materialization reason enum, and Discard support in `app/models/task.rb`
- [X] T021 [P] [US1] Implement task list/detail serializer views in `app/serializers/api/v1/task_serializer.rb`
- [X] T022 [P] [US1] Implement task create contract for one-time task payloads in `app/contracts/api/v1/task_create_contract.rb`
- [X] T023 [P] [US1] Implement task update contract for title, description, due date, and status in `app/contracts/api/v1/task_update_contract.rb`
- [X] T024 [P] [US1] Implement task index contract for `from`, `to`, `status[]`, and `tag_ids[]` filters in `app/contracts/api/v1/task_index_contract.rb`
- [X] T025 [P] [US1] Implement public task ID contract in `app/contracts/api/v1/task_id_contract.rb`
- [X] T026 [US1] Implement one-time task create form that creates `TaskTemplate` and physical `Task` in `app/forms/api/v1/task_create_form.rb`
- [X] T027 [US1] Implement task show form that resolves kept physical tasks or valid virtual occurrences in `app/forms/api/v1/task_show_form.rb`
- [X] T028 [US1] Implement task index form for bounded one-time task listing in `app/forms/api/v1/task_index_form.rb`
- [X] T029 [US1] Implement task update form for physical one-time tasks in `app/forms/api/v1/task_update_form.rb`
- [X] T030 [US1] Implement task delete form using Discard in `app/forms/api/v1/task_delete_form.rb`
- [X] T031 [US1] Implement public task CRUD actions in `app/controllers/api/v1/tasks_controller.rb`

**Checkpoint**: User Story 1 is fully functional and testable independently.

---

## Phase 4: User Story 2 - Organize Tasks With Tags (Priority: P2)

**Goal**: Staff can list/create/update/delete tags, attach/remove tags from tasks, and protected seed tags cannot be modified or destroyed.

**Independent Test**: Seed required tags, attach several tags to a task, remove one assignment, verify task response tags, and verify protected tags reject update/delete.

### Tests for User Story 2

- [X] T032 [P] [US2] Add model and seed specs for required protected tags in `spec/models/tag_spec.rb`
- [X] T033 [P] [US2] Add request specs for tag CRUD and protected tag failures in `spec/requests/api/v1/tags_spec.rb`
- [X] T034 [P] [US2] Add request specs for task tag attach/remove behavior in `spec/requests/api/v1/task_tags_spec.rb`
- [X] T035 [P] [US2] Add contract/form specs for tag operations in `spec/forms/api/v1/tag_forms_spec.rb`

### Implementation for User Story 2

- [X] T036 [US2] Create `tags` and `task_template_tags` database tables with unique indexes in `db/migrate/002_create_tags_and_task_template_tags.rb`
- [X] T037 [US2] Implement `Tag` model validations, protected guard methods, and dependent assignments in `app/models/tag.rb`
- [X] T038 [US2] Implement `TaskTemplateTag` join model validations in `app/models/task_template_tag.rb`
- [X] T039 [US2] Add tag associations to `TaskTemplate` in `app/models/task_template.rb`
- [X] T040 [P] [US2] Seed protected tags `отчетность`, `операции`, and `звонок` in `db/seeds.rb`
- [X] T041 [P] [US2] Implement tag serializer in `app/serializers/api/v1/tag_serializer.rb`
- [X] T042 [P] [US2] Implement tag and task-tag contracts in `app/contracts/api/v1/tag_contract.rb`
- [X] T043 [US2] Implement tag CRUD form with protected tag enforcement in `app/forms/api/v1/tag_form.rb`
- [X] T044 [US2] Implement task tag assignment form with recurring-series prospective behavior hooks in `app/forms/api/v1/task_tags_form.rb`
- [X] T045 [US2] Implement tags controller actions in `app/controllers/api/v1/tags_controller.rb`
- [X] T046 [US2] Include template tags in task serializer responses in `app/serializers/api/v1/task_serializer.rb`

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Schedule Recurring Tasks (Priority: P3)

**Goal**: Staff can create recurring tasks and list virtual occurrences for bounded date windows without pre-creating future tasks.

**Independent Test**: Create daily, monthly, specific-date, and day-parity tasks, list a 30-day bounded window, and verify exact occurrence dates without future physical rows.

### Tests for User Story 3

- [X] T047 [P] [US3] Add recurrence contract specs for daily, monthly, specific_dates, day_parity, and invalid payloads in `spec/contracts/api/v1/task_recurrence_contract_spec.rb`
- [X] T048 [P] [US3] Add occurrence window validation specs for required `from/to` and max 366-day windows in `spec/services/recurrence/occurrence_window_spec.rb`
- [X] T049 [P] [US3] Add occurrence generator specs for all recurrence types and boundary cases in `spec/services/recurrence/occurrence_generator_spec.rb`
- [X] T050 [P] [US3] Add request specs for recurring task creation and bounded listing in `spec/requests/api/v1/recurring_tasks_spec.rb`

### Implementation for User Story 3

- [X] T051 [US3] Extend task create/update contracts with recurrence payload rules in `app/contracts/api/v1/task_create_contract.rb` and `app/contracts/api/v1/task_update_contract.rb`
- [X] T052 [US3] Implement bounded date window value object in `app/services/recurrence/occurrence_window.rb`
- [X] T053 [US3] Implement recurrence occurrence generator for once, daily, monthly, specific_dates, and day_parity templates in `app/services/recurrence/occurrence_generator.rb`
- [X] T054 [US3] Extend task create form to create recurring `TaskTemplate` rows without future `Task` rows in `app/forms/api/v1/task_create_form.rb`
- [X] T055 [US3] Extend task index form to generate virtual occurrences, load materialized tasks including discarded rows, overlay by public task ID, and filter final results in `app/forms/api/v1/task_index_form.rb`
- [X] T056 [US3] Extend task show form to return virtual occurrences when no physical task exists and the template can generate the date in `app/forms/api/v1/task_show_form.rb`
- [X] T057 [US3] Add recurrence details to task detail serializer responses in `app/serializers/api/v1/task_serializer.rb`

**Checkpoint**: User Stories 1-3 work; recurring tasks solve the infinity problem.

---

## Phase 6: User Story 4 - Track Status Per Recurring Occurrence (Priority: P4)

**Goal**: Staff can change status for one recurring occurrence without changing adjacent occurrences in the same series.

**Independent Test**: Create a recurring task, mark one occurrence completed, list adjacent dates, and verify only that occurrence is materialized and changed.

### Tests for User Story 4

- [X] T058 [P] [US4] Add materializer service specs for idempotent virtual occurrence materialization in `spec/services/task_materializer_spec.rb`
- [X] T059 [P] [US4] Add request specs for completing one recurring occurrence without affecting adjacent dates in `spec/requests/api/v1/recurring_status_spec.rb`
- [X] T060 [P] [US4] Add form specs for PATCH materializing a virtual occurrence in `spec/forms/api/v1/task_update_materialization_form_spec.rb`

### Implementation for User Story 4

- [X] T061 [US4] Implement idempotent task materializer with find-or-create-or-restore behavior in `app/services/task_materializer.rb`
- [X] T062 [US4] Extend task update form to materialize virtual occurrences on status changes in `app/forms/api/v1/task_update_form.rb`
- [X] T063 [US4] Ensure task index overlay returns kept materialized status and adjacent virtual pending statuses in `app/forms/api/v1/task_index_form.rb`
- [X] T064 [US4] Add transaction and unique-index conflict handling for concurrent materialization in `app/services/task_materializer.rb`

**Checkpoint**: User Stories 1-4 work; per-occurrence status is isolated.

---

## Phase 7: User Story 5 - Override One Recurring Occurrence (Priority: P5)

**Goal**: Staff can cancel, move, delete, and revise one recurring occurrence or future series behavior without changing the whole historical series.

**Independent Test**: Cancel one occurrence, move another occurrence, delete a virtual occurrence, close a series, and revise future series settings while past windows remain unchanged.

### Tests for User Story 5

- [X] T065 [P] [US5] Add request specs for cancel and move one recurring occurrence in `spec/requests/api/v1/recurring_override_spec.rb`
- [X] T066 [P] [US5] Add request specs for deleting virtual occurrences and suppressing fallback in `spec/requests/api/v1/task_delete_suppression_spec.rb`
- [X] T067 [P] [US5] Add service specs for prospective template revision and effective_date behavior in `spec/services/task_template_reviser_spec.rb`
- [X] T068 [P] [US5] Add service specs for closing a recurring series and discarding future materialized tasks in `spec/services/task_template_closer_spec.rb`

### Implementation for User Story 5

- [X] T069 [US5] Extend task update form to handle due_date moves and canceled status while preserving original occurrence_date in `app/forms/api/v1/task_update_form.rb`
- [X] T070 [US5] Extend task delete form to create and discard suppression markers for virtual occurrences in `app/forms/api/v1/task_delete_form.rb`
- [X] T071 [US5] Implement prospective template revision service with successor templates and tag copying in `app/services/task_template_reviser.rb`
- [X] T072 [US5] Implement recurring series close service with inclusive `end_date = Date.current` and future materialized discard in `app/services/task_template_closer.rb`
- [X] T073 [US5] Implement task series close form for `DELETE /api/v1/tasks/:id/series` in `app/forms/api/v1/task_series_close_form.rb`
- [X] T074 [US5] Wire move, cancel, delete, and series close flows through tasks controller actions in `app/controllers/api/v1/tasks_controller.rb`

**Checkpoint**: All functional user stories work independently and together.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, Swagger exposure, performance checks, and final verification.

- [X] T075 [P] Configure rswag API and Swagger UI mounting in `config/routes.rb` and `config/initializers/rswag_api.rb`
- [X] T076 [P] Copy or generate OpenAPI contract into rswag-accessible docs in `swagger/v1/openapi.yaml`
- [X] T077 [P] Add Docker Compose configuration for Rails and PostgreSQL review startup in `docker-compose.yml`
- [X] T078 [P] Update README startup, assumptions, architecture, and Swagger instructions in `README.md`
- [X] T079 [P] Add quickstart validation notes and example curl requests in `specs/001-task-tracker-api/quickstart.md`
- [X] T080 Run RSpec, Brakeman, and RuboCop, then record results in `HISTORY.md`
- [X] T081 Validate OpenAPI YAML and update any drift from implementation in `specs/001-task-tracker-api/contracts/openapi.yaml`
- [X] T082 Review `HISTORY.md` for completeness before delivery in `HISTORY.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies.
- **Phase 2 Foundational**: Depends on Phase 1; blocks all user stories.
- **Phase 3 US1**: Depends on Phase 2; MVP scope.
- **Phase 4 US2**: Depends on Phase 3 for task/template records.
- **Phase 5 US3**: Depends on Phase 3 and can proceed before or after US2 if tag work is not touched.
- **Phase 6 US4**: Depends on Phase 5 recurring virtual occurrences.
- **Phase 7 US5**: Depends on Phase 5 and Phase 6 materialization behavior.
- **Phase 8 Polish**: Depends on desired user stories being complete.

### User Story Dependencies

- **US1 Manage Basic Tasks**: No user-story dependency after foundation; establishes public task CRUD and core models.
- **US2 Organize Tasks With Tags**: Depends on US1 task templates; independently testable with one created task.
- **US3 Schedule Recurring Tasks**: Depends on US1 core task/template structure; independently testable through recurring creation/listing.
- **US4 Track Status Per Recurring Occurrence**: Depends on US3 virtual recurring occurrences.
- **US5 Override One Recurring Occurrence**: Depends on US3 recurrence and US4 materialization.

### Within Each User Story

- Write tests first and confirm they fail.
- Migrations/models before contracts/forms that persist data.
- Contracts before forms.
- Services before forms that orchestrate them.
- Forms before controllers.
- Serializers can be implemented in parallel with forms when response shape is known.

---

## Parallel Opportunities

- Setup helper files T002-T008 can be parallelized after dependencies are declared.
- Foundational support tasks T010-T013 touch different files and can run in parallel.
- Tests within each user story are parallelizable.
- Contracts and serializers within a story can usually be implemented in parallel.
- US2 and US3 can be developed in parallel after US1 if both avoid editing the same serializer/controller lines at the same time.

---

## Parallel Example: User Story 1

```bash
Task: "T014 Add request specs for one-time task create/show/update/delete/list behavior in spec/requests/api/v1/tasks_spec.rb"
Task: "T015 Add contract specs for task create/update/index/public-id validation in spec/contracts/api/v1/task_contracts_spec.rb"
Task: "T017 Add serializer specs for compact and detail task responses in spec/serializers/api/v1/task_serializer_spec.rb"
```

---

## Parallel Example: User Story 3

```bash
Task: "T047 Add recurrence contract specs in spec/contracts/api/v1/task_recurrence_contract_spec.rb"
Task: "T048 Add occurrence window validation specs in spec/services/recurrence/occurrence_window_spec.rb"
Task: "T049 Add occurrence generator specs in spec/services/recurrence/occurrence_generator_spec.rb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup.
2. Complete Phase 2 foundation.
3. Complete Phase 3 US1.
4. Validate one-time task CRUD and bounded list filters.
5. Stop for demo or continue incrementally.

### Incremental Delivery

1. US1: Basic public task CRUD.
2. US2: Tags and protected seed tags.
3. US3: Recurrence and bounded virtual generation.
4. US4: Per-occurrence status materialization.
5. US5: Cancel, move, delete suppression, series close, and prospective revision.

### Final Validation

1. Run `bundle exec rspec`.
2. Run `bundle exec brakeman`.
3. Run `bundle exec rubocop`.
4. Validate `specs/001-task-tracker-api/contracts/openapi.yaml`.
5. Run the quickstart scenarios and update `README.md`/`HISTORY.md`.

---

## Phase 9: Convergence

- [X] T083 Wire public recurring series updates through `TaskTemplateReviser` for `recurrence`, `tag_ids`, and `effective_date` request fields per plan: Template Revisions (partial)
- [X] T084 Implement `tag_ids[]` filtering in `GET /api/v1/tasks` for virtual and materialized task instances per plan: Listing Strategy and OpenAPI contract (partial)
- [X] T085 Resolve virtual recurring occurrences in task tag assignment endpoints and apply recurring tag changes prospectively per plan: Template Revisions and `/tasks/{id}/tags` contract (partial)
- [X] T086 Validate `tag_ids` existence in `POST /api/v1/tasks` and return clear 422 errors for missing tags per FR-007 and FR-008 (partial)
- [X] T087 Reject duplicate `specific_dates` recurrence payloads instead of silently normalizing them per Edge Cases (partial)
- [X] T088 Add validation coverage for open-ended recurring task listing over a 90-day window without pre-creating future tasks per SC-005 (missing)
- [X] T089 Decide and implement recurring `POST /api/v1/tasks` behavior when a non-pending `status` is provided, either materializing the first occurrence or rejecting/documenting the input per FR-001 (partial)

## Phase 10: Convergence

- [X] T090 Return a clear 422 validation error when recurring series revision `effective_date` is after the current template `end_date`, with RSpec coverage, per plan: Template Revisions (partial)
- [X] T091 Validate `DELETE /api/v1/tasks/:id/series` against an existing recurring physical or virtual occurrence before closing the template, and reject impossible or one-time series-close requests, per T073 and OpenAPI `/tasks/{id}/series` (partial)
