# Research: Task Tracker API

## Decision: Use Template & Instance as the core architecture

**Rationale**: The user-created task is best represented as a durable
`TaskTemplate`. A concrete `Task` represents execution on one date. This makes
one-time and recurring tasks follow the same conceptual model while keeping
per-date status isolated. `TaskTemplate` does not store status; virtual
occurrences are `pending` until materialized.

The public API still presents a simple `/tasks` resource. `TaskTemplate` is an
internal persistence and recurrence mechanism, not the primary client-facing
resource.

**Alternatives considered**:

- Single `tasks` table with recurrence columns: rejected because it mixes
  templates and concrete executions.
- Separate `RecurrenceRule`, `OccurrenceState`, and `OccurrenceOverride` tables:
  rejected after architecture review because a materialized `Task` can represent
  changed state, cancellation, and movement with fewer moving parts.

## Decision: Create physical tasks only when needed

**Rationale**: Creating a recurring template should not create future tasks for
unbounded dates. Virtual generation for a requested window solves the infinity
problem. A physical `Task` is created only for `once` templates, explicit
materialization, or a changed occurrence.

**Alternatives considered**:

- Pre-generate occurrences far into the future: rejected because it violates the
  infinity constraint.
- Rolling cache for the next N days: rejected for v1 because it adds background
  synchronization and invalidation complexity.

## Decision: Use `recurrence_type` on TaskTemplate

**Rationale**: The assignment requires a small fixed set of recurrence modes:
`once`, `daily`, `monthly`, `specific_dates`, and `day_parity`. Storing the type
and relevant parameters directly on `TaskTemplate` keeps the model easy to
inspect and explain.

**Alternatives considered**:

- Separate recurrence rules table: viable, but unnecessary for a single-rule
  template in this assignment.
- Full recurrence expression syntax: rejected as overpowered for the requested
  recurrence types.

## Decision: Close templates with `end_date`

**Rationale**: Destroying a template can make historical tasks harder to
understand. Setting `end_date` to the current date preserves the template and
prevents future virtual generation. Because `end_date` is inclusive, deleting a
recurring series preserves the past and today while hiding future occurrences.

**Alternatives considered**:

- Hard delete templates: rejected because it breaks auditability.
- Use Discard on templates: rejected for now because recurrence rules are better
  closed semantically by an end date.

## Decision: Apply recurring template edits prospectively

**Rationale**: In-place edits to a recurring template can rewrite virtual
history because past non-materialized occurrences are generated from the current
template. Prospective revisions close the old template at `effective_date - 1`
and create a successor template. Tag changes use the same rule so historical
virtual occurrences are not regenerated with new tag assignments.

**Alternatives considered**:

- Mutate templates in place: rejected because past virtual windows would become
  historically inaccurate.
- Materialize all past occurrences before editing: rejected because it
  reintroduces unwanted bulk materialization.

## Decision: Overlay materialized tasks by both original and actual dates

**Rationale**: A moved task has an `occurrence_date` and a different `due_date`.
The list endpoint must suppress the original virtual occurrence and show the
materialized task on its actual due date.

**Alternatives considered**:

- Overlay only by `occurrence_date`: rejected because moved tasks can disappear
  from the target due-date window.
- Overlay only by `due_date`: rejected because the original virtual occurrence
  can duplicate the moved task.

## Decision: Cap task list windows

**Rationale**: Virtual recurrence generation needs a bounded workload. Requiring
`from` and `to`, validating order, and capping the window at 366 days protects
the API while still covering the assignment's 30-day and 90-day scenarios.

**Alternatives considered**:

- No maximum window: rejected because it leaves recurrence generation open to
  accidental abuse.
- Very small window such as 31 days: rejected because success criteria mention
  90-day validation.

## Decision: Use Discard for materialized Task history

**Rationale**: Physical `Task` records represent concrete work history.
Discarding them instead of hard deleting preserves history and makes it possible
to hide deleted instances from normal lists while retaining review/audit data.

**Alternatives considered**:

- Hard delete physical tasks: rejected because the user explicitly requested
  history preservation.
- Use Discard for every model: rejected because protected tags and templates have
  more specific lifecycle rules.

## Decision: Use discarded tasks as suppression markers

**Rationale**: If a discarded materialized task were ignored during generation,
the same recurrence date would reappear as a virtual occurrence. Loading all
materialized tasks, including discarded rows, lets the generator distinguish
three states: kept task means show physical task; discarded task means show
nothing; no task row means show virtual fallback.

**Alternatives considered**:

- Load only kept tasks: rejected because deleted occurrences would resurrect.
- Add a separate suppression table: rejected because Discard already leaves a
  durable row for the same template/date.

## Decision: Expose stable public task instance IDs

**Rationale**: Virtual occurrences have no database `tasks.id`, but the client
needs to list, retrieve, update, and delete them like ordinary tasks. The API
therefore exposes `id` as `tpl_<task_template_id>_<occurrence_date>`, which is
the existing occurrence key under a user-facing name. The physical database ID
stays internal.

**Alternatives considered**:

- Expose separate template/occurrence endpoints: rejected because it leaks the
  internal recurrence model into the public API.
- Materialize every listed occurrence to get a database ID: rejected because it
  violates the infinity and bounded materialization design.

## Decision: Separate cancellation from deletion

**Rationale**: Canceling an occurrence is visible business history, while
deleting an occurrence means hiding it from normal task lists. Canceling creates
or updates a kept physical task with `status: canceled`; deleting discards an
existing row or creates and discards a suppression marker.

**Alternatives considered**:

- Treat `status: canceled` as deletion: rejected because canceled work should be
  visible in history.
- Hard delete deleted occurrences: rejected because virtual fallback would
  resurrect them unless a separate suppression mechanism were added.

## Decision: Use a strict unique index for task instances

**Rationale**: One template/date must have one task row at most. This makes a
discarded row the canonical suppression marker and avoids ambiguous duplicates.

**Alternatives considered**:

- Partial unique index on kept rows only: rejected because it allows a new kept
  row next to a discarded suppression row for the same template/date.

## Decision: Attach tags to TaskTemplate

**Rationale**: Tags describe the user-defined task/series. Virtual and physical
instances should inherit the same tags from their template in API responses.

**Alternatives considered**:

- Attach tags to physical tasks: rejected because recurring virtual occurrences
  would not have rows to tag.
- Maintain separate template tags and task tags: rejected for v1 as unnecessary
  complexity.

## Decision: Use Rails API conventions with service objects for recurrence

**Rationale**: Rails models/controllers are sufficient for CRUD and tags, while
recurrence expansion/materialization is easier to test and reason about in
dedicated services.

**Alternatives considered**:

- Add a full calendar/recurrence gem: rejected for v1 because supported rules
  are limited and materialization behavior is custom.
- Put recurrence expansion directly in controllers: rejected because controller
  tests would become too broad and calendar logic would be harder to isolate.

## Decision: Use dry-validation contracts and operation forms

**Rationale**: The sibling `api-service` project uses a maintainable
controller -> form -> contract -> serializer flow. Mirroring that structure
keeps this assignment close to an existing production style: controllers remain
thin, dry-validation contracts own request shape/coercion/business validation,
forms orchestrate one operation, services hold reusable domain logic, and
serializers own public response shape.

**Alternatives considered**:

- Validate directly in controllers: rejected because recurrence, public task ID,
  tag, and date-window validation would make controllers broad and difficult to
  test.
- Put all request validation in Active Record models: rejected because API
  request concerns such as `effective_date`, recurrence payload shape, and
  public task IDs are not database fields.
- Use ActiveModel-only forms: viable, but dry-validation gives explicit
  coercion, nested contracts, reusable predicates, and a style already proven in
  the reference project.

## Decision: Use rswag/OpenAPI for Swagger documentation

**Rationale**: The repository must include Swagger documentation. An OpenAPI
contract under the feature directory can guide implementation, and rswag can
later expose Swagger UI and keep request specs close to the contract.

**Alternatives considered**:

- Handwritten README-only API docs: rejected because the assignment explicitly
  requires Swagger documentation.
- Generate docs after implementation only: rejected because API contract should
  guide implementation and tests.

## Decision: Use RSpec for the maintained test suite

**Rationale**: The maintained suite uses RSpec to match the intended project
structure and keep request, form, contract, serializer, model, and service
coverage in one consistent style.

**Alternatives considered**:

- Keep Minitest: viable for Rails defaults, but rejected after the project
  adopted RSpec as the single test stack before further implementation.
