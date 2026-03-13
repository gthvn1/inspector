module State = struct
  type t = { lines : string array; cursor : int; size : int }

  let create (fname : string) : t =
    let lines =
      In_channel.with_open_text fname In_channel.input_lines |> Array.of_list
    in
    { lines; cursor = 0; size = Array.length lines }

  let show_line s : string = s.lines.(s.cursor)

  let rec repl s =
    print_string "inspector> ";
    flush stdout;
    try
      match read_line () |> String.lowercase_ascii with
      | "exit" | "quit" -> print_endline "bye"
      | "next" ->
          if s.cursor < s.size - 1 then repl { s with cursor = s.cursor + 1 }
          else repl s
      | "prev" ->
          if s.cursor > 0 then repl { s with cursor = s.cursor - 1 } else repl s
      | "show" ->
          Printf.printf "[%d]: %s\n" s.cursor (show_line s);
          repl s
      | str ->
          print_endline str;
          repl s
    with End_of_file -> print_endline "bye"
end

let () =
  if Array.length Sys.argv < 2 then (
    Printf.eprintf "Usage: %s <logfile>\n" (Filename.basename Sys.argv.(0));
    exit 1);

  let s = State.create Sys.argv.(1) in
  Printf.printf "Loaded %d lines\n" s.size;

  State.repl s
