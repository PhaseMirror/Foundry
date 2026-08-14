import Multiplicity.Spine
import moc.pAdicHodge
import moc.ShimuraCohomology
import f1_square.Mechanism
import prime_tensors.Stability

namespace Multiplicity.MOC

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

end Multiplicity.MOC
