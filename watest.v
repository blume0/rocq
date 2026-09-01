Require Import Vector.

Set SmallInversion Debug.

(* Section s. *)
(* Parameter S T : Type.
 * Parameter f : S -> T.
 *
 * Inductive Imf : T -> Type :=
 * | imf : forall (s : S), Imf (f s).
 *
 * Definition inv (t : T) (p : Imf t) : {s : S | t = f s} :=
 *    match p as p in Imf t0 return {s : S | t0 = f s} with
 *    | imf s => exist _ s eq_refl
 *    end. *)
(* End s. *)

Inductive T := tt.
Check tt : T.

#[universes(polymorphic=yes)]
Inductive eq : forall A : Type, A -> A -> Type :=
| refl : forall A a, eq A a a.

Definition weakK (e : eq (eq T tt tt) (refl T tt) (refl T tt)):
    e = refl (eq T tt tt) (refl T tt).
Proof.
Fail refine (
    (* We cannot express the refined pattern of the in-clause
     * with its 'refl' constructors without being ill-typed.
     * Here: 'refl T_1 tt' needs to be of type T_0 but is of type
     * 'eq T_1 tt tt' *)
    match e as e_as in eq T_0 (refl T_1 tt) (refl T_2 tt)
      (* Same for the return predicate if we want to express weakK *)
      return e_as = refl T_0 (refl T tt)
    with
    | refl _ _ => _
    end
).
(* Current small-inversion's cases.ml fails to handle that and crashes on an assertion *)
Admitted.

(* Definition yep (A B C : Type) (a : nat) (b : nat) (c : C) : nat :=
 *   match a, b, c with
 *   | S n, S n', cc => n + n'
 *   | 0, _, cc => 0
 *   | _, 0, cc => 0
 *   end.
 * Print yep. *)


(* Axioms n m : nat.
 * Axioms (u : Vector.t nat (S n)) (v : Vector.t nat (S m)).
 * Eval cbn in (
 *   match v as v' in Vector.t _ n', u as u' in Vector.t _ m' return nat  with
 *   | Vector.cons _ a _ xx, Vector.cons _ b _ tt' => a * b
 *   end
 * ). *)


(* Fixpoint map2 A B C (f : A -> B -> C) n (u : Vector.t A n) (v : Vector.t B n) : Vector.t C n :=
 *   match u, v with
 *   | Vector.cons _ hd _ tl, Vector.cons _ hd' _ tl' => Vector.cons C (f hd hd') _ (map2 A B C f _ tl tl')
 *   | Vector.nil _, Vector.nil _ => Vector.nil C
 *   end.
 * Eval compute in map2. *)


