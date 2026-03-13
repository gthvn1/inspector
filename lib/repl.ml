let rec loop state =
  print_string "inspector> ";
  flush stdout;
  try
    match read_line () |> String.lowercase_ascii with
    | "exit" | "quit" -> print_endline "bye"
    | "next" -> loop (State.next state)
    | "prev" -> loop (State.prev state)
    | "show" ->
        Printf.printf "[%d]: %s\n" (State.cursor state) (State.show_line state);
        loop state
    | str ->
        print_endline str;
        loop state
  with End_of_file -> print_endline "bye"
