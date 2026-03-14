type t
(** Log navigation state.

    A [t] represents a loaded log file and a cursor pointing to the currently
    active line. *)

val create : logfile:string -> dbfile:string -> t
(** [create logfile dbfile] loads the log file [logfile] and the database file
    [dbfile] into memory and initializes the cursor at the first line. *)

val show_line : int -> t -> string
(** [show_line n s] returns the line at index [n] (an `int`). If [n] is outside
    the range of logs, question marks are returned. *)

val show_current_line : t -> string
(** [show_current_line s] returns the line currently pointed to by the cursor.
*)

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

val get_db : t -> Xapidb.t
(** [get_db dom] returns the XAPI database registered in [dom]. *)

val dbsize : t -> int
(** Returns the number of entries in the database. *)
