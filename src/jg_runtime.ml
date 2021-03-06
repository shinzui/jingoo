(*
  jg_runtime.ml

  Copyright (c) 2011- by Masaki WATANABE

  License: see LICENSE
*)
open Jg_utils
open Jg_types

let box_int i = Tint i
let box_float f = Tfloat f
let box_string s = Tstr s
let box_bool b = Tbool b
let box_list lst = Tlist lst
let box_set lst = Tset lst
let box_obj alist = Tobj alist
let box_hash hash = Thash hash
let box_array a = Tarray a
let box_pat fn = Tpat fn
let box_lazy z = Tlazy z
let box_fun z = Tfun z

let unbox_int = function
  | Tint x -> x
  | _ -> failwith "invalid arg:not int(unbox_int)"

let unbox_float = function
  | Tfloat f -> f
  | _ -> failwith "invalid arg:not float(unbox_float)"

let unbox_string = function
  | Tstr s -> s
  | _ -> failwith "invalid arg:not string(unbox_string)"

let unbox_bool = function
  | Tbool b -> b
  | _ -> failwith "invalid arg:not bool(unbox_bool)"

let unbox_list = function
  | Tlist lst -> lst
  | _ -> failwith "invalid arg:not list(unbox_list)"

let unbox_set = function
  | Tset lst -> lst
  | _ -> failwith "invalid arg:not set(unbox_set)"

let unbox_array = function
  | Tarray lst -> lst
  | _ -> failwith "invalid arg:not list(unbox_list)"

let unbox_obj = function
  | Tobj alist -> alist
  | _ -> failwith "invalid arg:not obj(unbox_obj)"

let unbox_hash = function
  | Thash hash -> hash
  | _ -> failwith "invalid arg:not hahs(unbox_hash)"

let unbox_pat = function
  | Tpat pat -> pat
  | _ -> failwith "invalid arg:not hahs(unbox_pat)"

let string_of_tvalue = function
  | Tint x -> string_of_int x
  | Tfloat x -> string_of_float x
  | Tstr x -> x
  | Tbool x -> string_of_bool x
  | Tobj x -> "<obj>"
  | Thash x -> "<hash>"
  | Tpat _ -> "<pat>"
  | Tlist x -> "<list>"
  | Tset x -> "<set>"
  | Tfun _ -> "<fun>"
  | Tnull -> ""
  | Tarray _ -> "<array>"
  | Tlazy _ -> "<lazy>"
  | Tvolatile x -> "<volatile>"

let type_string_of_tvalue = function
  | Tint x -> "int"
  | Tfloat x -> "float"
  | Tstr x -> "string"
  | Tbool x -> "bool"
  | Tobj x -> "obj"
  | Thash x -> "hash"
  | Tlist x -> "list"
  | Tpat x -> "pat"
  | Tset x -> "set"
  | Tfun _ -> "function"
  | Tnull -> "null"
  | Tarray _ -> "array"
  | Tlazy _ -> "lazy"
  | Tvolatile _ -> "volatile"

let dump_expr = function
  | IdentExpr(str) -> spf "IdentExpr(%s)" str
  | LiteralExpr(tvalue) -> spf "LiteralExpr(%s)" (string_of_tvalue tvalue)
  | NotOpExpr(_) -> "NotOpExpr"
  | NegativeOpExpr(_) -> "NegativeOpExpr"
  | PlusOpExpr(_,_) -> "PlusOpExpr"
  | MinusOpExpr(_,_) -> "MinusExpr"
  | TimesOpExpr(_,_) -> "TimesOpExpr"
  | PowerOpExpr(_,_) -> "PowerOpExpr"
  | DivOpExpr(_,_) -> "DivOpExpr"
  | ModOpExpr(_,_) -> "ModOpExpr"
  | AndOpExpr(_,_) -> "AndOpExpr"
  | OrOpExpr(_,_) -> "OrOpExpr"
  | NotEqOpExpr(_,_) -> "NotEqOpExpr"
  | EqEqOpExpr(_,_) -> "EqEqExpr"
  | LtOpExpr(_,_) -> "LtOpExpr"
  | GtOpExpr(_,_) -> "GtOpExpr"
  | LtEqOpExpr(_,_) -> "LtEqOpExpr"
  | GtEqOpExpr(_,_) -> "GtEqOpExpr"
  | DotExpr(_,_) -> "DotExpr"
  | BracketExpr(_,_) -> "BracketExpr"
  | ListExpr(_) -> "ListExpr"
  | SetExpr(_) -> "SetExpr"
  | ObjExpr(_) -> "ObjExpr"
  | InOpExpr(_,_) -> "InOpExpr"
  | KeywordExpr(_,_) -> "KeywordExpr"
  | AliasExpr(_,_) -> "AliasExpr"
  | ApplyExpr(_,_) -> "ApplyExpr"
  | TestOpExpr(_,_) -> "TestOpExpr"

let is_iterable = function
  | Tlist _ | Tset _ | Thash _ | Tobj _ | Tarray _ | Tstr _ | Tnull-> true
  | _ -> false

let jg_strp = function
  | Tstr _ -> Tbool true
  | _ -> Tbool false

let jg_intp = function
  | Tint _ -> Tbool true
  | _ -> Tbool false

let jg_floatp = function
  | Tfloat _ -> Tbool true
  | _ -> Tbool false

let jg_listp = function
  | Tlist _ -> Tbool true
  | _ -> Tbool false

let jg_setp = function
  | Tset _ -> Tbool true
  | _ -> Tbool false

let jg_objp = function
  | Tobj _ -> Tbool true
  | _ -> Tbool false

let jg_hashp = function
  | Thash _ -> Tbool true
  | _ -> Tbool false

let jg_patp = function
  | Tpat _ -> Tbool true
  | _ -> Tbool false

let jg_funp = function
  | Tfun _ -> Tbool true
  | _ -> Tbool false

let jg_arrayp = function
  | Tarray _ -> Tbool true
  | _ -> Tbool false

let jg_push_frame ctx =
  {ctx with frame_stack = (Hashtbl.create 10) :: ctx.frame_stack}

let jg_pop_frame ctx =
  match ctx.frame_stack with
    | [] -> ctx (* never happen *)
    | [top_frame] -> ctx (* because top frame always remain *)
    | frame :: rest -> {ctx with frame_stack = rest} (* other case, pop latest *)

let jg_set_value ctx name value =
  match ctx.frame_stack with
    | [] ->
      let frame = Hashtbl.create 10 in
      Hashtbl.add frame name value;
      {ctx with frame_stack = frame :: []}
    | frame :: rest ->
      Hashtbl.add frame name value;
      {ctx with frame_stack = frame :: rest}

let jg_set_values ctx names values =
  List.fold_left2 (fun ctx name value ->
    jg_set_value ctx name value
  ) ctx names (Jg_utils.take (List.length names) values ~pad:Tnull)

let jg_bind_names ctx names values =
  match names, values with
    | [name], value -> jg_set_value ctx name value
    | name :: rest, Tset values -> jg_set_values ctx names values
    | _ -> ctx

let rec jg_force = function
  | Tlazy x -> jg_force (Lazy.force x)
  | Tvolatile x -> jg_force (x ())
  | x -> x

let rec jg_get_value ctx name =
  let rec get_value name = function
    | frame :: rest ->
      (try jg_force (Hashtbl.find frame name)
       with Not_found -> get_value name rest)
    | [] ->
      (try Thash (Hashtbl.find ctx.namespace_table name)
       with Not_found -> Tnull) in
  get_value name ctx.frame_stack

let jg_get_func ctx name =
  match jg_get_value ctx name with
    | Tfun f -> Tfun f
    | _ -> failwith @@ spf "undefined function %s" name

let jg_set_macro ctx name macro =
  Hashtbl.add ctx.macro_table name macro

let jg_get_macro ctx name =
  try Some(Hashtbl.find ctx.macro_table name) with Not_found -> None

let jg_remove_macro ctx name =
  Hashtbl.remove ctx.macro_table name

let jg_set_filter ctx name =
  {ctx with active_filters = name :: ctx.active_filters}

let jg_pop_filter ctx =
  match ctx.active_filters with
    | [] -> ctx
    | head :: rest -> {ctx with active_filters = rest}

let jg_escape_html str kwargs =
  match str with
    | Tstr str -> Tstr(Jg_utils.escape_html str)
    | other -> Tstr(Jg_utils.escape_html @@ string_of_tvalue other)

let jg_apply ?(name="<lambda>") ?(kwargs=[]) f args =
  match f with
    | Tfun fn -> fn args kwargs
    | _ -> failwith @@ spf "invalid apply: %s(%s) is not function(%s)" name (string_of_tvalue f) (type_string_of_tvalue f)

let jg_apply_filters ?(autoescape=true) ?(safe=false) ctx text filters =
  let (safe, text) = List.fold_left (fun (safe, text) name ->
    if name = "safe" then
      (true, text)
    else if name = "escape" && autoescape = true then
      (safe, text)
    else
      (safe, jg_apply (jg_get_func ctx name) [text] ~name)
  ) (safe, text) filters in
  if safe || not autoescape then text else jg_escape_html text []

let jg_output ?(autoescape=true) ?(safe=false) ctx value =
  (match ctx.active_filters, safe, value with
    | [], true, Tstr text -> ctx.output text
    | [], true, value -> ctx.output @@ string_of_tvalue value
    | _ ->
      ctx.output @@ string_of_tvalue @@
	jg_apply_filters ctx value ctx.active_filters ~safe ~autoescape
  );
  ctx

let rec jg_obj_lookup obj prop_name =
  jg_force @@
  match obj with
    | Tobj(alist) -> (try List.assoc prop_name alist with Not_found -> Tnull)
    | Thash(hash) -> (try Hashtbl.find hash prop_name with Not_found -> Tnull)
    | Tpat(fn) -> (try fn prop_name with Not_found -> Tnull)
    | Tlazy _ | Tvolatile _ -> jg_obj_lookup (jg_force obj) prop_name
    | _ -> failwith ("jg_obj_lookup:not object when looking for '"  ^ prop_name ^ "'")

let jg_obj_lookup_by_name ctx obj_name prop_name =
  match jg_get_value ctx obj_name with
    | (Tobj _ | Thash _ | Tpat _) as obj -> jg_obj_lookup obj prop_name
    | _ -> (try Jg_stub.get_func obj_name prop_name with Not_found -> Tnull)

let jg_obj_lookup_path obj path =
  List.fold_left (fun obj key -> jg_obj_lookup obj key) obj path

let jg_iter_mk_ctx ctx iterator itm len i =
  let cycle = Tfun (fun args kwargs ->
      let args_len = List.length args in
      List.nth args (i mod args_len)
    ) in
  let ctx = jg_push_frame ctx in
  let ctx = jg_bind_names ctx iterator itm in
  let ctx =
    jg_set_value ctx "loop" @@
    Tpat (function
        | "index0" -> Tint i
        | "index" -> Tint (i+1)
        | "revindex0" -> Tint (len - i - 1)
        | "revindex" -> Tint (len - i)
        | "first" -> Tbool (i=0)
        | "last" -> Tbool (i=len-1)
        | "length" -> Tint len
        | "cycle" -> cycle
        | _ -> raise Not_found
      ) in
  ctx

let jg_iter_hash ctx iterator f h =
  let i = ref 0 in
  let len = Hashtbl.length h in
  Hashtbl.iter
    (fun k v ->
       let itm = Tset [ box_string k ; v ] in
       let () = f @@ jg_iter_mk_ctx ctx iterator itm len (!i) in
       incr i)
    h

let jg_iter_obj ctx iterator f l =
  let len = List.length l in
  List.iteri
    (fun i (k, v) ->
       let itm = Tset [ box_string k ; v ] in
       f @@ jg_iter_mk_ctx ctx iterator itm len i)
    l

let jg_iter_array ctx iterator f a =
  let len = Array.length a in
  Array.iteri (fun i itm -> f @@ jg_iter_mk_ctx ctx iterator itm len i) a

let jg_iter_str ctx iterator f s =
  let len = String.length s in
  String.iteri (fun i itm ->
      let itm = Tstr (String.make 1 itm) in
      f @@ jg_iter_mk_ctx ctx iterator itm len i) s

let jg_iter ctx iterator f iterable =
  match iterable with
  | Thash h -> jg_iter_hash ctx iterator f h
  | Tobj l -> jg_iter_obj ctx iterator f l
  | Tarray a -> jg_iter_array ctx iterator f a
  | Tstr s -> jg_iter_str ctx iterator f s
  | Tlist l | Tset l ->
    let len = List.length l in
    List.iteri (fun i itm -> f @@ jg_iter_mk_ctx ctx iterator itm len i) l
  | _ -> ()

let jg_eval_macro ?(caller=false) env ctx macro_name args kwargs macro f =
  let Macro (arg_names, defaults, code) = macro in
  let args_len = List.length args in
  let arg_names_len = List.length arg_names in
  let ctx' = jg_push_frame ctx in
  let ctx' = jg_set_value ctx' "varargs" @@ Tlist (Jg_utils.after arg_names_len args) in
  let ctx' = jg_set_value ctx' "kwargs" @@ Tobj kwargs in
  let ctx' = jg_set_value ctx' macro_name @@ Tpat (function
      | "name" -> Tstr macro_name
      | "arguments" -> Tlist (List.map box_string arg_names)
      | "defaults" -> Tobj defaults
      | "catch_kwargs" -> Tbool (kwargs <> [])
      | "catch_vargs" -> Tbool (args_len > arg_names_len)
      | "caller" -> Tbool caller
      | _ -> raise Not_found
    ) in
  let ctx' = List.fold_left2 (fun ctx' name value ->
      jg_set_value ctx' name value
    ) ctx' arg_names (Jg_utils.take arg_names_len args ~pad:Tnull) in
  let ctx' = List.fold_left (fun ctx' (name, value) ->
      jg_set_value ctx' name value
    ) ctx' @@ List.map (fun (name, value) ->
      try (name, List.assoc name kwargs) with Not_found -> (name, value)
    ) defaults in
  let ctx' = List.fold_left (fun ctx' (name, value) ->
      try jg_set_value ctx' name @@ List.assoc name kwargs with Not_found ->
	jg_set_value ctx' name value
    ) ctx' defaults in
  let _ = f ctx' code in
  ctx

let jg_test_defined ctx name =
  match jg_get_value ctx name with
    | Tnull -> Tbool(false)
    | _ -> Tbool(true)

let jg_test_undefined ctx name =
  match jg_test_defined ctx name with
    | Tbool status -> Tbool (not status)
    | _ -> failwith "invalid test:jg_test_defined"

let jg_test_obj_defined ctx obj_name prop_name =
  match jg_get_value ctx obj_name with
    | Tobj(alist) -> Tbool (List.mem_assoc prop_name alist)
    | _ -> Tbool(false)

let jg_test_obj_undefined ctx obj_name prop_name =
  match jg_test_obj_defined ctx obj_name prop_name with
    | Tbool status -> Tbool (not status)
    | _ -> failwith "invalid test:jg_test_obj_defined"

let jg_test_escaped ctx =
  Tbool(List.mem "safe" @@ ctx.active_filters)

let jg_test_none ctx name =
  match jg_get_value ctx name with
    | Tnull -> Tbool(true)
    | _ -> Tbool(false)

let jg_negative = function
  | Tint x -> Tint(-x)
  | Tfloat x -> Tfloat(-.x)
  | _ -> failwith "jg_negative:type error"

let rec jg_is_true = function
  | Tbool x -> x
  | Tstr x -> x <> ""
  | Tint x -> x != 0
  | Tfloat x -> (x > epsilon_float) || (x < -. epsilon_float)
  | Tlist x -> List.length x > 0
  | Tset x -> List.length x > 0
  | Tobj x -> List.length x > 0
  | Thash x -> Hashtbl.length x > 0
  | Tpat _ -> true
  | Tnull -> false
  | Tfun(f) -> failwith "jg_is_true:type error(function)"
  | Tarray a -> Array.length a > 0
  | Tlazy fn -> jg_is_true (Lazy.force fn)
  | Tvolatile fn -> jg_is_true (fn ())

let jg_not x =
  Tbool (not (jg_is_true x))

let jg_plus left right =
  match left, right with
    | Tint x1, Tint x2 -> Tint(x1+x2)
    | Tint x1, Tfloat x2 -> Tfloat(float_of_int x1+.x2)
    | Tint x1, Tstr x2 -> Tstr (string_of_int x1 ^ x2)

    | Tfloat x1, Tfloat x2 -> Tfloat(x1+.x2)
    | Tfloat x1, Tint x2 -> Tfloat(x1+.float_of_int x2)
    | Tfloat x1, Tstr x2 -> Tstr (string_of_float x1 ^ x2)

    | Tstr x1, Tstr x2 -> Tstr (x1 ^ x2)
    | Tstr x1, Tint x2 -> Tstr (x1 ^ string_of_int x2)
    | Tstr x1, Tfloat x2 -> Tstr (x1 ^ string_of_float x2)

    | _, _ -> failwith "jg_plus:type error"

let jg_minus left right =
  match left, right with
    | Tint x1, Tint x2 -> Tint(x1-x2)
    | Tfloat x1, Tfloat x2 -> Tfloat(x1-.x2)
    | Tint x1, Tfloat x2 -> Tfloat(float_of_int x1-.x2)
    | Tfloat x1, Tint x2 -> Tfloat(x1-.float_of_int x2)
    | _, _ -> failwith "jg_minus:type error"

let jg_times left right =
  match left, right with
    | Tint x1, Tint x2 -> Tint(x1*x2)
    | Tfloat x1, Tfloat x2 -> Tfloat(x1*.x2)
    | Tint x1, Tfloat x2 -> Tfloat(float_of_int x1*.x2)
    | Tfloat x1, Tint x2 -> Tfloat(x1*.float_of_int x2)
    | _, _ -> failwith "jg_times:type error"

let jg_power left right =
  let rec power m n a =
    if n <= 0 then a
    else if n mod 2 = 0 then power (m *. m) (n / 2) a
    else power m (n - 1) (m *. a) in
  match left, right with
    | Tint x1, Tint x2 -> Tfloat (power (float_of_int x1) x2 1.0)
    | _, _ -> failwith "jg_powew:type error"

let jg_div left right =
  match left, right with
    | _, Tint 0 -> failwith "jg_div:zero division error"
    | _, Tfloat 0.0 -> failwith "jg_div:zero division error"
    | Tint x1, Tint x2 -> Tint(x1/x2)
    | Tfloat x1, Tfloat x2 -> Tfloat(x1/.x2)
    | Tint x1, Tfloat x2-> Tfloat(float_of_int x1/.x2)
    | Tfloat x1, Tint x2 -> Tfloat(x1/.float_of_int x2)
    | _, _ -> failwith "jg_div:type error"

let jg_mod left right =
  match left, right with
    | _, Tint 0 -> failwith "jg_mod:zero division error"
    | Tint x1, Tint x2 -> Tint(x1 mod x2)
    | _, _ -> failwith "jg_mod:type error"

let jg_and left right =
  Tbool(jg_is_true left && jg_is_true right)

let jg_or left right =
  Tbool(jg_is_true left || jg_is_true right)

let rec jg_compare_list
  : 'a . filter:('a -> tvalue) -> 'a list -> 'a list -> int =
  fun ~filter x1 x2 -> match x1, x2 with
    | [], [] -> 0
    | [], _ -> -1
    | _, [] -> 1
    | x1 :: acc1, x2 :: acc2 ->
      match jg_compare (filter x1) (filter x2) with
      | 0 -> compare acc1 acc2
      | c -> c

and jg_compare_obj left right = match left, right with
  | Tobj x1, Tobj x2 ->
    jg_compare_list ~filter:snd
      (List.sort (fun (a, _) (b, _) -> compare a b) x1)
      (List.sort (fun (a, _) (b, _) -> compare a b) x2)
  | Thash x1, Thash x2 ->
    let x1 = Hashtbl.fold (fun k v acc -> (k, v) :: acc) x1 [] in
    let x2 = Hashtbl.fold (fun k v acc -> (k, v) :: acc) x2 [] in
    jg_compare_obj (Tobj x1) (Tobj x2)
  | _ -> -1

and jg_compare left right = match left, right with
  | Tint x1, Tint x2 -> compare x1 x2
  | Tfloat x1, Tfloat x2 -> compare x1 x2
  | Tstr x1, Tstr x2 -> strcmp x1 x2
  | Tbool x1, Tbool x2 -> compare x1 x2
  | Tlist x1, Tlist x2 -> jg_compare_list ~filter:(fun x -> x) x1 x2
  | Tset x1, Tset x2 -> jg_compare_list ~filter:(fun x -> x) x1 x2
  | Tarray x1, Tarray x2 ->
    begin
      let l1 = Array.length x1 in
      let l2 = Array.length x2 in
      match compare l1 l2 with
      | 0 ->
        let rec loop i =
          if i = l1 then 0
          else match jg_compare x1.(i) x2.(i) with
            | 0 -> loop (i + 1)
            | c -> c
        in loop 0
      | c -> c
    end
  | (Tpat _ | Thash _ | Tobj _), (Tpat _ | Thash _ | Tobj _) ->
    begin
      try unbox_int @@ jg_apply (jg_obj_lookup left "__compare__") [ left ; right ]
      with Not_found -> jg_compare_obj left right
    end
  | _, _ -> -1

let rec jg_eq_eq_aux left right =
  match left, right with
    | Tint x1, Tint x2 -> x1=x2
    | Tfloat x1, Tfloat x2 -> x1=x2
    | Tstr x1, Tstr x2 -> x1=x2
    | Tbool x1, Tbool x2 -> x1=x2
    | Tlist x1, Tlist x2
    | Tset x1, Tset x2 -> jg_list_eq_eq x1 x2
    | Tobj x1, Tobj x2 -> jg_obj_eq_eq left right
    | Tarray x1, Tarray x2 -> jg_array_eq_eq x1 x2
    | _, _ -> false

(* Copied from Array module to ensure compatibility with 4.02 *)
and array_iter2 f a b =
  let open Array in
  if length a <> length b then
    invalid_arg "Array.iter2: arrays must have the same length"
  else
    for i = 0 to length a - 1 do f (unsafe_get a i) (unsafe_get b i) done

and jg_array_eq_eq a1 a2 =
  try
    array_iter2
      (fun a b ->
         if not @@ jg_eq_eq_aux a b
         then raise @@ Invalid_argument "jg_array_eq_eq")
      a1 a2 ;
    true
  with
    Invalid_argument _ -> false

and jg_list_eq_eq l1 l2 =
  List.length l1 = List.length l2
  && List.for_all2 jg_eq_eq_aux l1 l2

and jg_obj_eq_eq obj1 obj2 =
  let alist1 = unbox_obj obj1 in
  let alist2 = unbox_obj obj2 in
  List.length alist1 = List.length alist2
  &&
  try
    List.for_all
      (fun (prop, value) -> jg_eq_eq_aux value (List.assoc prop alist2))
      alist1
  with
    Not_found -> false

let jg_eq_eq left right =
  Tbool (jg_eq_eq_aux left right)

let jg_not_eq left right =
  Tbool (not @@ jg_eq_eq_aux left right)

let jg_lt left right =
  match left, right with
    | Tint x1, Tint x2 -> Tbool(x1<x2)
    | Tfloat x1, Tfloat x2 -> Tbool(x1<x2)
    | Tstr x1, Tstr x2 -> Tbool(x1<x2)
    | _, _ -> failwith "jg_lt:type error"

let jg_gt left right =
  match left, right with
    | Tint x1, Tint x2 -> Tbool(x1>x2)
    | Tfloat x1, Tfloat x2 -> Tbool(x1>x2)
    | Tstr x1, Tstr x2 -> Tbool(x1>x2)
    | _, _ -> failwith "jg_gt:type error"

let jg_lteq left right =
  match left, right with
    | Tint x1, Tint x2 -> Tbool(x1<=x2)
    | Tfloat x1, Tfloat x2 -> Tbool(x1<=x2)
    | Tstr x1, Tstr x2 -> Tbool(x1<=x2)
    | _, _ -> failwith "jg_lteq:type error"

let jg_gteq left right =
  match left, right with
    | Tint x1, Tint x2 -> Tbool(x1>=x2)
    | Tfloat x1, Tfloat x2 -> Tbool(x1>=x2)
    | Tstr x1, Tstr x2 -> Tbool(x1>=x2)
    | _, _ -> failwith "jg_gteq:type error"

(* Copied from Array module to ensure compatibility with 4.02 *)
let array_exists p a =
  let n = Array.length a in
  let rec loop i =
    if i = n then false
    else if p (Array.unsafe_get a i) then true
    else loop (succ i) in
  loop 0

let jg_inop left right =
  match left, right with
    | value, Tlist lst -> Tbool (List.exists (jg_eq_eq_aux value) lst)
    | value, Tarray a -> Tbool (array_exists (jg_eq_eq_aux value) a)
    | _ -> Tbool false

let jg_get_kvalue ?(defaults=[]) name kwargs =
  try List.assoc name kwargs with Not_found ->
    (try List.assoc name defaults with Not_found -> Tnull)

let jg_safe value kwargs =
  value

let jg_upper x kwargs =
  match x with
    | Tstr str -> Tstr (String.uppercase str)
    | other -> Tstr (string_of_tvalue other)

let jg_lower x kwargs =
  match x with
    | Tstr str -> Tstr (String.lowercase str)
    | other -> Tstr (string_of_tvalue other)

let jg_int x kwargs =
  match x with
    | Tint x -> Tint x
    | Tfloat x -> Tint (int_of_float  x)
    | Tstr s -> Tint (int_of_string s)
    | _ -> failwith "invalid arg:not number(jg_int)"

let jg_float x kwargs =
  match x with
    | Tfloat x -> Tfloat x
    | Tint x -> Tfloat (float_of_int x)
    | Tstr s -> Tfloat (float_of_string s)
    | _ -> failwith "invalid arg:not number(jg_float)"

let jg_join join_str lst kwargs =
  match join_str, lst with
    | Tstr str, Tlist lst
    | Tstr str, Tset lst ->
      Tstr (String.concat str (List.map string_of_tvalue lst))
    | Tstr str, Tarray array ->
      let buf = Buffer.create 256 in
      let () =
        Array.iteri
          (fun i v ->
             if i > 0 then Buffer.add_string buf str ;
             Buffer.add_string buf (string_of_tvalue v) )
          array
      in Tstr (Buffer.contents buf)
    | _ -> failwith "invalid arg:jg_join"

let jg_split pat text kwargs =
  match pat, text with
    | Tstr pat, Tstr text ->
      let lst =
	Pcre.split ~rex:(Pcre.regexp pat) text |>
	  List.map (fun str -> Tstr str) in
      Tlist lst

  | _ -> failwith "invalid args: split"

let jg_substring base count str kwargs =
  match base, count, str with
    | Tint base, Tint count, Tstr str ->
      Tstr (substring base count str)
    | Tint _, Tint _, Tnull ->
      Tstr ""
    | _ -> failwith "invalid args: substring"

let jg_truncate len str kwargs =
  match len, str with
    | Tint len, Tstr str ->
      Tstr (substring 0 len str)

    | _ -> failwith "invalid args: truncate"

let jg_strlen x kwargs =
  match x with
    | Tstr str -> Tint (Jg_utils.strlen str)
    | _ -> failwith "invalid args: strlen"

let jg_length x kwargs =
  match x with
    | Tlist lst -> Tint (List.length lst)
    | Tset lst -> Tint (List.length lst)
    | Tstr str -> Tint (Jg_utils.strlen str)
    | Tarray arr -> Tint (Array.length arr)
    | _ -> failwith "invalid args: not list(length)"

let jg_md5 x kwargs =
  match x with
    | Tstr str ->
      Tstr(str |> String.lowercase |> Digest.string |> Digest.to_hex)
    | _ -> failwith "invalid arg: not string(jg_md5)"

let jg_abs value kwargs =
  match value with
    | Tint x -> Tint (abs x)
    | _ -> failwith "type error: not integer(abs)"

let jg_attr obj prop kwargs =
  match obj, prop with
    | Tobj alist, Tstr prop ->
      (try List.assoc prop alist with Not_found -> Tnull)
    | Thash htbl, Tstr prop ->
      (try Hashtbl.find htbl prop with Not_found -> Tnull)
    | Tpat fn, Tstr prop ->
      (try fn prop with Not_found -> Tnull)
    | _ -> Tnull

let jg_batch ?(defaults=[
  ("fill_with", Tnull)
]) count value kwargs =
  let fill_value = match jg_get_kvalue "fill_with" kwargs ~defaults with Tnull -> None | other -> Some other in
  match count, value with
    | Tint slice_count, Tlist lst ->
      let rec batch ret left_count rest =
	if left_count > slice_count then
	  batch ((box_list @@ take slice_count rest) :: ret) (left_count - slice_count) (after slice_count rest)
	else if left_count > 0 then
	  batch ((box_list @@ take slice_count rest ?pad:fill_value) :: ret) 0 []
	else
	  box_list @@ List.rev ret in
      batch [] (List.length lst) lst
    | Tint slice_count, Tarray ary ->
       failwith "not supported yet."
    | _ -> failwith "invalid args: batch"

let jg_center ?(defaults=[
  ("width", Tint 80)
]) value kwargs =
  value (* TODO *)

let jg_capitalize value kwargs =
  match value with
    | Tstr str -> Tstr (String.capitalize str)
    | _ -> failwith "invalid args: not string(capitalize)"

let jg_default default value kwargs =
  match value with
    | Tnull -> default
    | other -> other

let jg_dictsort ?(defaults=[
  (* these optional arguments are ignored yet *)
  ("case_sensitive", Tbool true);
  ("by", Tstr "key");
]) value kwargs =
  match value with
    | Tobj alist ->
      Tobj (List.sort (fun a b -> String.compare (fst a) (fst b)) alist)
    | _ -> value

let jg_reverse lst kwargs =
  match lst with
    | Tlist lst -> Tlist (List.rev lst)
    | Tarray a ->
      let len = Array.length a in
      Tarray (Array.init len (fun i -> Array.get a (len - 1 - i)))
    | _ -> failwith "invalid args: not list(jg_reverse)"

let jg_last lst kwargs =
  match lst with
    | Tlist lst
    | Tset lst ->
      let rec last = function
        | [] -> List.hd [] (* same exception as previous implementation *)
        | [x] -> x
        | _ :: tl -> last tl in
      last lst
    | Tarray a -> Array.get a (Array.length a - 1)
    | _ -> failwith "invalid args: not list(jg_last)"

let jg_random lst kwargs =
  let knuth a =
    for i = Array.length a - 1 downto 1 do
      let j = Random.int i in
      let t = a.(i) in
      a.(i) <- a.(j);
      a.(j) <- t
    done ;
    a
  in
  match lst with
    | Tlist l -> Tlist (Array.to_list @@ knuth @@ Array.of_list l)
    | Tarray a -> Tarray (knuth @@ Array.copy a)
    | _ -> failwith "invalid args: not list or array(jg_random)"

let jg_replace src dst str kwargs =
  match src, dst, str with
    | Tstr src, Tstr dst, Tstr str ->
      Tstr (Pcre.replace ~rex:(Pcre.regexp src ~flags:[`UTF8]) ~templ:dst str)
    | _ -> failwith "invalid arg:not string(jg_replace)"

let jg_add a b = match a, b with
  | Tint a, Tint b -> Tint (a + b)
  | Tfloat a, Tfloat b -> Tfloat (a +. b)
  | Tint a, Tfloat b
  | Tfloat b, Tint a -> Tfloat (float_of_int a +. b)
  | _ -> failwith "invalid args:non numerical list(jg_add)"

let jg_sum lst kwargs =
  match lst with
  | Tset l
  | Tlist l -> List.fold_left jg_add (Tint 0) l
  | Tarray a -> Array.fold_left jg_add (Tint 0) a
  | _ -> failwith "invalid args: not list(jg_sum)"

let jg_trim str kwargs =
  match str with
    | Tstr str -> Tstr (String.trim str)
    | _ -> failwith "invalid args: not string(jg_trim)"

let jg_list value kwargs =
  match  value with
    | Tlist lst | Tset lst -> Tlist lst
    | Tstr str ->
      let len = strlen str in
      let rec iter ret i =
	if i >= len then
	  List.rev ret
	else
	  let s1 = Tstr (substring i 1 str) in
	  iter (s1 :: ret) (i+1) in
      Tlist (iter [] 0)
    | Tarray a -> Tlist (Array.to_list a)
    | _ -> failwith "invalid_arg:can't make sequence(jg_list)"

let jg_slice ?(defaults=[
  ("fill_with", Tnull);
]) len value kwargs =
  jg_batch len (jg_list value []) kwargs

let jg_sublist base count lst kwargs =
  match base, count, lst with
    | Tint base, Tint count, Tlist lst -> Tlist (after base lst |> take count)
    | Tint base, Tnull, Tlist lst -> Tlist (after base lst)
    | _ -> failwith "lnvalid args:jg_sublist"

let jg_wordcount str kwargs =
  match str with
    | Tstr str ->
      Pcre.split ~rex:(Pcre.regexp "[\\s\\t　]+" ~flags:[`UTF8]) str |>
	List.length |> fun count -> Tint count
    | _ -> failwith "invalid arg: not string(jg_word_count)"

let jg_round how value kwargs =
  match how, value with
    | _, Tint x -> Tint x
    | Tstr "floor", Tfloat x -> Tfloat (floor x)
    | Tstr ("ceil" | "common"), Tfloat x -> Tfloat (ceil x)
    | Tstr other, Tfloat x ->
      failwith @@
      spf "invalid args:round method %s not supported(jg_round)" other
    | _ -> failwith "invalid args:jg_round"

let jg_fmt_float digit_count value kwargs =
  match digit_count, value with
    | Tint digit_count, Tfloat value ->
      let fmt = Scanf.format_from_string (spf "%%.%df" digit_count) "%f" in
      Tfloat (float_of_string @@ spf fmt value)
    | _, _ -> failwith "invalid args:fmt_float(digit_count, float_value)"

let jg_range start stop kwargs =
  match start, stop with
    | Tint start, Tint stop ->
      if start = stop then
	Tlist [Tint start]
      else
	let is_end i = if start < stop then i > stop else i < stop in
	let next i = if start < stop then i + 1 else i - 1 in
	let rec iter ret i = if is_end i then List.rev ret else iter ((Tint i) :: ret) (next i) in
	Tlist (iter [] start)
    | _ -> failwith "invalid args: not int(jg_range)"

let jg_urlize text kwargs =
  match text with
    | Tstr text ->
      let reg = Pcre.regexp "((http|ftp|https):\\/\\/[\\w\\-_]+(\\.[\\w\\-_]+)+([\\w\\-\\.,@?^=%&amp;:/~\\+#]*[\\w\\-\\@?^=%&amp;/~\\+#])?)" in
      Tstr (Pcre.replace ~rex:reg ~templ:"<a href='$1'>$1</a>" text)
    | _ -> failwith "invalid arg: not string(jg_urlize)"

let jg_title text kwargs =
  match text with
    | Tstr text ->
      (match Pcre.split ~rex:(Pcre.regexp "[\\s\\t　]+" ~flags:[`UTF8]) text with
	| head :: rest ->
	  ((String.capitalize head) :: rest) |> String.concat " " |> fun text' -> Tstr text'
	| _ -> Tstr text)
    | _ -> failwith "invalid arg: not string(jg_title)"

let jg_striptags text kwargs =
  match text with
    | Tstr text ->
      let reg = Pcre.regexp "<\\/?[^>]+>" ~flags:[`UTF8] in
      let text' = Pcre.replace ~rex:reg ~templ:"" text in
      Tstr text'
    | _ -> failwith "invalid arg: not string(jg_striptags)"

(* Copy of String.split_on_char which is available in 4.04 *)
let string_split_on_char sep s =
  let open String in
  let r = ref [] in
  let j = ref (length s) in
  for i = length s - 1 downto 0 do
    if unsafe_get s i = sep then begin
      r := sub s (i + 1) (!j - i - 1) :: !r;
      j := i
    end
  done;
sub s 0 !j :: !r

let jg_sort lst kwargs =
  let reverse = ref false in
  let attribute = ref "" in
  List.iter (function ("reverse", Tbool true) -> reverse := true
                    | ("attribute", Tstr name) -> attribute := name
                    | (kw, _) -> failwith kw) kwargs;
  let compare = match !attribute with
    | "" -> jg_compare
    | att ->
      let path = string_split_on_char '.' att in
      fun a b -> jg_compare (jg_obj_lookup_path a path) (jg_obj_lookup_path b path) in
  let compare = if !reverse then fun a b -> compare b a else compare in
  match lst with
    | Tlist l -> Tlist (List.sort compare l)
    | Tarray a -> Tarray (let a = Array.copy a in Array.sort compare a ; a)
    | x -> failwith @@ spf "invalid_arg:can't sort %s (jg_sort)" (type_string_of_tvalue x)

let jg_xmlattr obj kwargs =
  match obj with
    | Tobj alist ->
      List.map (fun (name, value) -> spf "%s='%s'" name (string_of_tvalue value)) alist |>
	String.concat " " |> box_string
    | _ -> failwith "invalid_arg:not obj(jg_xmlattr)"

let jg_wordwrap width break_long_words text kwargs =
  match width, break_long_words, text with
    | Tint width, Tbool break_long_words, Tstr text ->
      let concat_line s1 s2 = if s1 = "" then s2 else String.concat " " [s1; s2] in
      let push_line s1 s2 = if s1 = "" then s2 else String.concat "\n" [s1; s2] in
      let rec iter lines line count = function
	| "" :: rest -> iter lines line count rest
	| word :: rest ->
	  let len = strlen word in
	  if count + len + 1 <= width then
	    iter lines (concat_line line word) (count + len + 1) rest
	  else if break_long_words then
	    let left_len = width - count in
	    let over_len = len + 1 - left_len in
	    let left_word = substring 0 left_len word in
	    let over_word = substring left_len over_len word in
	    iter (push_line lines @@ concat_line line left_word) "" 0 (over_word :: rest)
	  else
	    iter (push_line lines @@ concat_line line word) "" 0 rest
	| [] -> if line = "" then lines else push_line lines line in
      let words = Pcre.split ~rex:(Pcre.regexp "[\\s\\t　]+" ~flags:[`UTF8]) text in
      Tstr (iter "" "" 0 words)
    | _ -> failwith "invalid args:jg_wordwrap"

module JgHashtbl = Hashtbl.Make (struct
    type t = Jg_types.tvalue
    let equal a b = jg_compare a b = 0
    let hash = Hashtbl.hash
  end)

let jg_groupby_aux key length iter collection =
  let path = string_split_on_char '.' key in
  let h = JgHashtbl.create length in
  iter
    (fun obj ->
      let k = jg_obj_lookup_path obj path in
      if JgHashtbl.mem h k then
        JgHashtbl.replace h k (obj :: JgHashtbl.find h k)
      else
        JgHashtbl.add h k [obj]) collection;
  box_list @@ JgHashtbl.fold
    (fun key list acc ->
      Tpat (function
      | "grouper" -> key
      | "list" -> Tlist (List.rev list)
      | _ -> raise Not_found) :: acc)
    h []

let jg_groupby key value kwargs =
  match key with
  | Tstr key -> begin
      match value with
      | Tarray ary -> jg_groupby_aux key (Array.length ary) Array.iter ary
      | Tlist list -> jg_groupby_aux key (List.length list) List.iter list
      | _ -> failwith "invalid arg: not list nor array(jg_groupby value)"
    end
  | _ -> failwith "invalid arg: not str(jg_groupby key)"

let jg_test_divisibleby num target kwargs =
  match num, target with
    | Tint 0, _ -> Tbool(false)
    | Tint n, Tint t ->  Tbool(t mod n = 0)
    | _ -> Tbool(false)

let jg_test_even x kwargs =
  match x with
    | Tint x -> Tbool(x mod 2 = 0)
    | _ -> Tbool(false)

let jg_test_odd x kwargs =
  match x with
    | Tint x -> Tbool(x mod 2 = 1)
    | _ -> Tbool(false)

let jg_test_iterable x kwargs =
  Tbool (is_iterable x)

let jg_test_lower x kwargs =
  match x with
    | Tstr str -> Tbool(Jg_utils.is_lower str)
    | _ -> Tbool(false)

let jg_test_upper x kwargs =
  match x with
    | Tstr str -> Tbool(Jg_utils.is_upper str)
    | _ -> Tbool(false)

let jg_test_number x kwargs =
  match x with
    | Tint _ -> Tbool(true)
    | Tfloat _ -> Tbool(true)
    | _ -> Tbool(false)

let jg_test_sameas value target kwargs =
  match value, target with
    | Tstr x, Tstr y -> Tbool(x == y)
    | Tint x, Tint y -> Tbool(x == y)
    | Tfloat x, Tfloat y -> Tbool(x == y)
    | Tbool x, Tbool y -> Tbool(x == y)
    | Tfun x, Tfun y -> Tbool(x == y)
    | Tobj x, Tobj y -> Tbool(x == y)
    | Tlist x, Tlist y -> Tbool(x == y)
    | Tset x, Tset y -> Tbool(x == y)
    | Tarray x, Tarray y -> Tbool(x == y)
    | _ -> Tbool(false)

let jg_test_sequence target kwargs =
  jg_test_iterable target kwargs

let jg_test_string target kwargs =
  jg_strp target

let func_arg0 f = Tfun (fun args kwargs ->
  f kwargs ()
)

let func_arg1 f = Tfun (fun args kwargs ->
  match args with
    | a1 :: rest -> f a1 kwargs
    | _ -> Tnull
)

let func_arg2 f = Tfun (fun args kwargs ->
  match args with
    | a1 :: a2 :: rest -> f a1 a2 kwargs
    | a1 :: rest -> func_arg1 (f a1)
    | _ -> Tnull
)

let func_arg3 f = Tfun (fun args kwargs ->
  match args with
    | a1 :: a2 :: a3 :: rest -> f a1 a2 a3 kwargs
    | a1 :: a2 :: rest -> func_arg1 (f a1 a2)
    | a1 :: rest -> func_arg2 (f a1)
    | _ -> Tnull
)

let std_filters = [
  (** built-in filters *)
  ("abs", func_arg1 jg_abs);
  ("capitalize", func_arg1 jg_capitalize);
  ("escape", func_arg1 jg_escape_html);
  ("e", func_arg1 jg_escape_html); (* alias for escape *)
  ("float", func_arg1 jg_float);
  ("int", func_arg1 jg_int);
  ("last", func_arg1 jg_last);
  ("length", func_arg1 jg_length);
  ("list", func_arg1 jg_list);
  ("lower", func_arg1 jg_lower);
  ("md5", func_arg1 jg_md5);
  ("safe", func_arg1 jg_safe);
  ("strlen", func_arg1 jg_strlen);
  ("sum", func_arg1 jg_sum);
  ("striptags", func_arg1 jg_striptags);
  ("sort", func_arg1 jg_sort);
  ("upper", func_arg1 jg_upper);
  ("random", func_arg1 jg_random);
  ("reverse", func_arg1 jg_reverse);
  ("title", func_arg1 jg_title);
  ("trim", func_arg1 jg_trim);
  ("urlize", func_arg1 jg_urlize);
  ("wordcount", func_arg1 jg_wordcount);
  ("xmlattr", func_arg1 jg_xmlattr);

  ("attr", func_arg2 jg_attr);
  ("batch", func_arg2 jg_batch);
  ("default", func_arg2 jg_default);
  ("d", func_arg2 jg_default); (* alias for default *)
  ("fmt_float", func_arg2 jg_fmt_float);
  ("join", func_arg2 jg_join);
  ("split", func_arg2 jg_split);
  ("slice", func_arg2 jg_slice);
  ("truncate", func_arg2 jg_truncate);
  ("range", func_arg2 jg_range);
  ("round", func_arg2 jg_round);
  ("groupby", func_arg2 jg_groupby);

  ("replace", func_arg3 jg_replace);
  ("substring", func_arg3 jg_substring);
  ("sublist", func_arg3 jg_sublist);
  ("wordwrap", func_arg3 jg_wordwrap);

  (** built-in tests *)
  ("divisibleby", func_arg2 jg_test_divisibleby);
  ("even", func_arg1 jg_test_even);
  ("iterable", func_arg1 jg_test_iterable);
  ("number", func_arg1 jg_test_number);
  ("odd", func_arg1 jg_test_odd);
  ("sameas", func_arg2 jg_test_sameas);
  ("sequence", func_arg1 jg_test_sequence);
  ("string", func_arg1 jg_test_string);
]

let jg_load_extensions extensions =
  List.iter (fun ext ->
    try
      Dynlink.loadfile ext
    with
	Dynlink.Error e -> failwith @@ Dynlink.error_message e
  ) extensions

let jg_init_context ?(models=[]) output env =
  let model_frame = Hashtbl.create (2 * List.length models) in
  let top_frame = Hashtbl.create (List.length std_filters + List.length env.filters + 2) in
  let rec set_values hash alist = List.fold_left (fun h (n, v) -> Hashtbl.add h n v; h) hash alist in
  ignore @@ set_values model_frame models;
  ignore @@ set_values top_frame std_filters;
  ignore @@ set_values top_frame env.filters;
  ignore @@ set_values top_frame [
    ("jg_is_autoescape", Tbool env.autoescape);
  ];
  { frame_stack = [model_frame; top_frame];
    macro_table = Hashtbl.create 10;
    namespace_table = Hashtbl.create 10;
    active_filters = [];
    output
  }
