type e (* an element of the database *)
type t (* the database *)

val from_channel : in_channel -> t
(** [from_file ic] reads XML from the input channel and build a relational
    database *)

val size : t -> int
(** [size t] returns the number of entries in the database *)

val get_ref : t -> ref:string -> e list
val elt_to_string : e -> string
