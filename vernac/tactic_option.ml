(************************************************************************)
(*         *      The Rocq Prover / The Rocq Development Team           *)
(*  v      *         Copyright INRIA, CNRS and contributors             *)
(* <O___,, * (see version control and CREDITS file for authors & dates) *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

open Libobject

type tac_option_locality =
  | Default
  | Global
  | Local
  | Export
  | GlobalAndExport

let tac_option_locality =
  let open Attributes in
  let open Attributes.Notations in
  let one x = attribute_of_list [x,single_key_parser ~name:"Locality" ~key:x ()] in
  one "local" ++ one "global" ++ one "export" >>= fun ((local,global),export) ->
  match local, global, export with
  | None, None, None -> return Default

  | Some (), Some (), _ -> CErrors.user_err Pp.(str "Cannot combine local and global.")
  | Some (), _, Some () -> CErrors.user_err Pp.(str "Cannot combine local and export.")

  | Some (), None, None -> return Local
  | None, Some (), None -> return Global
  | None, None, Some () -> return Export
  | None, Some (), Some () -> return GlobalAndExport

let warn_default_locality =
  CWarnings.create ~name:"deprecated-tacopt-without-locality" ~category:Deprecation.Version.v8_17 Pp.(fun () ->
      strbrk
        "The default and global localities for this command outside \
         sections are currently equivalent to the combination of the \
         standard meaning of \"global\" (as described in the reference \
         manual), \"export\" and re-exporting for every surrounding \
         module. It will change to just \"global\" (with the meaning \
         used by the \"Set\" command) in a future release." ++ fnl() ++
      strbrk
        "To preserve the current meaning in a forward compatible way, \
         use the attribute \"#[global,export]\" and repeat the command \
         with just \"#[export]\" in any surrounding modules. If you \
         are fine with the change of semantics, disable this warning.")

let declare_tactic_option ?default name =
  let current_tactic : Gentactic.glob_generic_tactic option ref =
    Summary.ref default ~name:(name^"-default-tactic")
  in
  let set_current_tactic t =
    current_tactic := t
  in
  let cache (_, tac) = set_current_tactic tac in
  let load _ (local, tac) = match local with
    | Default | Global | GlobalAndExport -> set_current_tactic tac
    | Export -> ()
    | Local -> assert false (* not allowed by classify *)
  in
  let import i (local, tac) = match local with
    | GlobalAndExport | Export -> if Int.equal i 1 then set_current_tactic tac
    | Default | Global -> set_current_tactic tac
    | Local -> assert false (* not allowed by classify *)
  in
  let classify (local, _) = match local with
    | Local -> Dispose
    | Default | Global | Export | GlobalAndExport -> Substitute
  in
  let subst (s, (local, tac)) =
    (local, Option.map (Gentactic.subst s) tac)
  in
  let input : tac_option_locality * Gentactic.glob_generic_tactic option -> obj =
    declare_object
      { (default_object name) with
        cache_function = cache;
        load_function = load;
        (* can't simple_open: crappy behaviour when superglobal *)
        open_function = filtered_open import;
        classify_function = classify;
        subst_function = subst}
  in
  let put ?loc local tac =
    let () = match local with
      | Default -> if not (Lib.sections_are_opened()) then warn_default_locality ?loc ()
      | Local -> ()
      | Export | Global | GlobalAndExport ->
        if Lib.sections_are_opened()
        then CErrors.user_err ?loc
            Pp.(str "This locality is not supported inside sections by this command.")
    in
    Lib.add_leaf (input (local, Some tac))
  in
  let get () = match !current_tactic with
    | None -> Proofview.tclUNIT ()
    | Some tac -> Gentactic.interp tac
  in
  let print () = match !current_tactic with
    | None -> Pp.str "<unset>"
    | Some tac ->
      let env = Global.env () in
      let sigma = Evd.from_env env in
      Gentactic.print_glob env sigma tac
  in
  put, get, print
