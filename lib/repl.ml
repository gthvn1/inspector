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

let rec loop state last_cmd =
  (* rendering part *)
  render state;
  print_string "inspector> ";
  flush stdout;

  try
    let user_input = read_line () |> String.lowercase_ascii in

    (* Determine which command to execute *)
    let cmd =
      match user_input with
      | "" -> last_cmd
      | "e" | "exit" | "q" | "quit" ->
          print_endline "Bye";
          exit 0
      | "h" | "help" ->
          help ();
          (* wait that user press enter *)
          ignore (read_line ());
          None
      | c -> Cmd.find_opt c commands
    in

    match cmd with
    | None -> loop state last_cmd
    | Some c ->
        let new_state = c.run state in
        loop new_state (Some c)
  with End_of_file -> print_endline "bye"

let start state =
  help ();
  loop state None
