/-
Copyright (c) 2020 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau
-/
import Mathlib.Algebra.CharP.Frobenius
import Mathlib.Algebra.CharP.Pi
import Mathlib.Algebra.CharP.Quotient
import Mathlib.Algebra.CharP.Subring
import Mathlib.Analysis.SpecialFunctions.Pow.NNReal
import Mathlib.FieldTheory.Perfect
import Mathlib.RingTheory.Valuation.Integers

/-!
# Ring Perfection and Tilt

In this file we define the perfection of a ring of characteristic p, and the tilt of a field
given a valuation to `ℝ≥0`.

## TODO

Define the valuation on the tilt, and define a characteristic predicate for the tilt.

-/


universe u₁ u₂ u₃ u₄

open scoped NNReal

/-- The perfection of a monoid `M`, defined to be the projective limit of `M`
using the `p`-th power maps `M → M` indexed by the natural numbers, implemented as
`{ f : ℕ → M | ∀ n, f (n + 1) ^ p = f n }`. -/
def Monoid.perfection (M : Type u₁) [CommMonoid M] (p : ℕ) : Submonoid (ℕ → M) where
  carrier := { f | ∀ n, f (n + 1) ^ p = f n }
  one_mem' _ := one_pow _
  mul_mem' hf hg n := (mul_pow _ _ _).trans <| congr_arg₂ _ (hf n) (hg n)

/-- The perfection of a ring `R` with characteristic `p`, as a subsemiring,
defined to be the projective limit of `R` using the Frobenius maps `R → R`
indexed by the natural numbers, implemented as `{ f : ℕ → R | ∀ n, f (n + 1) ^ p = f n }`. -/
def Ring.perfectionSubsemiring (R : Type u₁) [CommSemiring R] (p : ℕ) [hp : Fact p.Prime]
    [CharP R p] : Subsemiring (ℕ → R) :=
  { Monoid.perfection R p with
    zero_mem' := fun _ ↦ zero_pow hp.1.ne_zero
    add_mem' := fun hf hg n => (frobenius_add R p _ _).trans <| congr_arg₂ _ (hf n) (hg n) }

/-- The perfection of a ring `R` with characteristic `p`, as a subring,
defined to be the projective limit of `R` using the Frobenius maps `R → R`
indexed by the natural numbers, implemented as `{ f : ℕ → R | ∀ n, f (n + 1) ^ p = f n }`. -/
def Ring.perfectionSubring (R : Type u₁) [CommRing R] (p : ℕ) [hp : Fact p.Prime] [CharP R p] :
    Subring (ℕ → R) :=
  (Ring.perfectionSubsemiring R p).toSubring fun n => by
    simp_rw [← frobenius_def, Pi.neg_apply, Pi.one_apply, RingHom.map_neg, RingHom.map_one]

/-- The perfection of a ring `R` with characteristic `p`,
defined to be the projective limit of `R` using the Frobenius maps `R → R`
indexed by the natural numbers, implemented as `{f : ℕ → R // ∀ n, f (n + 1) ^ p = f n}`. -/
def Ring.Perfection (R : Type u₁) [CommSemiring R] (p : ℕ) : Type u₁ :=
  { f // ∀ n : ℕ, (f : ℕ → R) (n + 1) ^ p = f n }

namespace Perfection

variable (R : Type u₁) [CommSemiring R] (p : ℕ) [hp : Fact p.Prime] [CharP R p]

instance commSemiring : CommSemiring (Ring.Perfection R p) :=
  (Ring.perfectionSubsemiring R p).toCommSemiring

instance charP : CharP (Ring.Perfection R p) p :=
  CharP.subsemiring (ℕ → R) p (Ring.perfectionSubsemiring R p)

instance ring (R : Type u₁) [CommRing R] [CharP R p] : Ring (Ring.Perfection R p) :=
  (Ring.perfectionSubring R p).toRing

instance commRing (R : Type u₁) [CommRing R] [CharP R p] : CommRing (Ring.Perfection R p) :=
  (Ring.perfectionSubring R p).toCommRing

instance : Inhabited (Ring.Perfection R p) := ⟨0⟩

/-- The `n`-th coefficient of an element of the perfection. -/
def coeff (n : ℕ) : Ring.Perfection R p →+* R where
  toFun f := f.1 n
  map_one' := rfl
  map_mul' _ _ := rfl
  map_zero' := rfl
  map_add' _ _ := rfl

variable {R p}

@[ext]
theorem ext {f g : Ring.Perfection R p} (h : ∀ n, coeff R p n f = coeff R p n g) : f = g :=
  Subtype.eq <| funext h

variable (R p)

/-- The `p`-th root of an element of the perfection. -/
def pthRoot : Ring.Perfection R p →+* Ring.Perfection R p where
  toFun f := ⟨fun n => coeff R p (n + 1) f, fun _ => f.2 _⟩
  map_one' := rfl
  map_mul' _ _ := rfl
  map_zero' := rfl
  map_add' _ _ := rfl

variable {R p}

@[simp]
theorem coeff_mk (f : ℕ → R) (hf) (n : ℕ) : coeff R p n ⟨f, hf⟩ = f n := rfl

theorem coeff_pthRoot (f : Ring.Perfection R p) (n : ℕ) :
    coeff R p n (pthRoot R p f) = coeff R p (n + 1) f := rfl

theorem coeff_pow_p (f : Ring.Perfection R p) (n : ℕ) :
    coeff R p (n + 1) (f ^ p) = coeff R p n f := by rw [RingHom.map_pow]; exact f.2 n

theorem coeff_pow_p' (f : Ring.Perfection R p) (n : ℕ) : coeff R p (n + 1) f ^ p = coeff R p n f :=
  f.2 n

theorem coeff_frobenius (f : Ring.Perfection R p) (n : ℕ) :
    coeff R p (n + 1) (frobenius _ p f) = coeff R p n f := by apply coeff_pow_p f n

-- `coeff_pow_p f n` also works but is slow!
theorem coeff_iterate_frobenius (f : Ring.Perfection R p) (n m : ℕ) :
    coeff R p (n + m) ((frobenius _ p)^[m] f) = coeff R p n f :=
  Nat.recOn m rfl fun m ih => by
    rw [Function.iterate_succ_apply', Nat.add_succ, coeff_frobenius, ih]

theorem coeff_iterate_frobenius' (f : Ring.Perfection R p) (n m : ℕ) (hmn : m ≤ n) :
    coeff R p n ((frobenius _ p)^[m] f) = coeff R p (n - m) f :=
  Eq.symm <| (coeff_iterate_frobenius _ _ m).symm.trans <| (tsub_add_cancel_of_le hmn).symm ▸ rfl

theorem pthRoot_frobenius : (pthRoot R p).comp (frobenius _ p) = RingHom.id _ :=
  RingHom.ext fun x =>
    ext fun n => by rw [RingHom.comp_apply, RingHom.id_apply, coeff_pthRoot, coeff_frobenius]

theorem frobenius_pthRoot : (frobenius _ p).comp (pthRoot R p) = RingHom.id _ :=
  RingHom.ext fun x =>
    ext fun n => by
      rw [RingHom.comp_apply, RingHom.id_apply, RingHom.map_frobenius, coeff_pthRoot,
        ← @RingHom.map_frobenius (Ring.Perfection R p) _ R, coeff_frobenius]

theorem coeff_add_ne_zero {f : Ring.Perfection R p} {n : ℕ} (hfn : coeff R p n f ≠ 0) (k : ℕ) :
    coeff R p (n + k) f ≠ 0 :=
  Nat.recOn k hfn fun k ih h => ih <| by
    rw [Nat.add_succ] at h
    rw [← coeff_pow_p, RingHom.map_pow, h, zero_pow hp.1.ne_zero]

theorem coeff_ne_zero_of_le {f : Ring.Perfection R p} {m n : ℕ} (hfm : coeff R p m f ≠ 0)
    (hmn : m ≤ n) : coeff R p n f ≠ 0 :=
  let ⟨k, hk⟩ := Nat.exists_eq_add_of_le hmn
  hk.symm ▸ coeff_add_ne_zero hfm k

variable (R p)

instance perfectRing : PerfectRing (Ring.Perfection R p) p where
  bijective_frobenius := Function.bijective_iff_has_inverse.mpr
    ⟨pthRoot R p,
     DFunLike.congr_fun <| @frobenius_pthRoot R _ p _ _,
     DFunLike.congr_fun <| @pthRoot_frobenius R _ p _ _⟩

/-- Given rings `R` and `S` of characteristic `p`, with `R` being perfect,
any homomorphism `R →+* S` can be lifted to a homomorphism `R →+* Perfection S p`. -/
@[simps]
noncomputable def lift (R : Type u₁) [CommSemiring R] [CharP R p] [PerfectRing R p]
    (S : Type u₂) [CommSemiring S] [CharP S p] : (R →+* S) ≃ (R →+* Ring.Perfection S p) where
  toFun f :=
    { toFun := fun r => ⟨fun n => f (((frobeniusEquiv R p).symm : R →+* R)^[n] r),
        fun n => by rw [← f.map_pow, Function.iterate_succ_apply', RingHom.coe_coe,
          frobeniusEquiv_symm_pow_p]⟩
      map_one' := ext fun _ => (congr_arg f <| iterate_map_one _ _).trans f.map_one
      map_mul' := fun _ _ =>
        ext fun _ => (congr_arg f <| iterate_map_mul _ _ _ _).trans <| f.map_mul _ _
      map_zero' := ext fun _ => (congr_arg f <| iterate_map_zero _ _).trans f.map_zero
      map_add' := fun _ _ =>
        ext fun _ => (congr_arg f <| iterate_map_add _ _ _ _).trans <| f.map_add _ _ }
  invFun := RingHom.comp <| coeff S p 0
  right_inv f := RingHom.ext fun r => ext fun n =>
    show coeff S p 0 (f (((frobeniusEquiv R p).symm)^[n] r)) = coeff S p n (f r) by
      rw [← coeff_iterate_frobenius _ 0 n, zero_add, ← RingHom.map_iterate_frobenius,
        Function.RightInverse.iterate (frobenius_apply_frobeniusEquiv_symm R p) n]

theorem hom_ext {R : Type u₁} [CommSemiring R] [CharP R p] [PerfectRing R p] {S : Type u₂}
    [CommSemiring S] [CharP S p] {f g : R →+* Ring.Perfection S p}
    (hfg : ∀ x, coeff S p 0 (f x) = coeff S p 0 (g x)) : f = g :=
  (lift p R S).symm.injective <| RingHom.ext hfg

variable {R} {S : Type u₂} [CommSemiring S] [CharP S p]

/-- A ring homomorphism `R →+* S` induces `Perfection R p →+* Perfection S p`. -/
@[simps]
def map (φ : R →+* S) : Ring.Perfection R p →+* Ring.Perfection S p where
  toFun f := ⟨fun n => φ (coeff R p n f), fun n => by rw [← φ.map_pow, coeff_pow_p']⟩
  map_one' := Subtype.eq <| funext fun _ => φ.map_one
  map_mul' _ _ := Subtype.eq <| funext fun _ => φ.map_mul _ _
  map_zero' := Subtype.eq <| funext fun _ => φ.map_zero
  map_add' _ _ := Subtype.eq <| funext fun _ => φ.map_add _ _

theorem coeff_map (φ : R →+* S) (f : Ring.Perfection R p) (n : ℕ) :
    coeff S p n (map p φ f) = φ (coeff R p n f) := rfl

end Perfection

/-- A perfection map to a ring of characteristic `p` is a map that is isomorphic
to its perfection. -/
structure PerfectionMap (p : ℕ) [Fact p.Prime] {R : Type u₁} [CommSemiring R] [CharP R p]
    {P : Type u₂} [CommSemiring P] [CharP P p] [PerfectRing P p] (π : P →+* R) : Prop where
  injective : ∀ ⦃x y : P⦄,
    (∀ n, π (((frobeniusEquiv P p).symm)^[n] x) = π (((frobeniusEquiv P p).symm)^[n] y)) → x = y
  surjective : ∀ f : ℕ → R, (∀ n, f (n + 1) ^ p = f n) → ∃ x : P, ∀ n,
    π (((frobeniusEquiv P p).symm)^[n] x) = f n

namespace PerfectionMap

variable {p : ℕ} [Fact p.Prime]
variable {R : Type u₁} [CommSemiring R] [CharP R p]
variable {P : Type u₃} [CommSemiring P] [CharP P p] [PerfectRing P p]

/-- Create a `PerfectionMap` from an isomorphism to the perfection. -/
@[simps]
theorem mk' {f : P →+* R} (g : P ≃+* Ring.Perfection R p) (hfg : Perfection.lift p P R f = g) :
    PerfectionMap p f :=
  { injective := fun x y hxy =>
      g.injective <|
        (RingHom.ext_iff.1 hfg x).symm.trans <|
          Eq.symm <| (RingHom.ext_iff.1 hfg y).symm.trans <| Perfection.ext fun n => (hxy n).symm
    surjective := fun y hy =>
      let ⟨x, hx⟩ := g.surjective ⟨y, hy⟩
      ⟨x, fun n =>
        show Perfection.coeff R p n (Perfection.lift p P R f x) = Perfection.coeff R p n ⟨y, hy⟩ by
          simp [hfg, hx]⟩ }

variable (p R P)

/-- The canonical perfection map from the perfection of a ring. -/
theorem of : PerfectionMap p (Perfection.coeff R p 0) :=
  mk' (RingEquiv.refl _) <| (Equiv.apply_eq_iff_eq_symm_apply _).2 rfl

/-- For a perfect ring, it itself is the perfection. -/
theorem id [PerfectRing R p] : PerfectionMap p (RingHom.id R) :=
  { injective := fun _ _ hxy => hxy 0
    surjective := fun f hf =>
      ⟨f 0, fun n =>
        show ((frobeniusEquiv R p).symm)^[n] (f 0) = f n from
          Nat.recOn n rfl fun n ih => injective_pow_p R p <| by
            rw [Function.iterate_succ_apply', frobeniusEquiv_symm_pow_p, ih, hf]⟩ }

variable {p R P}

/-- A perfection map induces an isomorphism to the perfection. -/
noncomputable def equiv {π : P →+* R} (m : PerfectionMap p π) : P ≃+* Ring.Perfection R p :=
  RingEquiv.ofBijective (Perfection.lift p P R π)
    ⟨fun _ _ hxy => m.injective fun n => (congr_arg (Perfection.coeff R p n) hxy :), fun f =>
      let ⟨x, hx⟩ := m.surjective f.1 f.2
      ⟨x, Perfection.ext <| hx⟩⟩

theorem equiv_apply {π : P →+* R} (m : PerfectionMap p π) (x : P) :
    m.equiv x = Perfection.lift p P R π x := rfl

theorem comp_equiv {π : P →+* R} (m : PerfectionMap p π) (x : P) :
    Perfection.coeff R p 0 (m.equiv x) = π x := rfl

theorem comp_equiv' {π : P →+* R} (m : PerfectionMap p π) :
    (Perfection.coeff R p 0).comp ↑m.equiv = π :=
  RingHom.ext fun _ => rfl

theorem comp_symm_equiv {π : P →+* R} (m : PerfectionMap p π) (f : Ring.Perfection R p) :
    π (m.equiv.symm f) = Perfection.coeff R p 0 f :=
  (m.comp_equiv _).symm.trans <| congr_arg _ <| m.equiv.apply_symm_apply f

theorem comp_symm_equiv' {π : P →+* R} (m : PerfectionMap p π) :
    π.comp ↑m.equiv.symm = Perfection.coeff R p 0 :=
  RingHom.ext m.comp_symm_equiv

variable (p R P)

/-- Given rings `R` and `S` of characteristic `p`, with `R` being perfect,
any homomorphism `R →+* S` can be lifted to a homomorphism `R →+* P`,
where `P` is any perfection of `S`. -/
@[simps]
noncomputable def lift [PerfectRing R p] (S : Type u₂) [CommSemiring S] [CharP S p] (P : Type u₃)
    [CommSemiring P] [CharP P p] [PerfectRing P p] (π : P →+* S) (m : PerfectionMap p π) :
    (R →+* S) ≃ (R →+* P) where
  toFun f := RingHom.comp ↑m.equiv.symm <| Perfection.lift p R S f
  invFun f := π.comp f
  left_inv f := by
    simp_rw [← RingHom.comp_assoc, comp_symm_equiv']
    exact (Perfection.lift p R S).symm_apply_apply f
  right_inv f := by
    exact RingHom.ext fun x => m.equiv.injective <| (m.equiv.apply_symm_apply _).trans
      <| show Perfection.lift p R S (π.comp f) x = RingHom.comp (↑m.equiv) f x from
        RingHom.ext_iff.1 (by rw [Equiv.apply_eq_iff_eq_symm_apply]; rfl) _

variable {R p}

theorem hom_ext [PerfectRing R p] {S : Type u₂} [CommSemiring S] [CharP S p] {P : Type u₃}
    [CommSemiring P] [CharP P p] [PerfectRing P p] (π : P →+* S) (m : PerfectionMap p π)
    {f g : R →+* P} (hfg : ∀ x, π (f x) = π (g x)) : f = g :=
  (lift p R S P π m).symm.injective <| RingHom.ext hfg

variable {P} (p)
variable {S : Type u₂} [CommSemiring S] [CharP S p]
variable {Q : Type u₄} [CommSemiring Q] [CharP Q p] [PerfectRing Q p]

/-- A ring homomorphism `R →+* S` induces `P →+* Q`, a map of the respective perfections. -/
@[nolint unusedArguments]
noncomputable def map {π : P →+* R} (_ : PerfectionMap p π) {σ : Q →+* S} (n : PerfectionMap p σ)
    (φ : R →+* S) : P →+* Q :=
  lift p P S Q σ n <| φ.comp π

theorem comp_map {π : P →+* R} (m : PerfectionMap p π) {σ : Q →+* S} (n : PerfectionMap p σ)
    (φ : R →+* S) : σ.comp (map p m n φ) = φ.comp π :=
  (lift p P S Q σ n).symm_apply_apply _

theorem map_map {π : P →+* R} (m : PerfectionMap p π) {σ : Q →+* S} (n : PerfectionMap p σ)
    (φ : R →+* S) (x : P) : σ (map p m n φ x) = φ (π x) :=
  RingHom.ext_iff.1 (comp_map p m n φ) x

theorem map_eq_map (φ : R →+* S) : map p (of p R) (of p S) φ = Perfection.map p φ :=
  hom_ext _ (of p S) fun f => by rw [map_map, Perfection.coeff_map]

end PerfectionMap

section ModP

variable (O : Type u₂) [CommRing O] (p : ℕ)

/-- `O/(p)` for `O`, ring of integers of `K`. -/
def ModP :=
  O ⧸ (Ideal.span {(p : O)} : Ideal O)

namespace ModP

instance commRing : CommRing (ModP O p) :=
  Ideal.Quotient.commRing (Ideal.span {(p : O)} : Ideal O)

instance charP [Fact p.Prime] [hvp : Fact (¬ IsUnit (p : O))] : CharP (ModP O p) p :=
  CharP.quotient O p <| hvp.1

instance nontrivial [hp : Fact p.Prime] [Fact (¬ IsUnit (p : O))] : Nontrivial (ModP O p) :=
  CharP.nontrivial_of_char_ne_one hp.1.ne_one

end ModP

end ModP

section Perfectoid

variable (K : Type u₁) [Field K] (v : Valuation K ℝ≥0)
variable (O : Type u₂) [CommRing O] [Algebra O K] (hv : v.Integers O)
variable (p : ℕ)

namespace ModP

section Classical

attribute [local instance] Classical.dec

/-- For a field `K` with valuation `v : K → ℝ≥0` and ring of integers `O`,
a function `O/(p) → ℝ≥0` that sends `0` to `0` and `x + (p)` to `v(x)` as long as `x ∉ (p)`. -/
noncomputable def preVal (x : ModP O p) : ℝ≥0 :=
  if x = 0 then 0 else v (algebraMap O K x.out)

variable {K v O p}

theorem preVal_zero : preVal K v O p 0 = 0 :=
  if_pos rfl

include hv

theorem preVal_mk {x : O} (hx : (Ideal.Quotient.mk _ x : ModP O p) ≠ 0) :
    preVal K v O p (Ideal.Quotient.mk _ x) = v (algebraMap O K x) := by
  obtain ⟨r, hr⟩ : ∃ (a : O), a * (p : O) = (Ideal.Quotient.mk _ x).out - x :=
    Ideal.mem_span_singleton'.1 <| Ideal.Quotient.eq.1 <| Quotient.sound' <| Quotient.mk_out' _
  refine (if_neg hx).trans (v.map_eq_of_sub_lt <| lt_of_not_ge ?_)
  rw [← RingHom.map_sub, ← hr, hv.le_iff_dvd]
  exact fun hprx =>
    hx (Ideal.Quotient.eq_zero_iff_mem.2 <| Ideal.mem_span_singleton.2 <| dvd_of_mul_left_dvd hprx)

theorem preVal_mul {x y : ModP O p} (hxy0 : x * y ≠ 0) :
    preVal K v O p (x * y) = preVal K v O p x * preVal K v O p y := by
  have hx0 : x ≠ 0 := mt (by rintro rfl; rw [zero_mul]) hxy0
  have hy0 : y ≠ 0 := mt (by rintro rfl; rw [mul_zero]) hxy0
  obtain ⟨r, rfl⟩ := Ideal.Quotient.mk_surjective x
  obtain ⟨s, rfl⟩ := Ideal.Quotient.mk_surjective y
  rw [← map_mul (Ideal.Quotient.mk (Ideal.span {↑p})) r s] at hxy0 ⊢
  rw [preVal_mk hv hx0, preVal_mk hv hy0, preVal_mk hv hxy0, RingHom.map_mul, v.map_mul]

theorem preVal_add (x y : ModP O p) :
    preVal K v O p (x + y) ≤ max (preVal K v O p x) (preVal K v O p y) := by
  by_cases hx0 : x = 0
  · rw [hx0, zero_add]; exact le_max_right _ _
  by_cases hy0 : y = 0
  · rw [hy0, add_zero]; exact le_max_left _ _
  by_cases hxy0 : x + y = 0
  · rw [hxy0, preVal_zero]; exact zero_le _
  obtain ⟨r, rfl⟩ := Ideal.Quotient.mk_surjective x
  obtain ⟨s, rfl⟩ := Ideal.Quotient.mk_surjective y
  rw [← map_add (Ideal.Quotient.mk (Ideal.span {↑p})) r s] at hxy0 ⊢
  rw [preVal_mk hv hx0, preVal_mk hv hy0, preVal_mk hv hxy0, RingHom.map_add]; exact v.map_add _ _

theorem v_p_lt_preVal {x : ModP O p} : v p < preVal K v O p x ↔ x ≠ 0 := by
  refine ⟨fun h hx => by rw [hx, preVal_zero] at h; exact not_lt_zero' h,
    fun h => lt_of_not_ge fun hp => h ?_⟩
  obtain ⟨r, rfl⟩ := Ideal.Quotient.mk_surjective x
  rw [preVal_mk hv h, ← map_natCast (algebraMap O K) p, hv.le_iff_dvd] at hp
  · rw [Ideal.Quotient.eq_zero_iff_mem, Ideal.mem_span_singleton]; exact hp

theorem preVal_eq_zero {x : ModP O p} : preVal K v O p x = 0 ↔ x = 0 :=
  ⟨fun hvx =>
    by_contradiction fun hx0 : x ≠ 0 => by
      rw [← v_p_lt_preVal (hv := hv), hvx] at hx0
      exact not_lt_zero' hx0,
    fun hx => hx.symm ▸ preVal_zero⟩

theorem v_p_lt_val {x : O} :
    v p < v (algebraMap O K x) ↔ (Ideal.Quotient.mk _ x : ModP O p) ≠ 0 := by
  rw [lt_iff_not_ge, not_iff_not, ← map_natCast (algebraMap O K) p, hv.le_iff_dvd,
    Ideal.Quotient.eq_zero_iff_mem, Ideal.mem_span_singleton]

open NNReal

variable [hp : Fact p.Prime]

theorem mul_ne_zero_of_pow_p_ne_zero {x y : ModP O p} (hx : x ^ p ≠ 0) (hy : y ^ p ≠ 0) :
    x * y ≠ 0 := by
  obtain ⟨r, rfl⟩ := Ideal.Quotient.mk_surjective x
  obtain ⟨s, rfl⟩ := Ideal.Quotient.mk_surjective y
  have h1p : (0 : ℝ) < 1 / p := one_div_pos.2 (Nat.cast_pos.2 hp.1.pos)
  rw [← (Ideal.Quotient.mk (Ideal.span {(p : O)})).map_mul]
  rw [← (Ideal.Quotient.mk (Ideal.span {(p : O)})).map_pow] at hx hy
  rw [← v_p_lt_val hv] at hx hy ⊢
  rw [RingHom.map_pow, v.map_pow, ← rpow_lt_rpow_iff h1p, ← rpow_natCast, ← rpow_mul,
    mul_one_div_cancel (Nat.cast_ne_zero.2 hp.1.ne_zero : (p : ℝ) ≠ 0), rpow_one] at hx hy
  rw [RingHom.map_mul, v.map_mul]; refine lt_of_le_of_lt ?_ (mul_lt_mul'' hx hy zero_le' zero_le')
  by_cases hvp : v p = 0
  · rw [hvp]; exact zero_le _
  replace hvp := zero_lt_iff.2 hvp
  conv_lhs => rw [← rpow_one (v p)]
  rw [← rpow_add (ne_of_gt hvp)]
  refine rpow_le_rpow_of_exponent_ge hvp (map_natCast (algebraMap O K) p ▸ hv.2 _) ?_
  rw [← add_div, div_le_one (Nat.cast_pos.2 hp.1.pos : 0 < (p : ℝ))]; exact mod_cast hp.1.two_le

end Classical

end ModP

/-- Perfection of `O/(p)` where `O` is the ring of integers of `K`. -/
def PreTilt :=
  Ring.Perfection (ModP O p) p

namespace PreTilt

variable [Fact p.Prime] [Fact (¬ IsUnit (p : O))]

instance : CommRing (PreTilt O p) :=
  Perfection.commRing p _

instance : CharP (PreTilt O p) p :=
  Perfection.charP (ModP O p) p

section Classical

open Perfection

open scoped Classical in
/-- The valuation `Perfection(O/(p)) → ℝ≥0` as a function.
Given `f ∈ Perfection(O/(p))`, if `f = 0` then output `0`;
otherwise output `preVal(f(n))^(p^n)` for any `n` such that `f(n) ≠ 0`. -/
noncomputable def valAux (f : PreTilt O p) : ℝ≥0 :=
  if h : ∃ n, coeff _ _ n f ≠ 0 then
    ModP.preVal K v O p (coeff _ _ (Nat.find h) f) ^ p ^ Nat.find h
  else 0

variable {K v O p}

open scoped Classical in
theorem coeff_nat_find_add_ne_zero {f : PreTilt O p} {h : ∃ n, coeff _ _ n f ≠ 0} (k : ℕ) :
    coeff _ _ (Nat.find h + k) f ≠ 0 :=
  coeff_add_ne_zero (Nat.find_spec h) k

theorem valAux_zero : valAux K v O p 0 = 0 :=
  dif_neg fun ⟨_, hn⟩ => hn rfl

include hv

theorem valAux_eq {f : PreTilt O p} {n : ℕ} (hfn : coeff _ _ n f ≠ 0) :
    valAux K v O p f = ModP.preVal K v O p (coeff _ _ n f) ^ p ^ n := by
  have h : ∃ n, coeff _ _ n f ≠ 0 := ⟨n, hfn⟩
  rw [valAux, dif_pos h]
  classical
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le (Nat.find_min' h hfn)
  induction' k with k ih
  · rfl
  obtain ⟨x, hx⟩ := Ideal.Quotient.mk_surjective (coeff (ModP O p) p (Nat.find h + k + 1) f)
  have h1 : (Ideal.Quotient.mk _ x : ModP O p) ≠ 0 := hx.symm ▸ hfn
  have h2 : (Ideal.Quotient.mk _ (x ^ p) : ModP O p) ≠ 0 := by
    erw [RingHom.map_pow, hx, ← RingHom.map_pow, coeff_pow_p]
    exact coeff_nat_find_add_ne_zero k
  erw [ih (coeff_nat_find_add_ne_zero k), ← hx, ← coeff_pow_p, RingHom.map_pow, ← hx,
    ← RingHom.map_pow, ModP.preVal_mk hv h1, ModP.preVal_mk hv h2, RingHom.map_pow, v.map_pow,
    ← pow_mul, pow_succ']
  rfl

theorem valAux_one : valAux K v O p 1 = 1 :=
  (valAux_eq (hv := hv) <| show coeff (ModP O p) p 0 1 ≠ 0 from one_ne_zero).trans <| by
    rw [pow_zero, pow_one, RingHom.map_one, ← (Ideal.Quotient.mk _).map_one, ModP.preVal_mk hv,
      RingHom.map_one, v.map_one]
    change (1 : ModP O p) ≠ 0
    exact one_ne_zero

theorem valAux_mul (f g : PreTilt O p) :
    valAux K v O p (f * g) = valAux K v O p f * valAux K v O p g := by
  by_cases hf : f = 0
  · rw [hf, zero_mul, valAux_zero, zero_mul]
  by_cases hg : g = 0
  · rw [hg, mul_zero, valAux_zero, mul_zero]
  obtain ⟨m, hm⟩ : ∃ n, coeff _ _ n f ≠ 0 := not_forall.1 fun h => hf <| Perfection.ext h
  obtain ⟨n, hn⟩ : ∃ n, coeff _ _ n g ≠ 0 := not_forall.1 fun h => hg <| Perfection.ext h
  replace hm := coeff_ne_zero_of_le hm (le_max_left m n)
  replace hn := coeff_ne_zero_of_le hn (le_max_right m n)
  have hfg : coeff _ _ (max m n + 1) (f * g) ≠ 0 := by
    rw [RingHom.map_mul]
    refine ModP.mul_ne_zero_of_pow_p_ne_zero (hv := hv) ?_ ?_
    · rw [← RingHom.map_pow, coeff_pow_p f]; assumption
    · rw [← RingHom.map_pow, coeff_pow_p g]; assumption
  rw [valAux_eq hv (coeff_add_ne_zero hm 1),
      valAux_eq hv (coeff_add_ne_zero hn 1), valAux_eq hv hfg]
  rw [RingHom.map_mul] at hfg ⊢; rw [ModP.preVal_mul hv hfg, mul_pow]

theorem valAux_add (f g : PreTilt O p) :
    valAux K v O p (f + g) ≤ max (valAux K v O p f) (valAux K v O p g) := by
  by_cases hf : f = 0
  · rw [hf, zero_add, valAux_zero, max_eq_right]; exact zero_le _
  by_cases hg : g = 0
  · rw [hg, add_zero, valAux_zero, max_eq_left]; exact zero_le _
  by_cases hfg : f + g = 0
  · rw [hfg, valAux_zero]; exact zero_le _
  replace hf : ∃ n, coeff _ _ n f ≠ 0 := not_forall.1 fun h => hf <| Perfection.ext h
  replace hg : ∃ n, coeff _ _ n g ≠ 0 := not_forall.1 fun h => hg <| Perfection.ext h
  replace hfg : ∃ n, coeff _ _ n (f + g) ≠ 0 := not_forall.1 fun h => hfg <| Perfection.ext h
  obtain ⟨m, hm⟩ := hf; obtain ⟨n, hn⟩ := hg; obtain ⟨k, hk⟩ := hfg
  replace hm := coeff_ne_zero_of_le hm (le_trans (le_max_left m n) (le_max_left _ k))
  replace hn := coeff_ne_zero_of_le hn (le_trans (le_max_right m n) (le_max_left _ k))
  replace hk := coeff_ne_zero_of_le hk (le_max_right (max m n) k)
  rw [valAux_eq hv hm, valAux_eq hv hn, valAux_eq hv hk, RingHom.map_add]
  rcases le_max_iff.1
      (ModP.preVal_add hv (coeff _ _ (max (max m n) k) f)
      (coeff _ _ (max (max m n) k) g)) with h | h
  · exact le_max_of_le_left (pow_le_pow_left' h _)
  · exact le_max_of_le_right (pow_le_pow_left' h _)

variable (K v O p)

/-- The valuation `Perfection(O/(p)) → ℝ≥0`.
Given `f ∈ Perfection(O/(p))`, if `f = 0` then output `0`;
otherwise output `preVal(f(n))^(p^n)` for any `n` such that `f(n) ≠ 0`. -/
noncomputable def val : Valuation (PreTilt O p) ℝ≥0 where
  toFun := valAux K v O p
  map_one' := valAux_one hv
  map_mul' := valAux_mul hv
  map_zero' := valAux_zero
  map_add_le_max' := valAux_add hv

variable {K v O p}

theorem map_eq_zero {f : PreTilt O p} : val K v O hv p f = 0 ↔ f = 0 := by
  by_cases hf0 : f = 0
  · rw [hf0]; exact iff_of_true (Valuation.map_zero _) rfl
  obtain ⟨n, hn⟩ : ∃ n, coeff _ _ n f ≠ 0 := not_forall.1 fun h => hf0 <| Perfection.ext h
  show valAux K v O p f = 0 ↔ f = 0; refine iff_of_false (fun hvf => hn ?_) hf0
  rw [valAux_eq hv hn] at hvf; replace hvf := pow_eq_zero hvf; rwa [ModP.preVal_eq_zero hv] at hvf

end Classical

include hv

theorem isDomain : IsDomain (PreTilt O p) := by
  have hp : Nat.Prime p := Fact.out
  haveI : Nontrivial (PreTilt O p) := ⟨(CharP.nontrivial_of_char_ne_one hp.ne_one).1⟩
  haveI : NoZeroDivisors (PreTilt O p) :=
    ⟨fun hfg => by
      simp_rw [← map_eq_zero hv] at hfg ⊢; contrapose! hfg; rw [Valuation.map_mul]
      exact mul_ne_zero hfg.1 hfg.2⟩
  exact NoZeroDivisors.to_isDomain _

end PreTilt

/-- The tilt of a field, as defined in Perfectoid Spaces by Peter Scholze, as in
[scholze2011perfectoid]. Given a field `K` with valuation `K → ℝ≥0` and ring of integers `O`,
this is implemented as the fraction field of the perfection of `O/(p)`. -/
def Tilt [Fact p.Prime] [hvp : Fact (v p ≠ 1)] :=
  have _ := Fact.mk <| mt hv.one_of_isUnit <| (map_natCast (algebraMap O K) p).symm ▸ hvp.1
  FractionRing (PreTilt O p)

namespace Tilt

noncomputable instance [Fact p.Prime] [hvp : Fact (v p ≠ 1)] : Field (Tilt K v O hv p) :=
  haveI := Fact.mk <| mt hv.one_of_isUnit <| (map_natCast (algebraMap O K) p).symm ▸ hvp.1
  haveI := PreTilt.isDomain K v O hv p
  FractionRing.field _

end Tilt

end Perfectoid
