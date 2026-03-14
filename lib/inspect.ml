let re = Re.Perl.compile_pat "OpaqueRef:([0-9a-f-]+)"

let highlight line =
  Re.replace re ~f:(fun g -> Style.yellow_text (Re.Group.get g 0)) line

let find_opaqueref line = Re.all re line |> List.map (fun g -> Re.Group.get g 1)
