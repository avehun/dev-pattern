# Contracts — {{TITLE}}

Interfaces that cross task boundaries. **Frozen before decomposition.**

Put one file per contract here, for example:

- `http-api.md` or `openapi.yaml` — request/response shapes and status codes
- `events.md` — event names, payloads, ordering guarantees
- `types.ts` — shared type declarations two tasks must both satisfy
- `cli.md` — command surface, flags, exit codes

## Rules

1. If task T-002 consumes something task T-001 produces, that something is a contract
   and must be written down here **before either card is delegated**.
2. A task card copies the relevant contract fragment inline — the executor is not
   expected to open this directory.
3. An executor that finds the contract wrong must stop and report `blocked`.
   Only the lead changes a contract, and changing one means re-checking every card
   that depends on it.
