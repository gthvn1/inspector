module Cmd = Map.Make (String)
module D = Domain

type app_state = { domain : D.t; ui : Ui.t }
(** Group state of the UI but also of the domain *)

type command = {
    names : string list
  ; desc : string
  ; run : app_state -> app_state
}

let truncate_log max_len s =
  if String.length s > max_len then String.sub s 0 max_len ^ "..." else s

let show_logs app =
  let height = 10 in
  let middle = height / 2 in
  let max_size = D.size app.domain - 1 in

  (* We want the cursor in the middle of the log window. And we want to always have
   height lines *)
  let start =
    max 0 (min (D.cursor app.domain - middle) (max_size - height + 1))
  in
  let stop = max height (min (D.cursor app.domain + middle) max_size) in

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
let show_objects app = Ui.get_objects app.ui |> List.iter print_endline

let help commands =
  Printf.printf "Available commands:\n";
  List.iter
    (fun cmd ->
      Printf.printf "  %-20s %s\n" (String.concat "|" cmd.names) cmd.desc)
    commands;
  (* wait that user press enter *)
  print_endline "Press enter";
  ignore (read_line ())

let commands =
  let rec cmd_list =
    [
      {
        names = [ "e"; "exit"; "q"; "quit" ]
      ; desc = "Quit inspector"
      ; run =
          (fun _ ->
            print_endline "Bye";
            exit 0)
      }
    ; {
        names = [ "h"; "help" ]
      ; desc = "Show this help"
      ; run =
          (fun app ->
            help cmd_list;
            app)
      }
    ; {
        names = [ "n"; "next" ]
      ; desc = "Move cursor to the next log line"
      ; run = (fun app -> { app with domain = D.next app.domain })
      }
    ; {
        names = [ "p"; "prev" ]
      ; desc = "Move cursor to the previous line"
      ; run = (fun app -> { app with domain = D.prev app.domain })
      }
    ; {
        names = [ "t"; "trunc"; "truncate" ]
      ; desc = "Switch truncated mode (lines are truncated to 90 characters)"
      ; run = (fun app -> { app with ui = Ui.switch_trunc app.ui })
      }
    ]
  in
  cmd_list |> List.to_seq
  |> Seq.flat_map (fun cmd ->
      List.to_seq (List.map (fun name -> (name, cmd)) cmd.names))
  |> Cmd.of_seq

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
  (* Update the objects found on current line *)
  let line = D.show_current_line state.domain in
  let db = D.get_db state.domain in
  let refs =
    Inspect.find_opaqueref line
    |> List.sort_uniq String.compare
    |> List.map (fun ref ->
        Printf.eprintf "DEBUG: looking for ref %s\n%!" ref;
        Xapidb.get_ref ~ref db |> Xapidb.row_to_string)
  in
  let state = { state with ui = Ui.set_objects refs state.ui } in

  (* Rendering part *)
  render state;
  print_string "inspector> ";
  flush stdout;

  match read_line () with
  | exception End_of_file -> print_endline "Bye"
  | input -> (
      (* Determine which command to execute *)
      let cmd_name =
        match input |> String.trim |> String.lowercase_ascii with
        | "" -> Ui.get_last_cmd_opt state.ui
        | str -> Some str
      in

      match cmd_name with
      | None -> loop state
      | Some cmd_str -> (
          match Cmd.find_opt cmd_str commands with
          | None -> loop state
          | Some c -> exec_command cmd_str c state |> loop))

let start domain = loop { domain; ui = Ui.create () }
