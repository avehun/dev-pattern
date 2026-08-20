# Рабочий процесс

Сквозной прогон одной фичи и два режима передачи задач.

## Установка в проект

```bash
git clone https://github.com/avehun/dev-pattern.git ~/dev-pattern
cd /путь/к/проекту
bash ~/dev-pattern/scripts/init.sh .
```

Инсталлятор **никогда не затирает** существующие файлы: если `CLAUDE.md` уже есть,
рядом появится `CLAUDE.dev-pattern.md`, и вы сольёте руками. Посмотреть, что произойдёт,
не записывая ничего:

```bash
bash ~/dev-pattern/scripts/init.sh . --dry-run
```

Дальше обязательный шаг: заполнить `docs/constitution.md` (quality gates) и
`docs/stack.md` (команды). От них зависит поле `verify` в каждой карточке — с
плейсхолдерами процесс не поедет, и `doctor.sh` про это скажет.

```bash
bash scripts/doctor.sh
```

## Сквозной прогон

### Шаг 1–4: лид готовит работу

В Claude Code, в корне проекта:

```
/dp:research обновление токенов
/dp:spec token-refresh
/dp:plan
/dp:tasks
```

После этого в репозитории появилось:

```
docs/specs/001-token-refresh/
├── research.md   plan.md   spec.md   data-model.md
├── contracts/    quickstart.md   checklist.md   tasks.md
└── tasks/T-001.md  T-002.md  T-003.md
```

Посмотреть доску в любой момент:

```bash
bash scripts/status.sh
```

```
001-token-refresh  Token refresh  [spec: ready]  0/3 tasks done
  todo               T-001      Add refresh() to AuthClient
  todo               T-002      Persist refresh token
  todo               T-003      Retry-once middleware   (needs: T-001)

Ready to delegate: T-001 T-002
```

### Шаг 5: передача задачи исполнителю

#### Режим A — полуавтомат (по умолчанию)

```
/dp:delegate T-001
```

Лид валидирует карточку и печатает готовую команду. Вы запускаете её сами:

```bash
bash scripts/delegate.sh T-001
```

opencode стартует, спрашивает подтверждение на каждую правку — вы видите всё, что он
делает. Это режим по умолчанию: бесплатные модели непредсказуемы, а лимиты не бесконечны.

#### Режим B — автомат

```
/dp:delegate T-001 --run --auto
```

Лид сам запускает `scripts/delegate.sh T-001 --auto`, ждёт результата и докладывает, что
изменилось. `--auto` разрешает правки без вопросов, но **`deny`-правила из `opencode.json`
продолжают действовать**: за `allowed_paths` и в `docs/` он всё равно не попадёт, git
всё равно недоступен.

Лид никогда не добавляет `--auto` сам — только если вы его попросили.

#### Что делает `delegate.sh`

1. Проверяет карточку: статус, зависимости (`depends_on` все `done`), наличие
   `verify` и `allowed_paths`, счётчик попыток, отсутствие отсылок «смотри план».
2. Создаёт ветку `task/T-001` (или worktree при `--worktree`).
3. Ставит `status: in_progress`, инкрементирует `attempt`.
4. Запускает `opencode run --agent implementer -f <карточка> "<задание>"`.
5. По завершении ставит `status: in_review` и показывает `git diff --stat`.

Проверить команду, ничего не запуская:

```bash
bash scripts/delegate.sh T-001 --dry-run
```

### Параллельная работа

Задачи без взаимных зависимостей можно гнать одновременно в изолированных worktree:

```bash
bash scripts/delegate.sh T-001 --worktree &
bash scripts/delegate.sh T-002 --worktree &
```

Каждая получит свою копию рабочего дерева в `.worktrees/T-00X` и свою ветку. Без
`--worktree` задачи выполняются последовательно — иначе они затрут правки друг друга.

### Шаг 6: ревью

```
/dp:review T-001
```

Лид сам гоняет `verify` и гейты, проверяет критерии приёмки и границы, пишет
`reviews/T-001.md` с вердиктом.

При `changes_requested` — доработка агентом `fixer`, которому findings отдаются
приложенным файлом:

```bash
bash scripts/delegate.sh T-001 --agent fixer --review
```

`fixer` чинит **только** пронумерованные findings и дописывает в отчёт секцию
`## Attempt 2`.

При `attempt >= 2` `delegate.sh` откажется запускаться: это сигнал эскалации.
Лид дробит карточку на две-три или берёт задачу себе, записав причину в `tasks.md`.

### Шаг 7: приёмка

```
/dp:accept T-001
```

Гейты, коммит `T-001: <название>`, мерж ветки, `status: done`, обновление доски и
затронутых документов.

## Состояния карточки

```
   todo ──► in_progress ──► in_review ──┬──► done
     ▲            │                     │
     │            ▼                     ▼
     │        blocked           changes_requested
     │                                  │
     └──────────── fixer ◄──────────────┘
                    │
                    ▼  attempt >= 2
                escalated ──► лид дробит карточку или делает сам
```

| Статус | Кто ставит | Что значит |
| --- | --- | --- |
| `todo` | лид | готова к делегированию |
| `in_progress` | `delegate.sh` | исполнитель работает |
| `in_review` | `delegate.sh` | работа сдана, ждёт лида |
| `changes_requested` | лид | есть findings, нужен `fixer` |
| `blocked` | исполнитель | карточка неполна, нужен лид |
| `escalated` | лид | две неудачные попытки |
| `done` | лид | принято и закоммичено |

## Шпаргалка

```bash
bash scripts/doctor.sh                       # всё ли настроено
bash scripts/status.sh                       # доска задач
bash scripts/new-feature.sh <слаг>           # новая фича из шаблонов
bash scripts/delegate.sh T-001 --dry-run     # что будет запущено
bash scripts/delegate.sh T-001               # полуавтомат
bash scripts/delegate.sh T-001 --auto        # автомат
bash scripts/delegate.sh T-001 --worktree    # в изолированном worktree
bash scripts/delegate.sh T-001 --agent fixer --review   # доработка по ревью
```

См. также: [Методология](methodology.md) · [Карточки задач](task-cards.md) ·
[Настройка opencode](setup-opencode.md)
