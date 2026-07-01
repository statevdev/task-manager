# QA Report: Task Tracker API

**Date**: 2026-07-01
**Scope**: public task API behavior around task creation, recurrence, tags,
updates, deletion, and user-facing edge cases.

## Проверенные зоны риска

- PATCH одноразовой задачи с `tag_ids`.
- PATCH одноразовой задачи с recurrence-полями.
- PATCH recurring-задачи с пустым `recurrence`.
- PATCH recurring-задачи только с `effective_date`.
- DELETE связи задачи с несуществующим тегом.
- POST recurring-задачи, где `due_date` является стартом правила, но не самим
  generated occurrence.
- POST recurrence-правила, которое не может породить ни одного occurrence.
- POST recurrence-правила с нерелевантными параметрами для выбранного типа.

## Найденные и закрытые проблемы

- PATCH одноразовой задачи с `tag_ids` раньше проходил успешно, но не менял
  теги. Теперь теги обновляются через связанный `TaskTemplate`.
- PATCH одноразовой задачи с `recurrence` или `effective_date` раньше мог быть
  silently ignored. Теперь API возвращает `422`.
- PATCH recurring-задачи с пустым `recurrence` или только `effective_date`
  раньше создавал successor template без реальных изменений. Теперь API
  возвращает `422`.
- DELETE `/tasks/:id/tags/:tag_id` с несуществующим тегом раньше возвращал
  успешный ответ. Теперь API возвращает `404`.
- POST monthly/specific_dates/day_parity recurring-задачи раньше мог вернуть
  "ghost" instance на `due_date`, даже если recurrence-правило эту дату не
  генерировало. Теперь `due_date` трактуется как дата старта правила, а ответ
  содержит первый реально сгенерированный occurrence на эту дату или после нее.
- Recurrence payload с нерелевантными параметрами раньше мог сохранить лишние
  rule-поля. Теперь contract и model validation отклоняют такие payload.

## Регрессионное покрытие

Добавлен request spec:

- `spec/requests/api/v1/qa_edge_cases_spec.rb`

## Итоговые проверки

- `bundle exec rspec`: 54 examples, 0 failures.
- `bundle exec rubocop`: no offenses.
- `bundle exec brakeman --no-pager`: 0 security warnings.
- YAML parse для OpenAPI, Docker Compose и GitHub Actions: успешно.
