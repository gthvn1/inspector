module SMap = Map.Make (String)

type opaqueref = string
type uuid = string
type value = String of string | OpaqueRef of opaqueref
type row = value SMap.t

type db = {
    by_ref : (opaqueref, row) Hashtbl.t
  ; by_uuid : (uuid, opaqueref) Hashtbl.t
}

(* ---------------
        Helpers
     -------------- *)
let empty_row = SMap.empty

(** [parse_value s] returnsOpaqueRef <UUID> if [s] is a string that starts with
    "OpaqueRef", and String s otherwise. *)
let parse_value s : value =
  match String.split_on_char ':' s with
  | [ "OpaqueRef"; uuid ] -> OpaqueRef uuid
  | _ -> String s

(** [table_name attr] extracts the name from a table attribute [attr]. We are
    expecting a table attribute like: [(("", "name"), "Bond")]. If the attribute
    is not well formed it raises an error. *)
let table_name (attr : Xmlm.attribute list) : string =
  match attr with
  | [ ((_, local), name) ] -> name
  | l ->
      Printf.eprintf "For table only one attribute name is expected, got %d\n"
        (List.length l);
      failwith "Only one attribute name per table is expected"

(** [attr_to_row attr] converts an XML attribute list into a map from keys to
    values.

    Each attribute is a pair [((uri, key), value)]. The [key] is used as the map
    key, and [value] is parsed using {!parse_value}.

    Example input:
    {v
      [
        (("", "driver"), "OpaqueRef:d5c14883-7b16-4c9b-3aea-6e097ac39721");
        (("", "version"), "1.2");
      ]
    v}

    Resulting map (conceptually):
    {v
      {
        "driver"  -> OpaqueRef "d5c14883-7b16-4c9b-3aea-6e097ac39721";
        "version" -> String "1.2";
      }
    v} *)
let attr_to_row (attr : Xmlm.attribute list) : row =
  List.map (fun ((_uri, local), name) -> (local, parse_value name)) attr
  |> SMap.of_list

(** [peek_ref elements] return the string that corresponds to "ref" or "_ref".
    It is the OpaqueRef of the object (element) itself. It raises an expection
    if ref is not found.

    First we look for a key "ref" or "_ref" and when found we return the
    OpaqueRef If there is no such key or its value is not an OpaqueRef we raised
    an error. *)
let peek_ref (r : row) : opaqueref =
  let find name =
    match SMap.find_opt name r with
    | Some (OpaqueRef uuid) -> Some uuid
    | Some (String s) ->
        failwith (Printf.sprintf "OpaqueRef not found for %s, got %s" name s)
    | None -> None
  in
  match find "ref" with
  | Some uuid -> uuid
  | None -> (
      match find "_ref" with
      | Some uuid -> uuid
      | None -> failwith "Missing ref/_ref attribute")

(* ---------------
      Interface
   -------------- *)
let ref_count db = Hashtbl.length db.by_ref
let uuid_count db = Hashtbl.length db.by_uuid

(*List.iter (fun e -> Printf.printf "  %-20s\t%s\n" k (XapiDb.elt_to_string v) l))*)
let value_to_string elt =
  match elt with String s2 -> s2 | OpaqueRef uuid -> "OpaqueRef:" ^ uuid

let row_to_string (row : row) =
  let pair_to_string (key, value) =
    Printf.sprintf "%-20s\t%s" key (value_to_string value)
  in
  row |> SMap.bindings |> List.map pair_to_string |> String.concat "\n"

let get_by_ref db ~ref =
  Option.value (Hashtbl.find_opt db.by_ref ref) ~default:empty_row

let get_by_uuid db ~(uuid : uuid) =
  match Hashtbl.find_opt db.by_uuid uuid with
  | None -> empty_row
  | Some ref -> get_by_ref db ~ref

let from_channel ic =
  let ref_table : (opaqueref, row) Hashtbl.t = Hashtbl.create 128 in
  let uuid_table : (uuid, opaqueref) Hashtbl.t = Hashtbl.create 128 in
  let input = Xmlm.make_input (`Channel ic) in
  (* The goal of the loop is to fill the Hashtbl where the key is the OpaqueRef
     of an element. An element is basically the row but we will see as we go. *)
  let rec read_loop (stack : string list) =
    try
      (* input as a side effect *)
      let new_stack =
        match Xmlm.input input with
        | `Dtd _ -> stack (* can be safely ignored *)
        | `El_start (tag_name, tag_attr_lst) -> (
            (* Example:
                `El_start (("", "table"), [(("", "name"), "Bond")])
                   tag_name     --> ("", "table"), 
                   tag_attr_lst --> [(("", "name"), "Bond")] 
             *)
            let _, local = tag_name in
            match local with
            | "database" | "manifest" | "pair" -> stack (* can be skipped *)
            | "table" ->
                let tname = table_name tag_attr_lst in
                (* with our previous example we will push "Bond" on the list *)
                tname :: stack
            | "row" ->
                (* Row is always part of a table and we are not expecting nested table *)
                (* Example of row:
                        `El_start
                          (("", "row"),
                           [(("", "ref"), "OpaqueRef:033c8a63-49e7-86b5-acc0-194c12f2a078");
                            (("", "_ref"), "OpaqueRef:033c8a63-49e7-86b5-acc0-194c12f2a078");
                            (("", "driver"), "OpaqueRef:d5c14883-7b16-4c9b-3aea-6e097ac39721");
                            ...;
                            (("", "uuid"), "22135b35-ebe5-b54b-cd35-836a05e96792");
                            (("", "version"), "1.2")])
                   => tag_attr_list --> [(("", "ref"), "OpaqueRef:033c8a63-49e7-86b5-acc0-194c12f2a078"); ...]
                 *)
                assert (List.length stack = 1);
                let tbname = List.hd stack in
                let elements = attr_to_row tag_attr_lst in
                let ref = peek_ref elements in

                (* We can now insert the element, we should not have duplicated ref *)
                let () =
                  match Hashtbl.find_opt ref_table ref with
                  | None ->
                      (* We add the table name in the row so we will have the information later when
                         printing information *)
                      SMap.add "table" (String tbname) elements
                      |> Hashtbl.add ref_table ref
                  | Some _ -> Printf.eprintf "Ref %s is duplicated" ref
                in
                (* NOTE: We need to add the row because when reaching `El_end we will
                   remove it, and we will have the table on top. It works because we
                   don't have nested element. *)
                local :: stack
            | _ -> failwith (Printf.sprintf "%s is not handled" local))
        | `El_end -> ( match stack with [] -> [] | _ :: xs -> xs)
        | `Data _ ->
            (* Printf.printf "Data found\n" ;*)
            stack
      in
      read_loop new_stack
    with Xmlm.Error ((line, col), err) ->
      if not (Xmlm.eoi input) then (
        Printf.eprintf "[%d, %d]: Got exception: %s" line col
          (Xmlm.error_message err);
        exit 1)
  in
  read_loop [];
  { by_ref = ref_table; by_uuid = uuid_table }

let _sample_xml : string =
  {|
<?xml version="1.0" encoding="UTF-8"?>
<database>
  <manifest><pair key="schema_major_vsn" value="5"/><pair key="schema_minor_vsn" value="792"/><pair key="generation_count" value="72945"/></manifest>
  <table name="Certificate">
    <row ref="OpaqueRef:2b3b5149-e164-25b8-3e5c-b3da1765d060"  host="OpaqueRef:3ec68fc0-3c60-ffa4-e499-6142c369ea39" name="" type="host" uuid="7e514750-435c-c6e8-0272-042f644260f2"/>
    <row ref="OpaqueRef:082d1948-c3f7-91ae-8793-568c9e888810"  host="OpaqueRef:3ec68fc0-3c60-ffa4-e499-6142c369ea39" name=""  type="host_internal" uuid="bd62e7eb-ab54-82df-9c76-bea4981bf48d"/>
  </table>
  <table name="Cluster"/>
  <table name="Cluster_host"/>
  <table name="host">
    <row ref="OpaqueRef:3ec68fc0-3c60-ffa4-e499-6142c369ea39" CERTIFICATEs="('OpaqueRef:2b3b5149-e164-25b8-3e5c-b3da1765d060'%.'OpaqueRef:082d1948-c3f7-91ae-8793-568c9e888810')" uuid="6ff4b261-3e37-47f8-ace1-53556da6fcf2" />
   </table>
  <table name="pool_update"/>
</database>
|}
