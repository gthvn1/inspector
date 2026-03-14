(** Interactive command loop for the inspector.

    The REPL (Read–Eval–Print Loop) repeatedly reads commands from standard
    input and applies them to the current navigation state.

    Each command may update the state (for example moving the cursor) or display
    information about the current log line.

    The loop continues until the user enters ["quit"] or ["exit"], or until an
    end-of-file condition is encountered on standard input (for example when
    pressing Ctrl-D). *)

val start : Domain.t -> unit
(** [start state] starts the interactive command loop.

    The given [state] represents the current navigation state of the loaded log
    file. Commands executed by the user may derive new states (for example via
    {!State.next} or {!State.prev}) which are then used in the next iteration of
    the loop.

    The function runs until the user exits the program. *)

val help : unit -> unit
(** [help] print all commands available in the repl. *)
