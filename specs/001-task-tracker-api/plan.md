# Implementation Plan: Task Tracker API

**Branch**: `(none; Git repository not initialized)` | **Date**: 2026-06-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-task-tracker-api/spec.md`

## Summary

Build a Rails API module for medical staff task tracking using the Template &
Instance pattern:

- `TaskTemplate` is the user's task definition and recurrence rule.
- `Task` is a concrete execution instance for a specific date.
- The public API exposes task instances as `/api/v1/tasks`; templates remain an
  internal persistence and recurrence mechanism.
- Creating any task always creates a `TaskTemplate`.
- Creating a one-time task (`recurrence_type: once`) also creates one physical
  `Task` immediately.
- Creating a recurring task creates only the `TaskTemplate`; future `Task`
  records are not created ahead of time.
- Recurring instances are generated virtually for requested date windows.
- A physical `Task` for a recurring occurrence is created only when that
  occurrence is changed, canceled, completed, moved, or explicitly materialized.

This solves the infinity problem without losing history. The system never
creates tasks for years ahead, but each changed occurrence can still have its
own persisted state.

## Technical Context

**Language/Version**: Ruby 3.4.3, Rails 8.0.5 API mode

**Primary Dependencies**: Rails, Active Record, PostgreSQL adapter, Puma,
dry-validation for explicit request contracts and coercion, Discard for soft
deletion/history of materialized `Task` records, RSpec, Brakeman, RuboCop
Rails Omakase, rswag for Swagger/OpenAPI generation

**Storage**: PostgreSQL 16+ for development, test, and production-style runs

**Testing**: RSpec with Rails request specs, model specs, form/contract specs,
serializer specs, service specs for template occurrence generation/materialization,
and seed/protected-tag tests

**Target Platform**: Container-friendly Linux web service exposing JSON HTTP API

**Project Type**: Rails API web service

**Performance Goals**: Task list requests for a 90-day window complete without
pre-creating recurring tasks outside that window; reviewer workflows complete
within the measurable outcomes defined in the spec

**Constraints**: Recurring tasks must not be materialized infinitely; list
queries must require or enforce a bounded date range; protected seed tags cannot
be edited or deleted; template deletion closes the template via `end_date`
instead of destroying it; materialized `Task` deletion uses Discard; Swagger
documentation must match behavior

**Scale/Scope**: Single Rails API application for the test assignment; no
authentication or multi-tenant authorization in v1

## Architecture Decisions

### Template & Instance

`TaskTemplate` is the authoritative record for anything the user creates.
It stores common task fields, tags, recurrence type, recurrence parameters,
`start_date`, and optional `end_date`. It does not store status; virtual
occurrences are always `pending`, and any status change materializes a `Task`.

`Task` is a concrete instance for one date. It belongs to a `TaskTemplate` and
stores `occurrence_date`, actual `due_date`, status, and optional materialized
copies/overrides of title and description. Physical tasks exist for one-time
tasks immediately and for recurring occurrences only after materialization.

The public task ID is not the database `tasks.id`. API responses use a stable
instance ID in the format `tpl_<task_template_id>_<occurrence_date>`, such as
`tpl_12_2026-07-01`. The same ID addresses both virtual and materialized forms
of the same occurrence.

### Recurrence Types

The supported `TaskTemplate.recurrence_type` values are:

- `once`: one date; create one `Task` immediately.
- `daily`: every N days from `start_date`.
- `monthly`: every month on a specific day of month.
- `specific_dates`: only selected dates.
- `day_parity`: even or odd days of month.

### Listing Strategy

`GET /api/v1/tasks?from=...&to=...` returns a unified instance view:

1. Validate `from`, `to`, `from <= to`, and maximum window size of 366 days.
2. Load templates active in the requested window.
3. Generate virtual occurrences for each template inside the window.
4. Load all materialized `Task` records, including discarded rows, whose
   `occurrence_date` or `due_date` intersects the requested window.
5. Overlay materialized tasks onto virtual occurrences by public task ID
   (`tpl_<task_template_id>_<occurrence_date>`).
6. Suppress virtual occurrences hidden by discarded materialized tasks.
7. Filter final output by `due_date`, status, materialization, and tags.

Virtual and materialized occurrences are serialized with the same public `id`;
normal clients do not need to know whether a row exists in `tasks`.
List responses stay compact. Detail responses from `GET /tasks/:id`,
`POST /tasks`, and `PATCH /tasks/:id` additionally include a `recurrence`
object, or `null` for one-time tasks.

### Instance Changes and Materialization

Changing a virtual recurring occurrence materializes one `Task` linked to the
template and occurrence date. Marking completed, canceling, moving, or editing
one occurrence therefore affects only that instance.

Deleting a materialized `Task` uses Discard so history remains queryable when
needed. Canceling and deleting are intentionally different:

- canceling an occurrence materializes or updates a `Task` with
  `status: canceled`, `materialization_reason: status_change`, and no
  `discarded_at`; it remains visible in normal task lists;
- deleting an occurrence discards an existing `Task`, or creates and immediately
  discards a suppression marker for a virtual occurrence with
  `materialization_reason: delete`; it is hidden from normal task lists and
  suppresses virtual fallback.

`GET /api/v1/tasks/:id`, `PATCH /api/v1/tasks/:id`, and
`DELETE /api/v1/tasks/:id` parse the public instance ID. `PATCH` materializes a
virtual occurrence automatically when needed. `DELETE` works the same way for
virtual and physical occurrences from the client's point of view.

### Closing Templates

Destroying a `TaskTemplate` does not remove it. The API closes the template by
setting `end_date` to the current date. This preserves previous task history and
stops future virtual generation. Because `end_date` is inclusive, past
occurrences and today's occurrence remain valid; only future occurrences are
hidden.

Closing also discards kept materialized tasks with `due_date > end_date`, so a
closed recurring series does not keep showing future customized instances.

### Template Revisions

Recurring template edits are prospective. Updating title, description,
recurrence parameters, or tag assignments for a recurring template closes the
current template at the requested effective date minus one day and creates a
successor `TaskTemplate` with `previous_template_id` pointing to the old
template. `effective_date` is a transient `PATCH /tasks/:id` request parameter,
not a database column. The default effective date is today. This prevents
in-place edits from rewriting historical virtual occurrences.

If `effective_date <= current_template.start_date`, the template is updated in
place because there is no earlier generated window to preserve. If the template
already has an `end_date` before `effective_date`, the update is rejected.

One-time template edits update the single physical task as well as the template.

### Recurrence Boundaries

- `end_date` is inclusive.
- `daily` uses `start_date` as the interval anchor.
- `monthly` skips months where the selected day does not exist.
- `specific_dates` are stored as PostgreSQL `date[]`, normalized to sorted
  unique dates, and must fit the template date bounds.
- `day_parity` generates even/odd day numbers on or after `start_date`.

### Idempotent Materialization

Materializing a virtual occurrence is done through a service transaction. A
unique index on `(task_template_id, occurrence_date)` prevents duplicate
instances under concurrent requests. A discarded row is the suppression marker
for that template/date; rematerialization must restore or update that row
instead of inserting a duplicate.

### Request Pipeline and Code Organization

Use the same maintainable boundary style as the sibling `api-service`
reference:

```text
controller -> form -> contract -> domain/service -> serializer
```

- Controllers stay thin: permit params, instantiate a form, render serialized
  success or validation errors.
- Forms own one public API operation. A form calls a dry-validation contract,
  exposes `errors`, and orchestrates model/service calls.
- Contracts inherit from `ApplicationContract < Dry::Validation::Contract` and
  own request shape validation, type coercion, enum checks, date-window checks,
  public task ID parsing rules, and record-existence rules where appropriate.
- Serializers inherit from `ApplicationSerializer`, expose `.call`, and own the
  public JSON shape. Use serializer views for compact list responses and detail
  responses with `recurrence`.
- Domain services remain focused on recurrence generation, task
  materialization, template revision, and template closing.
- Shared helper modules such as `Callable` and `DryValidationHelpers` live under
  `lib/` to keep forms, services, and serializers small.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- PASS: API contract is documented in `contracts/openapi.yaml` and can be
  surfaced through Swagger tooling.
- PASS: Template recurrence plus bounded virtual generation avoids unbounded
  future materialization.
- PASS: Physical `Task` instances isolate changed occurrence state from the
  template.
- PASS: Protected seed tags are represented in the data model and test plan.
- PASS: PostgreSQL 16+ is the configured persistence target.
- PASS: Tests are planned for API behavior, recurrence generation, task
  materialization, seeds, Discard behavior, and protected tags.
- PASS: README assumptions and startup instructions are present and will be
  updated after implementation.

## Project Structure

### Documentation (this feature)

```text
specs/001-task-tracker-api/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml
└── tasks.md              # Created by /speckit-tasks, not this phase
```

### Source Code (repository root)

```text
app/
├── controllers/
│   └── api/
│       └── v1/
│           ├── application_controller.rb
│           ├── tags_controller.rb
│           ├── task_series_controller.rb
│           ├── task_tags_controller.rb
│           └── tasks_controller.rb
├── contracts/
│   ├── application_contract.rb
│   └── api/
│       └── v1/
│           ├── task_create_contract.rb
│           ├── task_update_contract.rb
│           ├── task_index_contract.rb
│           ├── task_id_contract.rb
│           └── tag_contract.rb
├── forms/
│   └── api/
│       └── v1/
│           ├── task_create_form.rb
│           ├── task_update_form.rb
│           ├── task_index_form.rb
│           ├── task_show_form.rb
│           ├── task_delete_form.rb
│           ├── task_series_close_form.rb
│           ├── task_tags_form.rb
│           └── tag_form.rb
├── models/
│   ├── task_template.rb
│   ├── task.rb
│   ├── tag.rb
│   └── task_template_tag.rb
├── serializers/
│   ├── application_serializer.rb
│   └── api/
│       └── v1/
│           ├── task_serializer.rb
│           └── tag_serializer.rb
└── services/
    ├── task_template_closer.rb
    ├── task_template_reviser.rb
    ├── task_materializer.rb
    ├── task_instance.rb
    ├── public_task_id.rb
    └── recurrence/
        ├── occurrence_generator.rb
        └── occurrence_window.rb

config/
├── initializers/
│   ├── dry_validation.rb
│   └── dry_types.rb
└── routes.rb

lib/
├── callable.rb
└── dry_validation_helpers.rb

db/
├── migrate/
└── seeds.rb

spec/
├── contracts/
│   └── api/
│       └── v1/
├── forms/
│   └── api/
│       └── v1/
├── models/
├── requests/
│   └── api/
│       └── v1/
├── serializers/
│   └── api/
│       └── v1/
├── services/
│   └── recurrence/
├── rails_helper.rb
└── spec_helper.rb

specs/001-task-tracker-api/
└── contracts/
    └── openapi.yaml
```

**Structure Decision**: Use standard Rails API directories while keeping
Template & Instance mostly internal. Public controllers delegate operation
logic to forms. Forms validate through dry-validation contracts, call domain
services, and return objects ready for serializers. Serializers define compact
and detailed public task responses. Models keep persistence rules and
associations; recurrence and materialization behavior stays in service objects.

## Complexity Tracking

No constitution violations.
