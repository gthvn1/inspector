type app_state = { domain : State.t; ui : ui_state }
and ui_state = { last_cmd : command option; truncated : bool }
and command = { description : string; run : app_state -> app_state }

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

let show_logs app =
  let open State in
  let height = 10 in
  let middle = height / 2 in
  let max_size = size app.domain - 1 in

  (* We want the cursor in the middle of the log window. And we want to always have
   height lines *)
  let start = max 0 (cursor app.domain - middle) in
  let start = min start (max_size - height) in
  let stop = min (cursor app.domain + middle) max_size in
  let stop = max stop height in

  for i = start to stop do
    let log = show_line i app.domain in
    let log = if app.ui.truncated then truncate_log 90 log else log in
    let line = Printf.sprintf "[%d]: %s" (i + 1) log in
    print_endline
    @@ if i = cursor app.domain then Style.reverse_text line else line
  done

let commands =
  [
    ( "t",
      {
        description =
          "Switch truncated mode (lines are truncated to 90 characters)";
        run =
          (fun s ->
            let new_ui = { s.ui with truncated = not s.ui.truncated } in
            { s with ui = new_ui });
      } );
    ( "n",
      {
        description = "Move cursor to the next log line";
        run = (fun s : app_state -> { s with domain = State.next s.domain });
      } );
    ( "p",
      {
        description = "Move cursor to the previous line";
        run = (fun s : app_state -> { s with domain = State.prev s.domain });
      } );
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
    (State.size state.domain)
    (State.dbsize state.domain);

  print_endline "--------------------------------------------\n";

  show_logs state;

  print_endline "\n--------------------------------------------"

let rec loop state =
  (* rendering part *)
  render state;
  print_string "inspector> ";
  flush stdout;

  try
    let user_input = read_line () |> String.lowercase_ascii in

    (* Determine which command to execute *)
    let cmd =
      match user_input with
      | "" -> state.ui.last_cmd
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
    | None -> loop state
    | Some c ->
        let new_state = c.run state in
        let new_ui = { new_state.ui with last_cmd = Some c } in
        loop { new_state with ui = new_ui }
  with End_of_file -> print_endline "bye"

let start state =
  help ();
  let ui_state = { last_cmd = None; truncated = true } in
  loop { domain = state; ui = ui_state }
