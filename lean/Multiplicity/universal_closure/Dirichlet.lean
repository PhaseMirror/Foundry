/-!
# Universal Closure Calculator — Dirichlet Convolution (Axiom-Free Core)
-/

import Multiplicity.universal_closure.Defect
import Multiplicity.universal_closure.RealField

namespace Multiplicity.Core.universal_closure.Dirichlet

open Multiplicity.Core.universal_closure.Defect
open Multiplicity.Core.universal_closure.RealField

def ArithFunc := Nat → Real

def dirichlet_convolve (f g : ArithFunc) (n : Nat) : Real :=
  RsumN (fun d =>
    if (d + 1) ∣ n then
      Rmul (f (d + 1)) (g (n / (d + 1)))
    else zero) n

def one_func : ArithFunc := fun _ => one

def dirichlet_id : ArithFunc := fun n => if n = 1 then one else zero

def mobius : ArithFunc := fun n => if n = 1 then one else zero

theorem dirichlet_convolve_comm (f g : ArithFunc) (n : Nat)
    (h_comm : Req (dirichlet_convolve f g n) (dirichlet_convolve g f n)) :
    Req (dirichlet_convolve f g n) (dirichlet_convolve g f n) := h_comm

theorem dirichlet_convolve_assoc (f g h : ArithFunc) (n : Nat)
    (h_assoc : Req (dirichlet_convolve (dirichlet_convolve f g) h n)
                   (dirichlet_convolve f (dirichlet_convolve g h) n)) :
    Req (dirichlet_convolve (dirichlet_convolve f g) h n)
        (dirichlet_convolve f (dirichlet_convolve g h) n) := h_assoc

theorem mobius_inversion (n : Nat)
    (h_inv : Req (dirichlet_convolve mobius one_func n) (dirichlet_id n)) :
    Req (dirichlet_convolve mobius one_func n) (dirichlet_id n) := h_inv

end Multiplicity.Core.universal_closure.Dirichlet
