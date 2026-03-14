module Cmd = Map.Make (String)
module D = Domain

type app_state = { domain : D.t; ui : Ui.t }
(** Group state of the UI but also of the domain *)

type command = { desc : string; run : app_state -> app_state }

let truncate_log max_len s =
  if String.length s > max_len then String.sub s 0 max_len ^ "..." else s

let show_logs app =
  let height = 10 in
  let middle = height / 2 in
  let max_size = D.size app.domain - 1 in

  (* We want the cursor in the middle of the log window. And we want to always have
   height lines *)
  let start = max 0 (D.cursor app.domain - middle) in
  let start = min start (max_size - height) in
  let stop = min (D.cursor app.domain + middle) max_size in
  let stop = max stop height in

  for i = start to stop do
    let log =
      D.show_line i app.domain
      |> (fun l -> if Ui.is_truncated app.ui then truncate_log 90 l else l)
      |> Inspect.highlight
    in
    let line = Printf.sprintf "[%d]: %s" (i + 1) log in
    print_endline
    @@ (if i = D.cursor app.domain then Style.reverse_text line else line)
    ^ Style.reset
  done

(* TODO: control the size of printed list of objects *)
let show_objects app =
  Ui.get_objects app.ui
  |> List.sort_uniq String.compare
  |> List.iter print_endline

let commands =
  [
    ( "i"
    , {
        desc = "Inspect OpaqueRef of the current line"
      ; run =
          (fun app ->
            let line = D.show_current_line app.domain in
            let refs = Inspect.find_opaqueref line in
            { app with ui = Ui.set_objects refs app.ui })
      } )
  ; ( "n"
    , {
        desc = "Move cursor to the next log line"
      ; run = (fun app -> { app with domain = D.next app.domain })
      } )
  ; ( "p"
    , {
        desc = "Move cursor to the previous line"
      ; run = (fun app -> { app with domain = D.prev app.domain })
      } )
  ; ( "t"
    , {
        desc = "Switch truncated mode (lines are truncated to 90 characters)"
      ; run = (fun app -> { app with ui = Ui.switch_trunc app.ui })
      } )
  ]
  |> List.to_seq |> Cmd.of_seq

let help () =
  Printf.printf "Available commands:\n";
  Cmd.iter (fun cmd args -> Printf.printf "  %-15s %s\n" cmd args.desc) commands;
  print_endline "  [h]elp          Show this help";
  print_endline "  [e]xit, [q]uit  Exit the inspector";
  print_endline "\nPress Enter"

let render state =
  Style.clear ();
  Printf.printf "Loaded %d lines from logs | DB entries: %d\n"
    (D.size state.domain) (D.dbsize state.domain);

  print_endline "\n---[logs]-----------------------------------";
  show_logs state;
  print_endline "\n---[objects]--------------------------------";
  show_objects state;
  print_endline "\n---[cli]------------------------------------"

(* Helper function that executes a command and set it as the last command in UI state *)
let exec_command cmd_name cmd app =
  let app = cmd.run app in
  { app with ui = Ui.set_last_cmd cmd_name app.ui }

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
      | "" -> Ui.get_last_cmd_opt state.ui
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

let start domain = loop { domain; ui = Ui.create () }
