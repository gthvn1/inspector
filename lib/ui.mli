type t
(** Keeps state related to the UI. *)

val create : unit -> t
(** [create ()] returns a UI state with truncation enabled by default and last command set to [None]. *)

val get_last_cmd_opt : t -> string option
(** [get_last_cmd_opt ui] returns the optional string that is the last command executed. *)

val set_last_cmd : string -> t -> t
(** [set_last_cmd cmd ui] returns a UI state where the last command has been updated to [cmd]. *)
val is_truncated : t -> bool
(** [is_truncated ui] returns [true] if truncation is enabled, [false] otherwise. *)

val switch_trunc : t -> t
(** [switch_trunc ui] returns a new UI state where truncation has been toggled. *)

