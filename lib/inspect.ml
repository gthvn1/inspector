let highlight line =
  let keyword = "OpaqueRef:" in
  let len = String.length keyword in

  let rec find i =
    if i > String.length line - len then None
    else if String.sub line i len = keyword then Some i
    else find (i + 1)
  in

  match find 0 with
  | None -> line
  | Some i ->
      let before = String.sub line 0 i in
      let after = String.sub line i (String.length line - i) in
      before ^ Style.bold_text after
