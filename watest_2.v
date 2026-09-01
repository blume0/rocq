
Inductive EqNat : nat -> nat -> Type :=
| refl n : EqNat n n.
o
Definition f (A : Type) (e : EqNat 2 3) : A :=
  match e with end.

Print f.
