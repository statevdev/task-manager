# Feature Specification: Task Tracker API

**Feature Branch**: `main` (local Git repository initialized)

**Created**: 2026-06-30

**Status**: Implemented

**Input**: User description: "Develop an API module for a medical staff task tracker with task CRUD, tags, recurring tasks, bounded recurrence listing, independent occurrence status, documentation, and local startup instructions."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manage Basic Tasks (Priority: P1)

A doctor or administrator can create, view, edit, delete, and list work tasks so
daily operational work can be tracked in one place.

**Why this priority**: Basic task management is the minimum useful product and
all later tag and recurrence behavior depends on it.

**Independent Test**: Create a task with a title, description, due date, and
status; retrieve it by ID; update it; list it with date/status filters; delete
it and verify it is no longer returned.

**Acceptance Scenarios**:

1. **Given** valid task details, **When** a staff member creates a task, **Then** the system stores the task and returns its details.
2. **Given** an existing task, **When** a staff member updates title, description, due date, or status, **Then** subsequent reads show the updated values.
3. **Given** tasks on different dates and statuses, **When** a staff member lists tasks with date and status filters, **Then** only matching tasks are returned.
4. **Given** an existing task, **When** a staff member deletes it, **Then** it is no longer returned by ID or list queries.

---

### User Story 2 - Organize Tasks With Tags (Priority: P2)

A staff member can assign multiple tags to a task and remove tags from a task so
tasks can be grouped by operational meaning such as reporting, operations, or
calls.

**Why this priority**: Tags make the tracker useful for medical workflows and
are explicitly required by the assignment.

**Independent Test**: Verify the required tags exist, attach several tags to a
task, remove one tag, and confirm protected tags cannot be edited or deleted.

**Acceptance Scenarios**:

1. **Given** the system has been initialized, **When** tags are listed or used, **Then** `отчетность`, `операции`, and `звонок` are available.
2. **Given** an existing task and existing tags, **When** tags are added to the task, **Then** the task includes all assigned tags.
3. **Given** a tagged task, **When** a tag is removed from that task, **Then** only that task-tag relation is removed and the tag remains available.
4. **Given** a required protected tag, **When** a staff member attempts to edit or delete it, **Then** the system rejects the operation.

---

### User Story 3 - Schedule Recurring Tasks (Priority: P3)

A staff member can define recurrence rules for routine tasks so repeated work is
visible in the tracker without manually creating every future occurrence.

**Why this priority**: Recurring medical work is a central business scenario and
requires deliberate design to avoid infinite task creation.

**Independent Test**: Create tasks with each supported recurrence type and list
tasks for bounded date windows to verify only expected occurrences are shown.

**Acceptance Scenarios**:

1. **Given** a task that repeats every second day, **When** a bounded date range is requested, **Then** only matching dates in that range are returned.
2. **Given** a task that repeats monthly on a selected day of month, **When** a bounded date range is requested, **Then** matching monthly occurrences are returned.
3. **Given** a task with specific scheduled dates, **When** a bounded date range is requested, **Then** only those dates inside the range are returned.
4. **Given** a task that repeats on even or odd days of month, **When** a bounded date range is requested, **Then** only dates with the selected parity are returned.

---

### User Story 4 - Track Status Per Recurring Occurrence (Priority: P4)

A staff member can mark one occurrence of a recurring task as completed,
pending, or canceled without changing the state of other dates in the same
series.

**Why this priority**: Independent occurrence state is explicitly called out as a
critical assignment requirement.

**Independent Test**: Create a recurring task, mark today's occurrence as
completed, and verify yesterday and tomorrow remain unchanged.

**Acceptance Scenarios**:

1. **Given** a recurring task visible on several dates, **When** one date is marked completed, **Then** only that date shows completed.
2. **Given** one completed occurrence, **When** the same series is listed for adjacent dates, **Then** adjacent occurrences retain their own statuses.
3. **Given** a recurring occurrence with a custom status, **When** the base recurrence is still active, **Then** future generated occurrences continue using `pending` unless changed.

---

### User Story 5 - Override One Recurring Occurrence (Priority: P5)

A staff member can cancel or move a single occurrence without changing the whole
recurring series.

**Why this priority**: This is a bonus requirement, but supporting it
demonstrates deeper handling of real calendar workflows.

**Independent Test**: Override one date in a recurring series and verify the
series continues normally before and after that date.

**Acceptance Scenarios**:

1. **Given** a recurring task, **When** one occurrence is canceled, **Then** it remains visible with status `canceled` only for that date.
2. **Given** a recurring task, **When** one occurrence is moved to a different due date, **Then** only that occurrence changes and the series rule remains unchanged.

---

### Edge Cases

- Creating a task without title or due date is rejected with validation errors; omitted status defaults to `pending`.
- Listing recurring tasks without a bounded date window is rejected or constrained to a documented safe default.
- Monthly recurrence on days 29, 30, or 31 skips months where that day does not exist.
- Daily recurrence interval must be a positive integer.
- Specific-date recurrence rejects duplicate or invalid dates.
- Even/odd recurrence is based on the day number within each month.
- Deleting a tag that is still assigned removes or prevents the operation according to documented behavior.
- Deleting a recurring series stops future appearances while preserving clear behavior for already customized occurrences.
- Deleting a recurring series sets `end_date` to today; because `end_date` is inclusive, past occurrences and today's occurrence remain available while future occurrences are hidden.
- Canceling an occurrence keeps it visible with `status: canceled`; deleting an occurrence hides it from normal lists and suppresses virtual fallback.
- Status filters apply consistently to both one-time tasks and recurring occurrences.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow staff to create a task with title, description, due date or recurrence start date, and optional recurrence settings.
- **FR-002**: System MUST allow staff to retrieve one task instance by stable public identifier.
- **FR-003**: System MUST allow staff to update task instance title, description, due date, and status.
- **FR-004**: System MUST allow staff to delete a task instance so it is hidden from normal lists.
- **FR-005**: System MUST allow staff to list tasks filtered by date or bounded date range.
- **FR-006**: System MUST allow staff to list tasks filtered by one or more statuses.
- **FR-007**: System MUST validate required task fields and return clear validation feedback.
- **FR-008**: System MUST support assigning multiple tags to one task.
- **FR-009**: System MUST support assigning one tag to multiple tasks.
- **FR-010**: System MUST support adding and removing tag assignments from a task.
- **FR-011**: System MUST ensure required tags `отчетность`, `операции`, and `звонок` exist after setup.
- **FR-012**: System MUST prevent editing or deleting required protected tags.
- **FR-013**: System MUST support daily recurrence every N days, where N is a positive integer.
- **FR-014**: System MUST support monthly recurrence on a selected day of month from 1 through 31.
- **FR-015**: System MUST support recurrence on explicit selected dates.
- **FR-016**: System MUST support recurrence on even or odd days of month.
- **FR-017**: System MUST list recurring task occurrences only for a bounded requested date window.
- **FR-018**: System MUST NOT require pre-creating all future occurrences for an open-ended recurring task.
- **FR-019**: System MUST allow status changes for a specific recurring occurrence without changing other occurrences in the same series.
- **FR-020**: System MUST expose a stable public task instance identifier in list responses using the `tpl_<template_id>_<occurrence_date>` format.
- **FR-021**: System SHOULD support canceling or moving one recurring occurrence without changing the whole series.
- **FR-022**: System MUST document local startup, assumptions, and available API operations for reviewers.
- **FR-023**: System MUST keep the LLM session history available in `HISTORY.md`.
- **FR-024**: System MUST keep internal task templates hidden behind the public `/tasks` API for normal task operations.

### Key Entities *(include if feature involves data)*

- **Task Template**: The internal task definition with title, description, recurrence type, schedule parameters, and tags.
- **Task**: A concrete execution instance for a specific date. It may be created immediately for one-time templates or materialized later for changed recurring occurrences.
- **Tag**: A reusable label that can be attached to many tasks; some tags are protected system tags.
- **Task Template Tag Assignment**: The many-to-many relationship between a task template and a tag.
- **Virtual Task Occurrence**: A task appearance generated from a template for a requested date window without a physical task row.
- **Materialized Task Occurrence**: A physical task row created when a one-time task is created, when a recurring occurrence is changed, or when a nearby instance must be persisted.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reviewer can create, read, update, delete, list, and filter basic tasks within 10 minutes using the documented interface.
- **SC-002**: Required protected tags are present after setup and all attempts to edit or delete them are rejected in validation tests.
- **SC-003**: For each supported recurrence type, a 30-day listing window returns exactly the expected occurrence dates in documented test cases.
- **SC-004**: Marking one recurring occurrence completed leaves adjacent occurrences unchanged in 100% of validation cases.
- **SC-005**: An open-ended recurring task can be listed for a 90-day window without requiring dates outside that window to be generated first.
- **SC-006**: Local startup instructions allow a reviewer to prepare the database and start the API without missing configuration steps.
- **SC-007**: API documentation covers public task operations, tags, recurrence, and materialization behavior before delivery.

## Assumptions

- Authentication and per-user authorization are out of scope for the first version unless added later.
- The primary actors are doctors and administrators using the tracker through an API client.
- Supported task statuses for the first version are `pending`, `completed`, and `canceled`.
- Every user-created task is stored as a task template. One-time templates also create one physical task immediately.
- Recurring task instances stay virtual until a specific instance is changed, canceled, completed, moved, or explicitly materialized.
- Public task IDs identify instances by template and occurrence date, for example `tpl_12_2026-07-01`.
- Date filters are inclusive.
- Recurring task list requests require a bounded date window; if a safe default is used, it must be documented.
- Monthly recurrence for a missing calendar day skips that month instead of moving to the last day.
- Closing a recurring template sets its end date to today instead of deleting historical data; today's occurrence remains valid because the end date is inclusive.
