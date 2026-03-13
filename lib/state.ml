type t = { lines : string array; cursor : int }
(** Invariant: cursor >= 0 cursor < Array.length lines *)

let size s = Array.length s.lines
let cursor s = s.cursor

let create (fname : string) : t =
  let lines =
    In_channel.with_open_text fname In_channel.input_lines |> Array.of_list
  in
  { lines; cursor = 0 }

let show_line s : string = s.lines.(s.cursor)

let next s =
  if s.cursor < size s - 1 then { s with cursor = s.cursor + 1 } else s

let prev s = if s.cursor > 0 then { s with cursor = s.cursor - 1 } else s
