type t
(** Keeps state related to the UI. *)

val create : unit -> t
(** [create ()] returns a UI state with truncation enabled by default, last
    command set to [None] and an empty list of objects. *)

val get_last_cmd_opt : t -> string option
(** [get_last_cmd_opt ui] returns the optional string that is the last command
    executed. *)

val set_last_cmd : string -> t -> t
(** [set_last_cmd cmd ui] returns a UI state where the last command has been
    updated to [cmd]. *)

val get_objects : t -> string list
(** [get_objects ui] returns objects currently registered in the [ui]. *)

val set_objects : string list -> t -> t
(** [set_objects lst ui] sets list of OpaqueRef [lst] into [ui] objects. There
    is no verification and you can pass any list of strings. *)

val is_truncated : t -> bool
(** [is_truncated ui] returns [true] if truncation is enabled, [false]
    otherwise. *)

val switch_trunc : t -> t
(** [switch_trunc ui] returns a new UI state where truncation has been toggled.
*)
