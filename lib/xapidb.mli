(** Representation of the XAPI database extracted from the XML dump.

    The database is parsed from the XML format produced by XAPI and stored in a
    hash table indexed by the object's OpaqueRef UUID.

    Conceptually the structure is:

    {[
      OpaqueRef UUID -> list of attributes of the object
    ]}

    Each object corresponds to a row in a XAPI table (VM, host, VBD, etc). *)

type value
type row
type db

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

val from_channel : in_channel -> db
(** [from_channel ic] reads XML from the input channel and builds a relational
    database *)

val ref_count : db -> int
(** [ref_count t] returns the number of OpaqueRef in the database *)

val uuid_count : db -> int
(** [uuid_count t] returns the number of UUID in the database *)

val get_by_ref : db -> ref:string -> row
(** [get_by_ref t ~ref] returns the list of elements in the database for the
    given opaque reference. *)

val get_by_uuid : db -> uuid:string -> row
(** [get_by_uuid t ~ref] returns the list of elements in the database for the
    given UUID. *)

val row_to_string : row -> string
(** [row_to_string row] converts a database row to a human‑readable string. *)
