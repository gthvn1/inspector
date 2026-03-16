type t = { truncated : bool; objects : string list }
(** Keep state related to the UI *)

let create () = { truncated = true; objects = [] }
let get_objects ui = ui.objects
let set_objects lst ui = { ui with objects = lst }
let is_truncated ui = ui.truncated
let switch_trunc ui = { ui with truncated = not ui.truncated }
