# CLAUDE.md — работа над самим dev-pattern

Это репозиторий-маркетплейс с одним плагином Claude Code, а не приложение. Прод-кода нет:
только плагин (инструкции, хуки, bash-инструменты) и документация.

## Раскладка

| Путь | Что это | Язык |
| --- | --- | --- |
| `README.md`, `docs/*.md` | объяснения для человека | русский |
| `.claude-plugin/marketplace.json` | маркетплейс | — |
| `plugins/dev-pattern/` | сам плагин | английский |
| `plugins/dev-pattern/rules.md` | правила, которые SessionStart-хук подставляет в каждую сессию | английский |
| `plugins/dev-pattern/scripts/` | код хуков (`guard.sh`, `session-start.sh`, `stop-docs.sh`) и `lib.sh` | — |
| `plugins/dev-pattern/bin/` | `dp-setup`, `dp-uninstall`, `dp-kb-stale`, `dp-docs-waive` — в PATH у Claude | — |
| `docs/plans/` | планы работы над этим репозиторием | русский |
| `scripts/check.sh` | самопроверка | — |

Основная сессия в проекте пользователя — Opus (`dp-setup` пишет `model: opus`), сабагенты
`researcher` и `worker` — Sonnet. Их границы держит `guard.sh`, а не промпты.

## Правила

- Машиночитаемое — по-английски: `rules.md`, агенты, скиллы, стили, шаблоны.
  Объяснения для человека — по-русски.
- `rules.md` подставляется в каждую сессию: каждая строка оплачивается всегда. Держите его
  коротким (`check.sh` требует < 4000 байт).
- Меняете `guard.sh` — обновите таблицу в `docs/agents.md` и тесты в разделе 3 `check.sh`.
- Меняете логику `stop-docs.sh` (что считается кодом/документацией) — обновите таблицу в
  `docs/workflow.md` и раздел 5 `check.sh`.
- Меняете `dp-setup`/`dp-uninstall` — раздел 6 `check.sh` обязан доказывать, что установка
  с последующим удалением оставляет чужой репозиторий байт в байт прежним.
- Агенты держат `model: sonnet` — это проверяет `check.sh`.
- Хуки — fail-open: `set -uo pipefail` без `-e`, любая внутренняя ошибка → `exit 0`.
  Инструменты в `bin/` — `set -euo pipefail`. Осторожно с `cond && cmd` на одной строке под
  `set -e`: пишите `if … then … fi`.
- Зависимости: `bash`, `git` (2.31+), `jq`, `awk`, `sed`. Больше ничего не добавлять.
- Хуки молчат в проектах без `docs/dp/knowledge/INDEX.md` — плагин может быть включён
  глобально, и это не должно влиять на чужие репозитории.

## Проверка перед коммитом

```bash
bash scripts/check.sh                          # структура, claude plugin validate,
                                                # живые тесты хуков, bin/ и setup/uninstall
claude --plugin-dir plugins/dev-pattern        # ручной прогон плагина без установки
```

`check.sh` обязан быть зелёным.
