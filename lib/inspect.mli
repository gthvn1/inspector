val highlight : string -> string
(** [highlight str] returns a new string where OpaqueRef is highlighted. If no
    reference is found then [str] is returned. *)

val find_opaqueref : string -> string list
(** [find_opaqueref str] returns a list of all OpaqueRef found in [str]. *)
