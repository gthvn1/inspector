(* capture is on uuid_pattern *)
let uuid_pattern =
  "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"

let re_ref = Re.Perl.compile_pat @@ "OpaqueRef:" ^ uuid_pattern
let re_uuid = Re.Perl.compile_pat uuid_pattern

let find_opaqueref line =
  match Re.all re_ref line |> List.map (fun g -> Re.Group.get g 1) with
  | [] -> []
  | l -> l

(* As uuid will path the substring of the opaqueref we first get OpaqueRef
 if any, then extract UUID and remove them if they are OpaqueRef. *)
let find_uuid line =
  let refs = find_opaqueref line in
  let all_uuids = Re.all re_uuid line |> List.map (fun g -> Re.Group.get g 1) in
  List.filter (fun u -> not (List.mem u refs)) all_uuids

let highlight line =
  let refs = find_opaqueref line in
  line
  |> Re.replace re_ref ~f:(fun g -> Style.yellow_text (Re.Group.get g 0))
  |> Re.replace re_uuid ~f:(fun g ->
      (* Here, like fin_uuid, we are matching all UUID so we need to check if it is not an opaqueref *)
      let u = Re.Group.get g 0 in
      if List.mem u refs then u else Style.green_text u)
