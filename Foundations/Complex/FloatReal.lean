/-!
# Float-based Real Substrate for Computational Dynamics
-/

namespace Foundations.Complex

abbrev Real := Float
notation "ℝ" => Real

def ofNat (n : Nat) : Real := Float.ofNat n
def ofReal (r : Real) : Real := r

def ck_pi : Float := 3.14159265358979323846
def ck_e  : Float := 2.71828182845904523536

def ck_sin (x : Float) : Float := Float.sin x
def ck_cos (x : Float) : Float := Float.cos x
def ck_exp (x : Float) : Float := Float.exp x
def ck_log (x : Float) : Float := Float.log x
def ck_sqrt (x : Float) : Float := Float.sqrt x

end Foundations.Complex
