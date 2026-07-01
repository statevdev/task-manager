# Data Model: Task Tracker API

## TaskTemplate

Represents any task definition created by the user. It is the template for one
or more concrete `Task` instances.

**Fields**

- `id`: unique identifier
- `title`: required string
- `description`: optional text
- `recurrence_type`: required enum, one of `once`, `daily`, `monthly`, `specific_dates`, `day_parity`
- `start_date`: required date
- `end_date`: optional date; closes future generation when present
- `previous_template_id`: optional reference to the template version this one replaces
- `interval`: integer used by `daily`
- `day_of_month`: integer from 1 through 31 used by `monthly`
- `specific_dates`: PostgreSQL `date[]`, default `[]`, null `false`, used by `specific_dates`
- `day_parity`: enum `even` or `odd` used by `day_parity`
- `created_at`, `updated_at`: timestamps

**Relationships**

- Has many task template tag assignments.
- Has many tags through task template tag assignments.
- Has many materialized tasks.
- Optionally belongs to a previous task template.
- May have successor task templates.

**Validation Rules**

- `title` must be present.
- `start_date` must be present.
- `end_date`, when present, must not be before `start_date`.
- `once` requires no recurrence parameters and creates one `Task`.
- `daily` requires `interval` greater than zero.
- `monthly` requires `day_of_month` from 1 through 31.
- `specific_dates` requires at least one unique date.
- `day_parity` requires `day_parity`.
- Only fields relevant to the selected `recurrence_type` may be populated.

**Lifecycle Rules**

- Creating a template with `recurrence_type: once` creates one physical `Task`
  for `start_date`.
- Creating a recurring template does not create future `Task` rows.
- Deleting a template sets `end_date` to the current date instead of destroying
  the template. Because `end_date` is inclusive, past occurrences and today's
  occurrences remain valid while future occurrences stop being generated.
- Recurring template updates that affect future behavior, including title,
  description, recurrence parameters, and tag assignments, close the current
  template at the requested effective date minus one day and create a successor
  template.
- Closing a template discards kept materialized tasks with `due_date` after the
  closing `end_date`.

**Prospective Revision Mechanics**

When a recurring series is updated through the public task API with changes that
should affect future occurrences, the system does not mutate the original
template in place.

`effective_date` is a transient request parameter for `PATCH /tasks/:id`, not a
database column. It answers: "from which date should these series changes start
working?" If omitted, the service uses `Date.current`.

1. Resolve `effective_date` from the request, or use `Date.current`.
2. If `effective_date <= current_template.start_date`, update the current
   template in place because there is no earlier template window to preserve.
3. If the current template has `end_date` and `effective_date > end_date`,
   reject the update because it starts after the series is already closed.
4. Otherwise update the current template with
   `end_date = effective_date - 1.day`.
5. Create a successor `TaskTemplate` with:
   - copied or updated title and description;
   - copied or updated recurrence parameters;
   - `start_date = effective_date`;
   - copied `end_date`, unless the update changes it;
   - `previous_template_id = old_template.id`.
6. Copy tag assignments to the successor, applying requested tag changes.
7. Keep existing materialized `Task` rows attached to the template that created
   their original occurrence.
8. Discard kept future materialized tasks from the old template when their
   `due_date` is after the old template's new `end_date`.

Example: a daily series starts on 2026-07-01. On 2026-07-10 the title is changed
with `effective_date = 2026-07-15`. The old template keeps
`start_date = 2026-07-01` and gets `end_date = 2026-07-14`. The successor
template starts on 2026-07-15 and points to the old template through
`previous_template_id`.

## Task

Concrete materialized execution instance for one date.

**Fields**

- `id`: unique identifier
- `task_template_id`: required template reference
- `occurrence_date`: required original template occurrence date
- `due_date`: required actual execution date; may differ from `occurrence_date` when moved
- `title`: required string copied from template when materialized, or changed for this instance
- `description`: optional text copied from template when materialized, or changed for this instance
- `status`: required enum, one of `pending`, `completed`, `canceled`
- `materialization_reason`: enum such as `once`, `status_change`, `move`, `edit`, `delete`, `manual`
- `discarded_at`: nullable timestamp managed by Discard
- `created_at`, `updated_at`: timestamps

**Relationships**

- Belongs to task template.
- Receives tags through its task template in API responses.

**Validation Rules**

- `task_template_id`, `occurrence_date`, `due_date`, `title`, and `status` must
  be present.
- One task row per template and `occurrence_date`, including discarded rows.
- `status` must be one of the supported statuses.
- When a physical task is created without an explicit status, the service sets
  `status: pending`.
- `due_date` may differ from `occurrence_date` only for a moved/materialized
  instance.
- Materialization must be idempotent for one template and occurrence date.

**Lifecycle Rules**

- A virtual occurrence becomes a `Task` when the occurrence is completed,
  canceled, moved, edited, or explicitly materialized.
- Deleting a materialized task discards it using Discard instead of hard
  deletion.
- A discarded materialized task suppresses virtual fallback for the same
  template and occurrence date in normal lists.
- The occurrence generator must load all materialized tasks for candidate
  template/date pairs, including discarded tasks. Its overlay logic is:
  kept task -> return the physical task; discarded task -> return nothing; no
  task row -> return the virtual occurrence.
- Canceling an occurrence creates or updates a materialized task with
  `status: canceled`, `materialization_reason: status_change`, and
  `discarded_at: nil`; canceled occurrences remain visible in normal task
  lists.
- Deleting a virtual recurring occurrence creates a physical suppression marker
  `Task` and immediately discards it with `materialization_reason: delete`;
  deleting an existing physical task discards that row. Deleted occurrences are
  hidden from normal lists and suppress virtual fallback.

## Tag

Reusable task label.

**Fields**

- `id`: unique identifier
- `name`: required unique string
- `protected`: required boolean, default `false`, null `false`
- `created_at`, `updated_at`: timestamps

**Relationships**

- Has many task template tag assignments.
- Has many task templates through task template tag assignments.

**Validation Rules**

- `name` must be present and unique.
- Protected tags cannot be updated or destroyed through normal API operations.
- Seed data must include protected tags `отчетность`, `операции`, and `звонок`.

## TaskTemplateTag

Join record between task templates and tags.

**Fields**

- `id`: unique identifier
- `task_template_id`: required template reference
- `tag_id`: required tag reference
- `created_at`, `updated_at`: timestamps

**Relationships**

- Belongs to task template.
- Belongs to tag.

**Validation Rules**

- The same tag cannot be assigned to the same task template more than once.

## Public Task API Identity

The external API exposes task instances through `/api/v1/tasks` and hides
whether an instance is virtual or materialized. Clients do not use the database
`tasks.id`.

**Public ID**

- Format: `tpl_<task_template_id>_<occurrence_date>`, for example
  `tpl_12_2026-07-01`.
- Meaning: one task instance identified by `task_template_id` and original
  `occurrence_date`.
- The same public ID is returned for a virtual occurrence and for the
  materialized `Task` that overrides it.
- `GET /api/v1/tasks/:id`, `PATCH /api/v1/tasks/:id`, and
  `DELETE /api/v1/tasks/:id` parse this public ID and operate on the physical
  task when it exists, or on the virtual occurrence when the template can
  generate it.

**Public Operation Semantics**

- `GET /tasks/:id`: returns a kept physical task, returns a virtual task if no
  physical row exists and the template can generate the occurrence, returns 404
  for discarded rows or impossible occurrences.
- `PATCH /tasks/:id`: updates an existing physical task, or materializes a
  virtual occurrence and applies the requested changes.
- `DELETE /tasks/:id`: discards an existing physical task, or creates and
  discards a suppression marker for an existing virtual occurrence.
- `POST /tasks`: creates a `TaskTemplate` internally. One-time tasks also create
  one physical `Task`; recurring tasks return the first visible instance for the
  provided `due_date` without pre-creating future tasks. Recurring creation
  accepts omitted `status` or `status: pending`; non-pending statuses are
  rejected so creation does not implicitly materialize the first occurrence.

## Task Instance Responses

Unified representations returned by public task endpoints. They may represent
either a virtual occurrence generated from a template or a physical `Task`.

### List Response

Returned by `GET /tasks`.

**Fields**

- `id`: public stable identifier, e.g. `tpl_12_2026-07-01`
- `title`
- `description`
- `occurrence_date`: original date generated from the template
- `due_date`: actual execution date; differs from `occurrence_date` when moved
- `status`: materialized task status or `pending` for virtual occurrences
- `recurrence_type`: copied from template
- `tags`: template tags

### Detail Response

Returned by `GET /tasks/:id`, `POST /tasks`, and `PATCH /tasks/:id`. Includes
all list response fields plus:

- `recurrence`: recurrence settings for the series, or `null` for one-time
  tasks
  - `type`: one of `daily`, `monthly`, `specific_dates`, `day_parity`
  - `interval`: present for `daily`
  - `end_date`: optional recurrence end date
  - `day_of_month`: present for `monthly`
  - `specific_dates`: present for `specific_dates`
  - `day_parity`: present for `day_parity`

Internal serializers may keep `task_template_id`, `previous_template_id`,
`materialized`, `discarded`, and database `task_id` for tests or debugging, but
the normal public response does not need to expose them.

## State Transitions

### Task Status

```text
pending -> completed
pending -> canceled
completed -> pending
completed -> canceled
canceled -> pending
```

### Template Lifecycle

```text
active -> closed_by_end_date
active -> superseded_by_successor_template
```

### Occurrence Materialization

```text
virtual occurrence -> materialized Task
materialized Task -> discarded Task
```

## Indexes and Constraints

- Unique index on `tags.name`.
- Unique index on `task_template_tags(task_template_id, tag_id)`.
- Unique index on `tasks(task_template_id, occurrence_date)`.
- Index on `task_templates(recurrence_type, start_date, end_date)`.
- Index on `task_templates(previous_template_id)`.
- Index on `tasks(due_date, status, discarded_at)`.
- Foreign keys from task template tags to task templates and tags.
- Foreign key from tasks to task templates.
