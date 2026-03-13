let () =
  let open Inspector in
  if Array.length Sys.argv <> 2 then (
    Printf.eprintf "Usage: %s <logfile>\n" (Filename.basename Sys.argv.(0));
    exit 1);

  let s = State.create Sys.argv.(1) in
  Printf.printf "Loaded %d lines\n" (State.size s);
  Repl.help ();

  Repl.loop s
