# Architecture Review: Template & Instance

## Verdict

The Template & Instance architecture covers the core problems from the
specification:

- no infinite task materialization;
- independent status for one recurring occurrence;
- one-off cancellation and movement;
- history preservation for materialized instances;
- protected tags;
- bounded date-window task lists.

The architecture is strong enough for the assignment if the implementation
explicitly handles the edge cases below.

## Coverage Matrix

| Spec problem | Current coverage | Required refinement |
|--------------|------------------|---------------------|
| Basic CRUD | Covered by public `/tasks` CRUD over virtual and materialized instances | API docs must explain that templates are internal implementation details |
| Tags | Covered by `TaskTemplateTag` | Tags belong to templates; instances inherit tags in responses |
| Infinity problem | Covered by virtual generation | Require bounded `from`/`to` and cap max window size |
| Per-occurrence status | Covered by materialized `Task` | Materialization must be idempotent by template/date |
| One-off cancel/move | Covered by materialized `Task.status` and `due_date` | Listing must suppress original virtual occurrence when moved |
| History | Covered by Discard for `Task` and `end_date` for templates | Template edits must not rewrite past virtual history |
| Protected seed tags | Covered | Enforce at model/service layer and test seeds |

## Edge Cases and Decisions

### Template Edits Can Rewrite Virtual History

**Problem**: If a recurring template is edited in place, old virtual occurrences
for past dates would be regenerated using the new title, description, or
schedule.

**Decision**: Recurring template edits are prospective. Schedule-affecting or
display-affecting edits close the current template at `effective_date - 1` and
create a successor `TaskTemplate` with `previous_template_id` pointing to the
old template. The default `effective_date` is today.

**Result**: Historical windows still use the old template; future windows use
the new template.

Tag changes on recurring templates follow the same prospective revision rule,
because otherwise past virtual occurrences would be regenerated with current
tag assignments.

### Closing a Template Does Not Hide Future Materialized Tasks

**Problem**: Setting `end_date = today` stops future virtual generation, but
future materialized tasks could still appear.

**Decision**: Closing a template sets `end_date` to today and discards kept
materialized tasks with `due_date > end_date`. Past and today's materialized
tasks remain. Because `end_date` is inclusive, deleting a recurring series means
"do not create future tasks", not "erase today".

**Result**: Deleting a recurring series stops future appearances while
preserving history.

### Moved Instances Can Duplicate or Disappear

**Problem**: If an occurrence generated for July 10 is moved to July 12, a July
10 list must not show the original virtual occurrence, and a July 12 list must
show the materialized moved task.

**Decision**: Listing loads materialized tasks where either `occurrence_date` or
`due_date` intersects the requested window. Materialized tasks suppress virtual
occurrences with the same public task ID
`tpl_<task_template_id>_<occurrence_date>`. Final output is filtered by
`due_date`.

**Result**: Moved instances appear on their actual due date and do not duplicate
at their original date.

### Public Task IDs for Virtual Occurrences

**Problem**: A virtual occurrence has no database `tasks.id`, but clients still
need one stable identifier for `GET`, `PATCH`, and `DELETE`.

**Decision**: Public task responses use `id` in the format
`tpl_<task_template_id>_<occurrence_date>`. The API parses this ID to locate the
template and original occurrence date. The physical database task ID remains
internal.

**Result**: The client sees a normal `/tasks` resource while the server can keep
recurring instances virtual until a write materializes them.

### Materialization Race Conditions

**Problem**: Two requests can try to materialize the same virtual occurrence at
the same time.

**Decision**: Add a strict unique index on
`(task_template_id, occurrence_date)` and materialize inside a transaction using
idempotent find-or-create-or-restore behavior.

**Result**: One physical task exists for one active occurrence instance.

### Date Window Abuse

**Problem**: A client can request an excessively large date window.

**Decision**: `from` and `to` are required for task instance lists, `from <= to`
is required, and the maximum window is 366 days.

**Result**: The API can safely expand recurrence rules in memory.

### Specific Dates and Monthly Boundary Dates

**Problem**: Duplicate dates, invalid dates, and month lengths can produce
surprising results.

**Decision**:

- `specific_dates` are stored as a PostgreSQL `date[]` with default `[]` and
  are normalized to sorted unique dates.
- `specific_dates` must be on or after `start_date` and on or before `end_date`
  when `end_date` is present.
- Monthly recurrence for day 29, 30, or 31 skips months where that day does not
  exist.

### Day Parity Rules

**Problem**: Even/odd recurrence needs an anchor.

**Decision**: `day_parity` generates dates on or after `start_date` whose day of
month matches the selected parity. `end_date`, if present, is inclusive.

### Discarded Tasks and Virtual Fallback

**Problem**: If a materialized task is discarded, the same virtual occurrence
could reappear and make deletion look ineffective.

**Decision**: Discarding a materialized task suppresses the virtual occurrence
for the same template/date in normal lists. The generator must load all
materialized tasks, including discarded rows. Rematerialization must explicitly
restore or update the discarded row because the unique index forbids a duplicate.

**Result**: Deleting one materialized instance hides it from normal task lists
without hard deletion.

### Cancel Is Not Delete

**Problem**: Canceling and deleting one occurrence can both stop normal work,
but they mean different things for history and UI.

**Decision**: Canceling materializes or updates the occurrence with
`status: canceled`, `materialization_reason: status_change`, and
`discarded_at: nil`, so it remains visible. Deleting discards an existing task,
or creates and discards a suppression marker for a virtual occurrence with
`materialization_reason: delete`, so it is hidden from normal lists.

**Result**: Canceled tasks are visible history; deleted occurrences are hidden
while still suppressing virtual fallback.

## Architecture Additions

- `TaskTemplate.previous_template_id` for prospective template revisions.
- `TaskTemplateRevision` service, or equivalent service object, to close and
  create successor templates.
- `TaskTemplateCloser` service to close a template and discard future
  materialized tasks.
- `TaskMaterializer` service to idempotently create/update one physical task.
- Public task ID parser/serializer for `tpl_<template_id>_<occurrence_date>`.
- `Recurrence::OccurrenceWindow` value object to validate `from`, `to`, and max
  window size.
- `Recurrence::OccurrenceGenerator` service to generate virtual occurrences
  from templates.

## Test Obligations

- Template revision preserves old virtual history and produces future
  occurrences from the successor template.
- Closing a template stops future virtual and materialized appearances.
- Moved occurrence appears on `due_date`, not original `occurrence_date`.
- Discarded task suppresses virtual fallback for the same occurrence.
- Canceling an occurrence remains visible with status `canceled`.
- Deleting a virtual occurrence creates a discarded suppression marker.
- Public task ID works for list, get, patch, and delete of virtual and physical
  occurrences.
- Concurrent materialization creates or restores one task row.
- Monthly day 31 skips shorter months.
- Specific dates are unique, sorted, and bounded by template dates.
