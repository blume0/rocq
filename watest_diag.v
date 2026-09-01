
Set SmallInversion Debug.

#[universes(polymorphic=yes)]
Inductive V: Type -> nat -> Type :=
| nil A : V A 0
| cons A n (hd : A) (tl : V A n) : V A (S n).


Definition diag {A : Type} (n : nat) (M : V (V A n) n) : V A n.
Proof.
refine (
  match M with
  | nil _ => nil _
  | cons _ n (cons _ _ hd tl) tls => _
  end
).
Abort.
