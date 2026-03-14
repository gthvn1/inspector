type t
(** Log navigation state.

    A [t] represents a loaded log file and a cursor pointing to the currently
    active line. *)

val create : logfile:string -> dbfile:string -> t
(** [create logfile dbfile] loads the log file [logfile] and the database file
    [dbfile] into memory and initializes the cursor at the first line. *)

val show_line : t -> string
(** [show_line s] returns the line currently pointed to by the cursor. *)

val next : t -> t
(** [next s] moves the cursor to the next line if possible. *)

val prev : t -> t
(** [prev s] moves the cursor to the previous line if possible. *)

val cursor : t -> int
(** Current cursor position. *)

val size : t -> int
(** Number of lines in the log. *)

val dbsize : t -> int
(** Number of entries in the db. *)
