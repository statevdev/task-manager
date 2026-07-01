# Quickstart: Task Tracker API

This guide validates the feature end-to-end once implementation tasks are
complete.

## Prerequisites

- Ruby 3.4.x
- PostgreSQL 16+
- Bundler
- Docker, if using the local PostgreSQL container

## Setup

Install dependencies:

```bash
BUNDLE_PATH=vendor/bundle bundle install
```

Start PostgreSQL 16 in Docker:

```bash
docker run -d --name task_manager_db \
  -e POSTGRES_DB=task_manager_development \
  -e POSTGRES_USER=task_manager \
  -e POSTGRES_PASSWORD=task_manager_password \
  -p 5432:5432 \
  postgres:16
```

Prepare the database:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
BUNDLE_PATH=vendor/bundle \
bundle exec rails db:prepare
```

Load required protected tags:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
BUNDLE_PATH=vendor/bundle \
bundle exec rails db:seed
```

Run the test suite:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
BUNDLE_PATH=vendor/bundle \
bundle exec rspec
```

Start the API:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
BUNDLE_PATH=vendor/bundle \
bundle exec rails server
```

## Validation Scenarios

### Example Requests

Create a one-time task:

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Call patient","description":"Check condition","due_date":"2026-07-01"}'
```

Create a recurring daily task:

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Daily round","due_date":"2026-07-01","recurrence":{"type":"daily","interval":1,"end_date":"2026-07-07"}}'
```

List a bounded occurrence window:

```bash
curl "http://localhost:3000/api/v1/tasks?from=2026-07-01&to=2026-07-07"
```

Swagger UI is exposed at `http://localhost:3000/api-docs`.

### 1. One-Time Task

1. Create a one-time task with `POST /api/v1/tasks`.
2. Verify the response includes a public ID such as `tpl_12_2026-07-01`.
3. Retrieve the task through `GET /api/v1/tasks/:id`.
4. List tasks for the task date.

Expected outcome: one-time creation produces a durable template and one physical
task instance.

### 2. Public Task CRUD

1. Create a recurring task with `POST /api/v1/tasks`.
2. Retrieve the returned public task ID.
3. Update title, description, due date, status, or tags through
   `PATCH /api/v1/tasks/:id`.
4. Delete the task occurrence through `DELETE /api/v1/tasks/:id`.
5. List the same date window after deletion.

Expected outcome: the public API behaves like normal task CRUD even when the
server internally materializes or suppresses a virtual occurrence.

### 3. Protected Tags

1. Prepare or seed the database.
2. List tags and verify `отчетность`, `операции`, and `звонок` exist.
3. Attach protected tags to a task.
4. Remove a tag from one task.
5. Attempt to edit or delete a protected tag.

Expected outcome: assignments can change, protected tag records cannot be
edited or deleted.

### 4. Recurrence Window Listing

1. Create a daily recurring task.
2. Create a monthly recurring task.
3. Create a specific-date recurring task.
4. Create an even-day or odd-day recurring task.
5. Request a 30-day task list window.

Expected outcome: list responses include virtual occurrences only inside the
requested window and do not create physical future rows.

### 5. Occurrence Materialization

1. Create a recurring task visible on several dates.
2. Update one virtual occurrence status to `completed`.
3. Request the same date window again.
4. Inspect the database or response metadata.

Expected outcome: only the changed date has a physical `Task`; adjacent
occurrences remain virtual and unchanged.

### 6. Move and Cancel One Occurrence

1. Create a recurring task.
2. Cancel one occurrence.
3. Move another occurrence to a different due date.
4. Request windows covering the original and moved dates.

Expected outcome: only the selected occurrences are materialized and affected;
the template recurrence continues normally.

### 7. Delete Occurrence

1. Create a recurring task.
2. Delete a visible occurrence by its public task ID.
3. List the same window normally.
4. Verify the discarded row remains available for history-oriented checks.

Expected outcome: normal lists hide the deleted occurrence, virtual fallback is
suppressed, and history is preserved.

### 8. Prospective Template Revision

1. Create a recurring task with a start date in the past.
2. Request a window before today and record the generated title and dates.
3. Update the series title, tags, or recurrence parameters with no explicit
   `effective_date`.
4. Request a past window and a future window.

Expected outcome: the past window still uses the old template, and the future
window uses the successor template.

### 9. Moved Occurrence Overlay

1. Create a recurring task that generates an occurrence on date A.
2. Move that occurrence to date B.
3. Request a one-day window for date A.
4. Request a one-day window for date B.

Expected outcome: date A does not show the original virtual occurrence, and date
B shows the materialized moved task.

### 10. Close Series With Future Materialized Tasks

1. Create a recurring task.
2. Materialize a future occurrence.
3. Delete or close the series.
4. Request a future window that would include that materialized occurrence.

Expected outcome: the future materialized task is discarded and no future
virtual occurrences are generated.

## Contract Reference

OpenAPI contract: [contracts/openapi.yaml](contracts/openapi.yaml)

Data model: [data-model.md](data-model.md)
