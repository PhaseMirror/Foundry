import MOC.Core
import MOC.Hecke
import MOC.Moonshine
import F1Square.Mechanism
import PIRTM.Stability

namespace MOC

/-- 
  Fontaine-Laffaille Module:
  Explicit integral classification of crystalline p-adic Galois representations.
  Hodge-Tate weights in the interval [0, p-1].
--/
structure FontaineLaffailleModule {n : Nat} (w : OperatorWord n) where
  cert : PIRTM.StabilityCertificate n
  underlying : Nat -- Free module dimension
  frobenius : HeckeAction w
  hodge_filtration : HodgeStructure n
  h_admissible : (∀ p : Prime, (coeff w p) * (coeff w p) <= 4000000 * p.val) ∧ 
                 UOR.Bridge.F1Square.Mechanism.hodgeType n 6

end MOC
