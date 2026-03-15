type value = String of string | Ref of string (* OpaqueRef UUID only *)
type e = string * value
type t = (string, e list) Hashtbl.t

(* ---------------
        Helpers
     -------------- *)
let parse_value s =
  match String.split_on_char ':' s with
  | [ "OpaqueRef"; uuid ] -> Ref uuid
  | _ -> String s

let table_name (attr : Xmlm.attribute list) : string =
  if List.length attr <> 1 then (
    Printf.eprintf "For table only one attribute name is expected, got %d\n"
      (List.length attr);
    failwith "Only one attribute name per table is expected");
  let (_, local), table_name = List.hd attr in
  assert (local = "name");
  table_name

(** [row_elements attr] return a list of tuple where the first element will be
    the key and the second element is a value. Example:
    - host="OpaqueRef:3e.." -> ("host", Ref("3e.."))
    - type="host_internal" -> ("type", String("host_internal")) *)
let row_elements (attr : Xmlm.attribute list) : e list =
  let rec loop acc = function
    | [] -> acc
    | x :: xs ->
        let (_uri, local), name = x in
        loop ((local, parse_value name) :: acc) xs
  in
  loop [] attr

(** [peek_ref elements] return the string that corresponds to "ref" or "_ref".
    It is the OpaqueRef of the object (element) itself. It raises an expection
    if ref is not found. *)
let peek_ref (elements : e list) : string =
  let _, opaqueref =
    List.find (fun (s, _) -> s = "ref" || s = "_ref") elements
  in
  match opaqueref with
  | Ref uuid -> uuid
  | String s -> failwith (Printf.sprintf "OpaqueRef is expected, got %s" s)

(* ---------------
        Interface 
     -------------- *)
let size = Hashtbl.length

(*List.iter (fun e -> Printf.printf "  %-20s\t%s\n" k (XapiDb.elt_to_string v) l))*)
let elt_to_string elt =
  let s1, s2 =
    match elt with s1, String s2 -> (s1, s2) | s1, Ref uuid -> (s1, uuid)
  in
  Printf.sprintf "%-20s\t%s" s1 s2

let get_ref t ~ref =
  match Hashtbl.find_opt t ref with None -> [] | Some l -> l

let from_channel ic =
  let htable : (string, e list) Hashtbl.t = Hashtbl.create 128 in
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
            let _, local = tag_name in
            match local with
            | "database" | "manifest" | "pair" -> stack (* can be skipped *)
            | "table" ->
                let tname = table_name tag_attr_lst in
                tname :: stack
            | "row" ->
                (* Row is always part of a table and we are not expecting nested table *)
                assert (List.length stack = 1);
                let tbname = List.hd stack in
                let elements = row_elements tag_attr_lst in
                let ref = peek_ref elements in

                (* We can now insert the element, we should not have duplicated ref *)
                let () =
                  match Hashtbl.find_opt htable ref with
                  | None ->
                      Hashtbl.add htable ref
                        (("table", String tbname) :: elements)
                  | Some _ -> Printf.eprintf "Ref %s is duplicated" ref
                in
                (* We need to add the row because when reaching `El_end we will remove
                     it, and we will have the table on top. It works because we don't have
                     nested element. *)
                local :: stack
            | _ -> failwith (Printf.sprintf "%s is not handled" local))
        | `El_end -> if List.is_empty stack then stack else List.tl stack
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
  htable

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
