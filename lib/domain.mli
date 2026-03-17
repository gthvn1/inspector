type t
(** Log navigation state.

    A [t] represents a loaded log file and a cursor pointing to the currently
    active line. *)

val create : logfile:string -> dbfile:string -> t
(** [create logfile dbfile] loads the log file [logfile] and the database file
    [dbfile] into memory and initializes the cursor at the first line. *)

val get_line : int -> t -> string
(** [get_line n s] returns the line at index [n] (an `int`). If [n] is outside
    the range of logs, question marks are returned. *)

val get_current_line : t -> string
(** [get_current_line s] returns the line currently pointed to by the cursor. *)

val next : t -> t
(** [next s] moves the cursor to the next line if possible and returns the new
    state. *)

val prev : t -> t
(** [prev s] moves the cursor to the previous line if possible and returns the
    new state. *)

val cursor : t -> int
(** Returns the current cursor position. *)

val size : t -> int
(** Returns the number of lines in the log. *)

val get_db : t -> Xapidb.db
(** [get_db dom] returns the XAPI database registered in [dom]. *)

val ref_count : t -> int
(** Returns the number of reference in the database. *)

val uuid_count : t -> int
(** Returns the number of UUID in the database. *)
