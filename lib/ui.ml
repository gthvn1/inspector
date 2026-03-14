type t = { last_cmd : string option; truncated : bool; objects : string list }
(** Keep state related to the UI *)

let create () = { last_cmd = None; truncated = true; objects = [] }
let get_last_cmd_opt ui = ui.last_cmd
let set_last_cmd cmd ui = { ui with last_cmd = Some cmd }
let get_objects ui = ui.objects
let set_objects lst ui = { ui with objects = lst }
let is_truncated ui = ui.truncated
let switch_trunc ui = { ui with truncated = not ui.truncated }
