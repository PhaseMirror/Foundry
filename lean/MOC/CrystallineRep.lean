import MOC.Core
import MOC.pAdicHodge
import MOC.ShimuraCohomology
import F1Square.Mechanism
import PIRTM.Stability

namespace MOC

/-- 
  Crystalline Representation:
  A p-adic Galois representation with an admissible filtered φ-module.
  Newton polygon lies above the Hodge polygon.
--/
structure CrystallineRep {n : Nat} (w : OperatorWord n) where
  cert : PIRTM.StabilityCertificate n
  galois_rep : GaloisRep n
  filtered_phi : FilteredPhiModule w
  hodge_filtration : HodgeStructure n
  h_admissible : weak_admissibility filtered_phi
  h_f1 : UOR.Bridge.F1Square.Mechanism.hodgeType n 6

end MOC
