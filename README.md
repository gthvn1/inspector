# Inspector

- run
```sh
❯ dune exec ./bin/main.exe -- -log inputs/xensource.log -db inputs/state.xml
Loaded 28 lines from logs
Found 206 entries in the DB
Available commands:
  next        Move cursor to the next log line
  prev        Move cursor to the previous line
  show        Display the current log line
  help        Show this help
  exit, quit  Exit the inspector
inspector>
```
