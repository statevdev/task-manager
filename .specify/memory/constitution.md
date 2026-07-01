<!--
Sync Impact Report
Version change: 0.0.0 -> 1.0.0
Modified principles: N/A, initial constitution adoption
Added sections: Technical Constraints; Development Workflow and Quality Gates
Removed sections: N/A
Templates requiring updates:
- updated: .specify/templates/plan-template.md
- updated: .specify/templates/tasks-template.md
- reviewed: .specify/templates/spec-template.md
- reviewed: README.md
Follow-up TODOs: None
-->
# Task Manager API Constitution

## Core Principles

### I. API Contract First
Every user-facing capability MUST be exposed through a clear JSON API contract.
Endpoints MUST use predictable resource naming, request and response shapes,
status codes, and validation errors. Swagger/OpenAPI documentation MUST be kept
current with implemented behavior.

### II. Calendar Correctness
Task due dates, recurrence rules, and occurrence windows MUST be modeled
explicitly. Recurring tasks MUST NOT be materialized unboundedly. Lists MUST be
generated for bounded date windows, and behavior for invalid or out-of-range
dates MUST be documented.

### III. Occurrence State Isolation
Status changes on a recurring task occurrence MUST apply only to that occurrence.
The canonical recurrence definition MUST remain distinct from per-date occurrence
state, overrides, and cancellations.

### IV. Testable Rails API Changes
Behavioral changes MUST include automated tests before implementation is
considered complete. API behavior MUST be covered with request or integration
tests; recurrence logic MUST have focused unit, model, or service tests; seed and
protected-tag behavior MUST be tested.

### V. Operational Simplicity and Documentation
The solution MUST remain small and understandable for a junior+ Rails API test
task. README, local setup, Docker/PostgreSQL instructions, assumptions, and LLM
history MUST remain accurate. Complexity in recurrence design MUST be justified
in the feature plan.

## Technical Constraints

- Runtime target is Ruby 3.4.x or newer.
- The application is a Ruby on Rails API backed by PostgreSQL 16 or newer.
- The project MUST use PostgreSQL for development and test data persistence.
- Docker or Docker Compose support SHOULD be kept runnable for quick review.
- Required immutable seed tags are `отчетность`, `операции`, and `звонок`; they
  MUST NOT be edited or deleted through the API.
- Swagger/OpenAPI documentation MUST be present before the task is considered
  complete.
- `README.md` MUST document assumptions where the source task is intentionally
  underspecified.

## Development Workflow and Quality Gates

- Specs MUST describe product behavior without implementation details;
  implementation details belong in plans.
- Plans MUST call out the recurrence storage strategy, bounded listing strategy,
  per-occurrence status strategy, and optional override strategy.
- Tasks MUST be organized by independently testable user stories.
- Tests MUST be created or updated alongside each user story.
- Database migrations, seed data, API controllers, response shapes, and Swagger
  docs MUST be traceable to requirements.
- Before completion, run the available automated test suite and static checks, or
  document why a check could not be run.

## Governance

This constitution supersedes conflicting local habits for this repository.
Amendments require updating this file, incrementing the version using semantic
versioning, and reviewing dependent Spec Kit templates. A feature may not move
from planning to implementation while a Constitution Check violation is
unresolved unless the violation is recorded with rationale and a simpler
alternative considered.

Versioning policy:

- MAJOR for incompatible changes to principles or quality gates.
- MINOR for added principles, sections, or materially expanded requirements.
- PATCH for wording clarifications that do not change obligations.

All future Spec Kit specs, plans, and tasks MUST be reviewed against these
principles.

**Version**: 1.0.0 | **Ratified**: 2026-06-30 | **Last Amended**: 2026-06-30
