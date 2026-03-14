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

- [ ] Stage 1: Split the terminal
- [ ] Stage 2: Show a live log
- [ ] Stage 3: Add a command line at the bottom
- [ ] Stage 4: Commands that call external tools
- [ ] Stage 5: UUID / OpaqueRef resolver

## Step 1

- Smallest program that splits the area into two parts
  - top: Log area
  - bottom: cli

## Step 2

- Fake logs
  - Replace top placeholder with fake logs
  - Refreshing UI
  - Scrolling

## Step 3

- Command line interface
  - to be defined

## Step 4

- External command: we will need to all `xe`
- Access to XAPI database

## Step 5

- Query for UUID and OpaqueRef
