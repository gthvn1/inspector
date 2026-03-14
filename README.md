# Inspector

Inspector is a small terminal tool to help read and understand **XAPI logs**.
It loads a log file and the XAPI database state, then lets you navigate inside
the logs and inspect objects referenced by the logs.

The goal is to make post‑mortem debugging easier when logs contain many
`OpaqueRef` and UUID identifiers.

The interface is simple and runs entirely in the terminal.

---

## Features

- Load a XAPI log file
- Load a XAPI database dump (XML)
- Navigate inside the log with a cursor
- Highlight `OpaqueRef` identifiers in the logs
- Toggle log truncation
- Inspector panel for future object inspection

---

## Run

Example:

```sh
dune exec ./bin/main.exe -- -log inputs/xensource.log -db inputs/state.xml
```

Example output:

```
Loaded 28 lines from logs | DB entries: 206

---logs----------------------------

[13]: Mar 14 ... VDI.create ...
[14]: Mar 14 ... OpaqueRef:24fac444...
[15]: Mar 14 ... OpaqueRef:24fac444...

---objects-------------------------
TODO

---cli-----------------------------
inspector>
```

---

## Commands

| Command | Description |
|-------|-------------|
| `i` | Update objects with the OpaqueRef found on the current line, if any |
| `n` | Move cursor to next log line |
| `p` | Move cursor to previous log line |
| `t` | Toggle truncated log display |
| `h`, `help` | Show help |
| `q`, `quit`, `exit` | Exit inspector |

Press **Enter** to repeat the last command.

---

## How it works

1. The log file is loaded into memory.
2. The XAPI database XML is parsed.
3. The terminal shows:
   - a **log window**
   - an **objects panel**
   - a **command prompt**
4. The cursor moves inside the logs and identifiers are highlighted.

Next steps of the project will allow inspecting objects referenced in the logs.

---

## Project structure

```
bin/
  main.ml

lib/
  inspect.ml
  model.ml
  repl.ml
  style.ml
  ui.ml
  xapidb.ml
```

- **inspect**: identifier detection and highlighting
- **model**: domain state (logs, cursor, database)
- **repl**: command loop and rendering
- **style**: Ansi escape sequence to manage output
- **ui**: UI state (truncation, inspector panel)
- **xapidb**: parsing the XAPI database

---

## Status

This project is experimental and under development.
