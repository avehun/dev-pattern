# Карточки задач

Карточка — единственный канал связи между лидом и исполнителем. Всё, чего в ней нет,
для исполнителя не существует: он не ходит в сеть, не изучает репозиторий и не помнит
предыдущих задач.

Шаблон: `docs/.templates/task-card.md`.

## Анатомия

```yaml
---
id: T-003
feature: 001-token-refresh
title: Add token refresh to AuthClient
status: todo
depends_on: [T-001]
attempt: 0
agent: implementer
model: opencode/big-pickle
allowed_paths:
  - src/auth/client.ts
  - src/auth/client.test.ts
verify: "npm test -- src/auth"
---
```

| Поле | Зачем |
| --- | --- |
| `id` | ссылка из `tasks.md`, ревью, отчёта, коммита |
| `depends_on` | `delegate.sh` не запустит задачу, пока зависимости не `done` |
| `attempt` | инкрементируется автоматически; `>= 2` блокирует запуск и требует эскалации |
| `agent` | `implementer` — код, `test-writer` — только тесты, `fixer` — доработка по ревью |
| `model` | можно ставить модель под сложность задачи |
| `allowed_paths` | границы задачи; всё за их пределами — проваленное ревью |
| `verify` | ровно одна команда, определяющая «готово» |

Тело карточки: `Goal` · `Context` · `Files you may touch` · `Step-by-step` ·
`Acceptance criteria` · `How to verify` · `Out of scope — do NOT` · `When you are done` ·
`If you get stuck`.

## Семь правил

### 1. Одна карточка — ≤ 3 файла и ≤ ~200 строк диффа

Не потому что модель не осилит больше текста, а потому что качество падает нелинейно:
на пятом файле она забывает, что решила на первом. Крупная задача дробится, даже если
дробление выглядит искусственно.

### 2. Context — самодостаточен

Плохо:

> Добавь метод refresh по образцу существующих методов клиента.

Хорошо:

> Класс `AuthClient` в `src/auth/client.ts`:
> ```ts
> export class AuthClient {
>   constructor(private http: HttpClient, private store: TokenStore) {}
>   async login(email: string, password: string): Promise<Session> { … }
> }
> ```
> `TokenStore` (`src/auth/store.ts`) даёт `get(): Token | null` и `set(t: Token): void`.
> `Token` — это `{ access: string; refresh: string; expiresAt: number }`.
> Эндпоинт: `POST /auth/refresh`, тело `{ refresh }`, ответ — тот же `Token`.
> На 401 сервер возвращает `{ error: "invalid_refresh" }`.

Вставляйте фактические сигнатуры, типы, константы, тексты ошибок и кусок соседнего кода
как образец стиля. Да, это дублирование. Оно окупается первым же непроваленным ревью.

### 3. Никаких отсылок к другим документам

`«см. plan.md»`, `«следуй паттерну из репозитория»`, `«изучи как сделано в X»` —
это не постановка. `delegate.sh` предупреждает, когда находит такие формулировки.

### 4. `allowed_paths` — точные пути

Никаких `src/auth/*`. Перечисляются конкретные файлы, включая те, которые будут созданы.
Список — это и граница, и чек-лист для ревью: `git diff --name-only` должен совпасть.

### 5. Ровно одна команда `verify`

Она должна **уже работать** в репозитории — проверьте её сами перед делегированием.
Если команду назвать невозможно, задача не готова к делегированию: непонятно, по какому
признаку исполнитель поймёт, что закончил.

Плохо: `npm test` на весь проект (долго, шумно, чужие падения).
Хорошо: `npm test -- src/auth` — узко и быстро.

### 6. «Out of scope — do NOT» пишется явно

Слабые модели заполняют тишину инициативой. Явный список запретов дешевле, чем ревью,
на котором вы обнаружите отрефакторенный половину модуля.

Базовый набор уже в шаблоне: не трогать зависимости, не рефакторить вне `allowed_paths`,
не лезть в `docs/` и конфиги, не запускать git, не «улучшать» прочитанное попутно.

### 7. Критерии приёмки — по ID из спеки

`AC-1`, `AC-2` копируются из `spec.md`. Тогда ревью механическое: каждый ID либо закрыт
с доказательством `file:line`, либо нет.

## Как дробить

**По слоям.** Модель данных → репозиторий → сервис → HTTP-хендлер → UI. Между слоями
контракт из `contracts/`, поэтому задачи не мешают друг другу.

**По критериям приёмки.** Один `AC` — одна задача, если он тянет на самостоятельный
кусок.

**Код и тесты отдельно** — если тестов много: `implementer` пишет реализацию,
`test-writer` покрывает её, с `depends_on`.

**Не дробите** то, что нельзя проверить по отдельности. Если после T-001 ничего не
запускается, значит граница проведена не там.

## Пример хорошей карточки

```markdown
---
id: T-003
feature: 001-token-refresh
title: Add refresh() to AuthClient
status: todo
depends_on: [T-001]
attempt: 0
agent: implementer
model: opencode/big-pickle
allowed_paths:
  - src/auth/client.ts
  - src/auth/client.test.ts
verify: "npm test -- src/auth/client.test.ts"
---

## Goal
Метод `AuthClient.refresh()` обменивает refresh-токен на новую пару и сохраняет её.

## Context
<полные сигнатуры AuthClient, TokenStore, Token, описание эндпоинта и ошибок>

## Files you may touch
| src/auth/client.ts | modify | только добавить метод refresh() |
| src/auth/client.test.ts | modify | добавить тесты, существующие не трогать |

## Step-by-step
1. Добавь `async refresh(): Promise<Token>` в `AuthClient`.
2. Возьми токен из `this.store.get()`; если `null` — брось `AuthError("no session")`.
3. `POST /auth/refresh` с телом `{ refresh }`.
4. При 401 очисти store и брось `AuthError("invalid_refresh")`.
5. При успехе сохрани через `this.store.set()` и верни новый Token.
6. Тесты: успех, отсутствие сессии, 401, сетевая ошибка.

## Acceptance criteria
- [ ] AC-1 — истёкший токен обновляется без повторного логина
- [ ] AC-2 — невалидный refresh очищает сессию и бросает AuthError

## How to verify
npm test -- src/auth/client.test.ts

## Out of scope — do NOT
- не трогай login() и logout()
- не добавляй зависимости
- не меняй интерфейс TokenStore
```

## Чек-лист перед делегированием

- [ ] ≤ 3 файла, ≤ ~200 строк
- [ ] Context самодостаточен, отсылок к другим документам нет
- [ ] `allowed_paths` — точные пути, включая создаваемые файлы
- [ ] `verify` проверена вручную и проходит на текущем коде (падая по нужной причине)
- [ ] «Out of scope» заполнен
- [ ] критерии приёмки указаны по ID из `spec.md`
- [ ] `depends_on` содержит только реальные зависимости

См. также: [Методология](methodology.md) · [Тестирование](testing.md) ·
[Траблшутинг](troubleshooting.md)
