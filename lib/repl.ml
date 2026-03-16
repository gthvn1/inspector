module D = Domain

type app_state = { domain : D.t; ui : Ui.t }
(** Group state of the UI but also of the domain *)

type command = {
    names : string list
  ; key : char
  ; desc : string
  ; run : app_state -> app_state
}

let truncate_log max_len s =
  if String.length s > max_len then String.sub s 0 max_len ^ "..." else s

let viewport ~pos ~height ~size =
  let middle = height / 2 in
  let start = max 0 (pos - middle) in
  let stop = min (start + height) size in
  (start, stop)

let show_logs app =
  let size = D.size app.domain - 1 in
  let start, stop = viewport ~pos:(D.cursor app.domain) ~height:10 ~size in

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

let rec commands =
  [
    {
      names = [ "q"; "quit" ]
    ; key = 'q'
    ; desc = "Quit inspector"
    ; run = (fun _ -> raise Exit)
    }
  ; {
      names = [ "h"; "help" ]
    ; key = 'h'
    ; desc = "Show this help"
    ; run =
        (fun app ->
          help commands;
          app)
    }
  ; {
      names = [ "n"; "next" ]
    ; key = 'n'
    ; desc = "Move cursor to the next log line"
    ; run = (fun app -> { app with domain = D.next app.domain })
    }
  ; {
      names = [ "p"; "prev" ]
    ; key = 'p'
    ; desc = "Move cursor to the previous line"
    ; run = (fun app -> { app with domain = D.prev app.domain })
    }
  ; {
      names = [ "t"; "truncate" ]
    ; key = 't'
    ; desc = "Switch truncated mode (lines are truncated to 90 characters)"
    ; run = (fun app -> { app with ui = Ui.switch_trunc app.ui })
    }
  ]

let render state =
  Style.clear ();
  Printf.printf "Loaded %d lines from logs | DB entries: %d\n"
    (D.size state.domain) (D.dbsize state.domain);

  print_endline "\n---[logs]-----------------------------------";
  show_logs state;
  print_endline "\n---[objects]--------------------------------";
  show_objects state;
  print_endline "\n---[cli]------------------------------------"

let find_cmd_opt c commands = List.find_opt (fun cmd -> cmd.key = c) commands

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

  match input_char stdin with
  | exception End_of_file -> print_endline "Bye"
  | carlu -> (
      match find_cmd_opt carlu commands with
      | None -> loop state
      | Some cmd -> cmd.run state |> loop)

let start domain =
  let term = Unix.tcgetattr Unix.stdin in
  let raw = { term with Unix.c_icanon = false } in
  Unix.tcsetattr Unix.stdin Unix.TCSANOW raw;
  Fun.protect
    ~finally:(fun () -> Unix.tcsetattr Unix.stdin Unix.TCSANOW term)
    (fun () ->
      try loop { domain; ui = Ui.create () }
      with Exit -> print_endline "\nBye")
