type ui_state = { last_cmd : string option; truncated : bool }
(** Keep state related to the UI *)

type app_state = { domain : Domain.t; ui : ui_state }
(** Group state of the UI but also of the domain *)

type command = { description : string; run : app_state -> app_state }

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
  let open Domain in
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

let show_objects app = print_endline "TODO"

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
        run = (fun s : app_state -> { s with domain = Domain.next s.domain });
      } );
    ( "p",
      {
        description = "Move cursor to the previous line";
        run = (fun s : app_state -> { s with domain = Domain.prev s.domain });
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
    (Domain.size state.domain)
    (Domain.dbsize state.domain);

  print_endline "\n---[logs]-----------------------------------";
  show_logs state;
  print_endline "\n---[objects]--------------------------------";
  show_objects state;
  print_endline "\n---[cli]------------------------------------"

(* Helper function that executes a command and set it as the last command in UI state *)
let exec_command cmd_name cmd app =
  let app = cmd.run app in
  { app with ui = { app.ui with last_cmd = Some cmd_name } }

let rec loop state =
  (* rendering part *)
  render state;
  print_string "inspector> ";
  flush stdout;

  try
    let input = read_line () |> String.lowercase_ascii in

    (* Determine which command to execute *)
    let cmd_name =
      match input with
      | "" -> state.ui.last_cmd
      | "e" | "exit" | "q" | "quit" ->
          print_endline "Bye";
          exit 0
      | "h" | "help" ->
          help ();
          (* wait that user press enter *)
          ignore (read_line ());
          None
      | str -> Some str
    in

    match cmd_name with
    | None -> loop state
    | Some cmd_str -> (
        match Cmd.find_opt cmd_str commands with
        | None -> loop state
        | Some c -> exec_command cmd_str c state |> loop)
  with End_of_file -> print_endline "bye"

let start state =
  help ();
  let ui_state = { last_cmd = None; truncated = true } in
  loop { domain = state; ui = ui_state }
