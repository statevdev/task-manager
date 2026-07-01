# Task Manager API

Rails API application for a medical staff task tracker.

The source requirements are captured in [SPECS.md](SPECS.md). The LLM session history is captured in [HISTORY.md](HISTORY.md).

## Stack

- Ruby 3.4.3
- Rails 8.0.5 API mode
- PostgreSQL 16+
- Docker / Docker Compose

## Local Setup

Install dependencies:

```bash
BUNDLE_PATH=vendor/bundle bundle install
```

Run PostgreSQL 16 in Docker:

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
bin/rails db:prepare
```

Load required protected tags:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
bin/rails db:seed
```

Run the API:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
BUNDLE_PATH=vendor/bundle \
bin/rails server
```

Run tests:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
BUNDLE_PATH=vendor/bundle \
bundle exec rspec
```

## Docker Setup

For review startup with Rails and PostgreSQL together:

```bash
docker compose up --build
```

If your Docker installation uses the legacy Compose binary, run
`docker-compose up --build` instead.

The API will be available at `http://localhost:3000`.

Swagger UI will be available at `http://localhost:3000/api-docs`.

The generated `Dockerfile` is production-oriented. The compose file uses the
official Ruby image for a development-style review run.

## API Examples

Create a one-time task:

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Call patient","description":"Check condition","due_date":"2026-07-01"}'
```

Create a daily recurring task:

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Daily round","due_date":"2026-07-01","recurrence":{"type":"daily","interval":1,"end_date":"2026-07-07"}}'
```

List a bounded window:

```bash
curl "http://localhost:3000/api/v1/tasks?from=2026-07-01&to=2026-07-07"
```

## Project Notes

This project was initialized as a Rails API with PostgreSQL and no Git repository initialization.

Spec Kit workflow artifacts are stored in [specs/001-task-tracker-api](specs/001-task-tracker-api).

The application follows the reference `api-service` structure for request
handling: controller -> form -> dry-validation contract -> domain service ->
serializer. Shared call helpers live under `lib/`.

## Assumptions

- Authentication and per-user authorization are out of scope for the first version unless added later.
- The primary actors are doctors and administrators using the tracker through an API client.
- Supported task statuses for the first version are `pending`, `completed`, and `canceled`.
- The public API exposes task instances through `/api/v1/tasks`; `TaskTemplate` is an internal persistence and recurrence mechanism.
- Public task IDs use the `tpl_<task_template_id>_<occurrence_date>` format and work for both virtual and materialized occurrences.
- One-time templates create one physical `Task` immediately.
- Recurring templates generate virtual task instances for bounded date windows and materialize physical `Task` rows only when a specific instance changes or must be persisted.
- Recurring task creation accepts omitted `status` or `status: pending`; `completed` and `canceled` are rejected at creation so the first occurrence is not materialized implicitly.
- Canceling an occurrence keeps it visible with `status: canceled`; deleting an occurrence hides it from normal lists and suppresses virtual fallback.
- Date filters are inclusive.
- Recurring task list requests require a bounded date window; if a safe default is used, it must be documented.
- Monthly recurrence for a missing calendar day skips that month instead of moving to the last day.
- Recurring series deletion closes the internal template through `end_date = Date.current`; because `end_date` is inclusive, past and today's occurrences remain valid while future occurrences stop.
