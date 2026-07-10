import ALP.Types.Action
import Mathlib

namespace ALP.Types.AdmissibilityReport

def isAdmitted (r : AdmissibilityReport) : Bool := r.allowed

def isVetoed (r : AdmissibilityReport) : Bool := !r.allowed

end ALP.Types.AdmissibilityReport
