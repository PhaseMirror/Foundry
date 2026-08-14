import Multiplicity.alp.Types.Action

namespace Multiplicity.ALP.Types.AdmissibilityReport

def isAdmitted (r : AdmissibilityReport) : Bool := r.allowed

def isVetoed (r : AdmissibilityReport) : Bool := !r.allowed

end Multiplicity.ALP.Types.AdmissibilityReport
