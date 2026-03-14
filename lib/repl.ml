type command = { description : string; run : State.t -> State.t }

module Cmd = Map.Make (String)

let show_command state =
  let open State in
  Printf.printf "[%d]: %s\n" (cursor state) (show_line state);
  state

let commands =
  [
    ( "next",
      { description = "Move cursor to the next log line"; run = State.next } );
    ( "prev",
      { description = "Move cursor to the previous line"; run = State.prev } );
    ( "show",
      { description = "Display the current log line"; run = show_command } );
  ]
  |> List.to_seq |> Cmd.of_seq

let help () =
  Printf.printf "Available commands:\n";
  Cmd.iter
    (fun cmd args -> Printf.printf "  %-11s %s\n" cmd args.description)
    commands;
  print_endline "  help        Show this help";
  print_endline "  exit, quit  Exit the inspector"

let clear () = print_string "\027[2J\027[H"

let rec loop state =
  print_string "inspector> ";
  flush stdout;
  try
    let cmd = read_line () |> String.lowercase_ascii in
    match cmd with
    | "" -> loop state
    | "exit" | "quit" -> print_endline "bye"
    | "help" ->
        help ();
        loop state
    | _ -> (
        match Cmd.find_opt cmd commands with
        | Some c -> loop (c.run state)
        | None ->
            Printf.printf "Unknown command: %s\n" cmd;
            loop state)
  with End_of_file -> print_endline "bye"

let start state =
  clear ();
  Printf.printf "Loaded %d lines from logs\n" (State.size state);
  Printf.printf "Found %d entries in the DB\n" (State.dbsize state);
  help ();
  loop state
