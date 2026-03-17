module D = Domain

type app_state = { domain : D.t; ui : Ui.t }
(** Group state of the UI but also of the domain *)

type key = Up | Down | Help | Trunc | Quit | Unkown
type user_input = K of key | S of string

type command = {
    names : string list
  ; key : key
  ; desc : string
  ; run : app_state -> app_state
}

(* Read key in raw mode *)
let read_key () : user_input =
  let c = input_char stdin in
  (* escape character ^ in dec is 27
       - Up is ESC[A; => \027[A *)
  if c = '\027' then
    let c1 = input_char stdin in
    let c2 = input_char stdin in
    match (c1, c2) with '[', 'A' -> K Up | '[', 'B' -> K Down | _ -> K Unkown
  else
    match c with
    | 'q' -> K Quit
    | 'h' -> K Help
    | 't' -> K Trunc
    | ':' -> S (read_line ())
    | _ -> K Unkown

let find_cmd_opt input commands =
  match input with
  | K k -> List.find_opt (fun cmd -> cmd.key = k) commands
  | S s -> List.find_opt (fun cmd -> List.mem s cmd.names) commands

let truncate_log max_len s =
  if String.length s > max_len then String.sub s 0 max_len ^ "..." else s

let viewport ~pos ~height ~size =
  let middle = height / 2 in
  let start = max 0 (pos - middle) in
  let stop = min (start + height) size in
  (start, stop)

let show_logs app =
  let trunc_size = 80 in
  let size = D.size app.domain - 1 in
  let start, stop = viewport ~pos:(D.cursor app.domain) ~height:10 ~size in

  for i = start to stop do
    let log =
      D.get_line i app.domain
      |> (fun l ->
      if Ui.is_truncated app.ui then truncate_log trunc_size l else l)
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
      names = [ "q"; "e"; "quit"; "exit" ]
    ; key = Quit
    ; desc = "Quit inspector"
    ; run = (fun _ -> raise Exit)
    }
  ; {
      names = [ "h"; "help" ]
    ; key = Help
    ; desc = "Show this help"
    ; run =
        (fun app ->
          help commands;
          app)
    }
  ; {
      names = [ "n"; "next" ]
    ; key = Down
    ; desc = "Move cursor to the next log line"
    ; run = (fun app -> { app with domain = D.next app.domain })
    }
  ; {
      names = [ "p"; "prev"; "previous" ]
    ; key = Up
    ; desc = "Move cursor to the previous line"
    ; run = (fun app -> { app with domain = D.prev app.domain })
    }
  ; {
      names = [ "t"; "trunc"; "truncate" ]
    ; key = Trunc
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

let rec loop state =
  (* Update the objects found on current line *)
  let line = D.get_current_line state.domain in
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

  match read_key () with
  | exception End_of_file -> print_endline "Bye"
  | input -> (
      match find_cmd_opt input commands with
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
