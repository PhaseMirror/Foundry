import ADR.Core

namespace ADR.Examples

def UAC_Qudit : DecisionRecord :=
  mkADR
    "UAC-001"
    "Use high-dimensional qudits for resource compression"
    "Standard qubit approaches require excessive physical atoms."
    "Adopt qudit encoding (d=10 for Sr, d=16 for Cs)."
    "Reduces atom count by 3.32×; simplifies error correction (HSEC)."
    "2026-07-01"
    "Ryan, Team"
    Status.accepted

def UAC_HSEC : DecisionRecord :=
  mkADR
    "UAC-002"
    "Leverage auxiliary hyperfine levels for non-destructive error detection"
    "Surface codes are costly; unused energy levels are wasted."
    "Implement HSEC using F=7/2 manifold as intrinsic error buffer."
    "5.4× overhead improvement, enables mid-circuit syndrome extraction."
    "2026-07-05"
    "Ryan"
    Status.proposed

end ADR.Examples
