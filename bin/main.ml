let usage_msg = "inspector -log <logfile> -db <dbfile>"
let logfile = ref ""
let dbfile = ref ""

let speclist =
  [
    ("-log", Arg.Set_string logfile, "Set log filename");
    ("-db", Arg.Set_string dbfile, "Set XAPI db file");
  ]

let ignore_anon arg = print_endline @@ arg ^ " is ignored"

let () =
  Arg.parse speclist ignore_anon usage_msg;
  if !logfile = "" then (
    Printf.eprintf "You must specify a log file using -log\n";
    exit 1);

  if !dbfile = "" then (
    Printf.eprintf "You must specify a db file using -db\n";
    exit 1);

  let open Inspector in
  Domain.create ~logfile:!logfile ~dbfile:!dbfile |> Repl.start
