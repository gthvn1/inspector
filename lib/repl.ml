type command = { description : string; run : State.t -> State.t }

module Cmd = Map.Make (String)

module Style = struct
  let bold = "\027[1m"
  let reverse = "\027[7m"
  let reset = "\027[0m"
  let bold_text s = bold ^ s ^ reset
  let reverse_text s = reverse ^ s ^ reset
end

let clear () = print_string "\027[2J\027[H"

let truncate_log max_len s =
  if String.length s > max_len then String.sub s 0 max_len ^ "..." else s

let show_logs state =
  let open State in
  let height = 10 in
  let middle = height / 2 in
  let max_size = size state - 1 in

  (* We want the cursor in the middle of the log window. And we want to always have
   height lines *)
  let start = max 0 (cursor state - middle) in
  let start = min start (max_size - height) in
  let stop = min (cursor state + middle) max_size in
  let stop = max stop height in

  for i = start to stop do
    let line =
      Printf.sprintf "[%d]: %s" (i + 1) (truncate_log 90 (show_line i state))
    in
    print_endline @@ if i = cursor state then Style.reverse_text line else line
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

let render state =
  clear ();
  Printf.printf "Loaded %d lines from logs | DB entries: %d\n"
    (State.size state) (State.dbsize state);

  print_endline "--------------------------------------------\n";

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
