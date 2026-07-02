# Task Manager API

Rails API-приложение для трекера рабочих задач медицинского персонала.

Исходные требования сохранены в [SPECS.md](SPECS.md). История работы с LLM сохранена в [HISTORY.md](HISTORY.md).

## Стек

- Ruby 3.4.3
- Rails 8.0.5 в API mode
- PostgreSQL 16+
- Docker / Docker Compose

## Локальный запуск

Установите зависимости:

```bash
BUNDLE_PATH=vendor/bundle bundle install
```

Запустите PostgreSQL 16 в Docker:

```bash
docker run -d --name task_manager_db \
  -e POSTGRES_DB=task_manager_development \
  -e POSTGRES_USER=task_manager \
  -e POSTGRES_PASSWORD=task_manager_password \
  -p 5432:5432 \
  postgres:16
```

Подготовьте базу данных:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
bin/rails db:prepare
```

Загрузите обязательные защищенные теги:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
bin/rails db:seed
```

Запустите API:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
BUNDLE_PATH=vendor/bundle \
bin/rails server
```

Запустите тесты:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
BUNDLE_PATH=vendor/bundle \
bundle exec rspec
```

## Проверки качества

Перед сдачей использовались следующие проверки:

```bash
DATABASE_HOST=localhost \
DATABASE_USERNAME=task_manager \
DATABASE_PASSWORD=task_manager_password \
BUNDLE_PATH=vendor/bundle \
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
ruby -ryaml -e 'YAML.load_file("specs/001-task-tracker-api/contracts/openapi.yaml"); YAML.load_file("swagger/v1/openapi.yaml"); YAML.load_file("docker-compose.yml")'
```

## Запуск через Docker

Для быстрого проверочного запуска Rails и PostgreSQL вместе:

```bash
docker compose up --build
```

Если у вас установлен старый бинарный файл Compose, используйте
`docker-compose up --build`.

API будет доступно по адресу `http://localhost:3000`.

Swagger UI будет доступен по адресу `http://localhost:3000/api-docs`.

Сгенерированный `Dockerfile` ориентирован на production-сборку. `docker-compose.yml`
использует официальный Ruby image для проверочного запуска в development-режиме.

## Примеры API

Создать одноразовую задачу:

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Позвонить пациенту","description":"Уточнить самочувствие","due_date":"2026-07-01"}'
```

Создать ежедневную повторяющуюся задачу:

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Ежедневный обход","due_date":"2026-07-01","recurrence":{"type":"daily","interval":1,"end_date":"2026-07-07"}}'
```

Получить список задач за ограниченное временное окно:

```bash
curl "http://localhost:3000/api/v1/tasks?from=2026-07-01&to=2026-07-07"
```

## Заметки по проекту

Проект был инициализирован как Rails API с PostgreSQL. Git-репозиторий был
добавлен позднее локально, без remote.

Артефакты workflow Spec Kit находятся в [specs/001-task-tracker-api](specs/001-task-tracker-api).

Приложение следует структуре reference-проекта `api-service` для обработки
запросов: controller -> form -> dry-validation contract -> domain service ->
serializer. Общие callable helpers находятся в `lib/`.

## Допущения

- Аутентификация и per-user авторизация не входят в первую версию, если не будут добавлены отдельно.
- Основные пользователи API - врачи и администраторы, работающие с трекером через API-клиент.
- Поддерживаемые статусы задач в первой версии: `pending`, `completed`, `canceled`.
- Публичное API показывает экземпляры задач через `/api/v1/tasks`; `TaskTemplate` остается внутренним механизмом хранения и повторяемости.
- Публичные ID задач используют формат `tpl_<task_template_id>_<occurrence_date>` и работают как для виртуальных, так и для материализованных экземпляров.
- Одноразовые шаблоны сразу создают одну физическую запись `Task`.
- Для повторяющихся задач `due_date` в запросе создания считается датой старта правила; ответ содержит первый сгенерированный экземпляр на эту дату или после нее.
- Повторяющиеся шаблоны генерируют виртуальные экземпляры задач для ограниченных временных окон и материализуют физические строки `Task` только при изменении конкретного экземпляра или необходимости сохранить его состояние.
- При создании повторяющейся задачи допускается отсутствующий `status` или `status: pending`; `completed` и `canceled` отклоняются, чтобы не материализовать первый экземпляр неявно.
- Отмена экземпляра оставляет его видимым со статусом `canceled`; удаление экземпляра скрывает его из обычных списков и подавляет виртуальный fallback.
- Фильтры по датам включают обе границы.
- Для получения списка повторяющихся задач требуется ограниченное временное окно; если используется безопасное значение по умолчанию, оно должно быть задокументировано.
- Ежемесячное повторение для отсутствующего календарного дня пропускает такой месяц, а не переносится на последний день месяца.
- Удаление повторяющейся серии закрывает внутренний шаблон через `end_date = Date.current`; поскольку `end_date` включительная, прошлые экземпляры и экземпляр за сегодняшний день остаются валидными, а будущие прекращаются.
