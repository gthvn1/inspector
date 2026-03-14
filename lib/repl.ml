type command = { description : string; run : State.t -> State.t }

module Cmd = Map.Make (String)

let show_logs state =
  let open State in
  let height = 10 in
  let middle = height / 2 in

  (* We want the cursor in the middle of the log window *)
  let start = max 0 (cursor state - middle) in
  let stop = min (size state) (cursor state + middle) in

  for i = start to stop do
    let prefix = if i = cursor state then "> " else "  " in
    Printf.printf "%s[%d]: %s\n" prefix i (show_line i state)
  done

let commands =
  [
    ("n", { description = "Move cursor to the next log line"; run = State.next });
    ("p", { description = "Move cursor to the previous line"; run = State.prev });
  ]
  |> List.to_seq |> Cmd.of_seq

let help () =
  Printf.printf "Available commands:\n";
  Cmd.iter
    (fun cmd args -> Printf.printf "  %-15s %s\n" cmd args.description)
    commands;
  print_endline "  [h]elp          Show this help";
  print_endline "  [e]xit, [q]uit  Exit the inspector";
  print_endline "\nPress Enter"

let clear () = print_string "\027[2J\027[H"

let render state =
  clear ();
  Printf.printf "Loaded %d lines from logs | DB entries: %d\n"
    (State.size state) (State.dbsize state);

  print_endline "--------------------------------------------\n\n";

  show_logs state;

  print_endline "\n--------------------------------------------"

let rec loop state =
  render state;
  print_string "inspector> ";
  flush stdout;
  try
    let cmd = read_line () |> String.lowercase_ascii in
    match cmd with
    | "" -> loop state
    | "e" | "exit" | "q" | "quit" -> print_endline "bye"
    | "h" | "help" ->
        help ();
        ignore (read_line ());
        (* wait that user press enter *)
        loop state
    | _ -> (
        match Cmd.find_opt cmd commands with
        | Some c -> loop (c.run state)
        | None ->
            Printf.printf "Unknown command: %s\n" cmd;
            loop state)
  with End_of_file -> print_endline "bye"

let start state =
  help ();
  loop state
