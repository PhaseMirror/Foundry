import MOC.Core
import MOC.Moonshine
import MOC.AlmostPurity
import F1Square.Mechanism
import PIRTM.Stability

namespace MOC

/-- 
  Prism Structure (A, I, φ):
  A pair representing the prismatic site, with Frobenius lift φ.
--/
structure Prism {n : Nat} (w : OperatorWord n) where
  A : Type
  I : Nat
  phi : HeckeAction w

/-- 
  Prismatic Data:
  A unified p-adic cohomology structure.
--/
structure PrismaticData {n : Nat} (w : OperatorWord n) where
  cert : PIRTM.StabilityCertificate n
  prism : Prism w
  hodge_tate : HodgeStructure n
  almost_purity : AlmostPurityData w
  h_f1 : UOR.Bridge.F1Square.Mechanism.hodgeType n 6

end MOC
