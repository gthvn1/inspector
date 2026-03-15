(** Representation of the XAPI database extracted from the XML dump.

    The database is parsed from the XML format produced by XAPI and stored in a
    hash table indexed by the object's OpaqueRef UUID.

    Conceptually the structure is:

    {[
      OpaqueRef UUID -> list of attributes of the object
    ]}

    Each object corresponds to a row in a XAPI table (VM, host, VBD, etc). *)

(** A value stored in the database.

    Attributes of XAPI objects are either plain strings or references to another
    object identified by its OpaqueRef UUID. *)
type value =
  | String of string  (** A plain attribute value (uuid, name, type, etc). *)
  | Ref of string
      (** Reference to another object in the database (OpaqueRef UUID). *)

type elt = string * value
(** One attribute of an object.

    The first element is the attribute name, the second is its value.

    Example:

    {[
      ("uuid", String "6ff4b261-3e37-47f8-ace1-53556da6fcf2")
        ("host", Ref "3ec68fc0-3c60-ffa4-e499-6142c369ea39")
    ]} *)

type t
(** Internal representation of the parsed database.

    The key is the OpaqueRef UUID (without the "OpaqueRef:" prefix).

    Example conceptual structure:

    {[
      "3ec68fc0-3c60-ffa4-e499-6142c369ea39" ->
        [
          ("table", String "host");
          ("uuid", String "6ff4b261-3e37-47f8-ace1-53556da6fcf2");
        ]
    ]} *)

val from_channel : in_channel -> t
(** [from_channel ic] reads XML from the input channel and builds a relational
    database *)

val size : t -> int
(** [size t] returns the number of entries in the database *)

val get_ref : t -> ref:string -> elt list
(** [get_ref t ~ref] returns the list of elements in the database for the given
    opaque reference. *)

val elt_to_string : elt -> string
(** [elt_to_string elt] converts a database element to a human‑readable string.
*)
