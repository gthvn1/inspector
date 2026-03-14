type e (* an element of the database *)
type t (* the database *)

val from_channel : in_channel -> t
(** [from_channel ic] reads XML from the input channel and builds a relational
    database *)

val size : t -> int
(** [size t] returns the number of entries in the database *)

val get_ref : t -> ref:string -> e list
(** [get_ref t ~ref] returns the list of elements in the database for the given
    reference. *)

val elt_to_string : e -> string
(** [elt_to_string elt] converts a database element to a human‑readable string.
*)
