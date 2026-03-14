type t = { lines : string array; cursor : int; db : Xapidb.t }
(** Invariant: cursor >= 0 cursor < Array.length lines *)

let size s = Array.length s.lines
let dbsize s = Xapidb.size s.db
let cursor s = s.cursor

let create ~(logfile : string) ~(dbfile : string) : t =
  let lines =
    In_channel.with_open_text logfile In_channel.input_lines |> Array.of_list
  in
  let db = In_channel.with_open_text dbfile Xapidb.from_channel in
  { lines; cursor = 0; db }

let show_current_line s = s.lines.(s.cursor)
let show_line n s = if n < 0 || n >= size s then "???" else s.lines.(n)

let next s =
  if s.cursor < size s - 1 then { s with cursor = s.cursor + 1 } else s

let prev s = if s.cursor > 0 then { s with cursor = s.cursor - 1 } else s
let get_db s = s.db
