let re = Re.Perl.compile_pat "OpaqueRef:([0-9a-f-]+)"

let highlight line =
  Re.replace re ~f:(fun g -> Style.yellow_text (Re.Group.get g 0)) line
