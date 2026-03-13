let load_lines filename =
  In_channel.with_open_text filename In_channel.input_lines |> Array.of_list

let () =
  if Array.length Sys.argv < 2 then (
    Printf.eprintf "Usage: %s <logfile>\n" (Filename.basename Sys.argv.(0));
    exit 1);

  let contents = load_lines Sys.argv.(1) in
  Printf.printf "Loaded %d lines\n" (Array.length contents)
