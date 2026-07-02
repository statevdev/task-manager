# Task Manager API

Rails API для трекера рабочих задач медицинского персонала: врачи и
администраторы могут создавать задачи, назначать теги, работать с повторяемыми
задачами и менять состояние отдельных повторений.

Исходное тестовое задание сохранено в [SPECS.md](SPECS.md). История работы с
LLM сохранена в [HISTORY.md](HISTORY.md).

## Стек

- Ruby 3.4.3
- Ruby on Rails 8.0.5, API mode
- PostgreSQL 16
- dry-validation для валидации входных API-параметров
- discard для soft-delete материализованных экземпляров задач
- rswag / OpenAPI для Swagger-документации
- RSpec для тестов
- RuboCop Rails Omakase и Brakeman для статических проверок
- Docker / Docker Compose для быстрого локального запуска
- Spec Kit для проектных артефактов в `specs/001-task-tracker-api`

## Возможности

- CRUD задач через публичный API `/api/v1/tasks`.
- Фильтрация списка задач по диапазону дат, статусам и тегам.
- Теги задач, включая защищенные системные теги `отчетность`, `операции` и
  `звонок`.
- Повторяемые задачи без создания записей на годы вперед.
- Поддерживаемая периодичность:
  - один раз;
  - каждые N дней;
  - каждый месяц в указанное число;
  - на конкретные даты;
  - по четным или нечетным дням месяца.
- Независимый статус конкретного повторения: `pending`, `completed`,
  `canceled`.
- Отмена, перенос и удаление отдельного повторения.
- Закрытие повторяемой серии без удаления истории.

## Локальный запуск

Установите зависимости:

```bash
bundle install
```

Запустите PostgreSQL 16:

```bash
docker compose up -d db
```

Если у вас установлен старый бинарный файл Compose:

```bash
docker-compose up -d db
```

Подготовьте базу данных и обязательные теги:

```bash
bin/rails db:prepare
bin/rails db:seed
```

Перед первым запуском тестов подготовьте тестовую базу:

```bash
bin/rails db:test:prepare
```

Запустите API:

```bash
bin/rails server
```

API будет доступно по адресу `http://localhost:3000`.

Swagger UI будет доступен по адресу `http://localhost:3000/api-docs`.

Локальные настройки подключения к базе уже согласованы с сервисом `db` из
`docker-compose.yml`. При необходимости их можно переопределить стандартными
переменными окружения `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`,
`DATABASE_USERNAME` и `DATABASE_PASSWORD`.

## Запуск целиком в Docker

Для проверочного запуска Rails и PostgreSQL вместе:

```bash
docker compose up --build
```

Fallback для старого Compose:

```bash
docker-compose up --build
```

## Документация API

- Swagger UI: `http://localhost:3000/api-docs`
- OpenAPI contract для Spec Kit:
  [specs/001-task-tracker-api/contracts/openapi.yaml](specs/001-task-tracker-api/contracts/openapi.yaml)
- OpenAPI файл для rswag:
  [swagger/v1/openapi.yaml](swagger/v1/openapi.yaml)

## Основные endpoint'ы

| Метод | Endpoint | Назначение |
| --- | --- | --- |
| `GET` | `/api/v1/tasks` | Список задач за диапазон дат |
| `POST` | `/api/v1/tasks` | Создание одноразовой или повторяемой задачи |
| `GET` | `/api/v1/tasks/:id` | Получение задачи по публичному ID |
| `PATCH` | `/api/v1/tasks/:id` | Изменение задачи или отдельного повторения |
| `DELETE` | `/api/v1/tasks/:id` | Скрытие задачи или отдельного повторения |
| `DELETE` | `/api/v1/tasks/:id/series` | Закрытие повторяемой серии |
| `GET` | `/api/v1/tags` | Список тегов |
| `POST` | `/api/v1/tags` | Создание тега |
| `PATCH` | `/api/v1/tags/:id` | Переименование тега |
| `DELETE` | `/api/v1/tags/:id` | Удаление тега |
| `POST` | `/api/v1/tasks/:task_id/tags` | Добавление тегов к задаче |
| `DELETE` | `/api/v1/tasks/:task_id/tags/:id` | Удаление тега с задачи |

Публичный ID задачи имеет вид `tpl_<template_id>_<occurrence_date>`, например
`tpl_12_2026-07-01`. Такой ID используется и для сохраненных задач, и для
виртуальных повторений.

## Примеры API

Создать одноразовую задачу:

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Позвонить пациенту","description":"Уточнить самочувствие","due_date":"2026-07-01"}'
```

Создать ежедневную повторяемую задачу:

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Ежедневный обход","due_date":"2026-07-01","recurrence":{"type":"daily","interval":1,"end_date":"2026-07-07"}}'
```

Получить список задач за ограниченное временное окно:

```bash
curl "http://localhost:3000/api/v1/tasks?from=2026-07-01&to=2026-07-07"
```

Отметить одно повторение выполненным:

```bash
curl -X PATCH http://localhost:3000/api/v1/tasks/tpl_1_2026-07-02 \
  -H "Content-Type: application/json" \
  -d '{"status":"completed"}'
```

## Допущения

- Аутентификация и per-user авторизация не входят в первую версию.
- Основные пользователи API - врачи и администраторы.
- Поддерживаемые статусы задач: `pending`, `completed`, `canceled`.
- Фильтры по датам включают обе границы.
- Для списка повторяемых задач требуется ограниченное временное окно.
- Для повторяемых задач `due_date` в запросе создания считается датой старта
  правила; ответ содержит первый сгенерированный экземпляр на эту дату или
  после нее.
- Ежемесячное повторение для отсутствующего календарного дня пропускает такой
  месяц, а не переносится на последний день месяца.
- Отмена экземпляра оставляет его видимым со статусом `canceled`; удаление
  экземпляра скрывает его из обычных списков.
- Удаление повторяемой серии закрывает ее с сегодняшнего дня включительно:
  прошлые экземпляры и экземпляр за сегодня остаются доступными, будущие
  скрываются.
