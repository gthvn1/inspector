type t = { last_cmd : string option; truncated : bool }
(** Keep state related to the UI *)

let create () = { last_cmd = None; truncated = true }
let get_last_cmd_opt ui = ui.last_cmd
let set_last_cmd cmd ui = { ui with last_cmd = Some cmd }
let is_truncated ui = ui.truncated
let switch_trunc ui = { ui with truncated = not ui.truncated }
