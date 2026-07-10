import ProofWidgets.Component.Html
import AffineCore.CertificationGate
import AffineCore.AdelicBorn
import AffineCore.EthicalConvergence

-- Widgets.lean
-- Interactive Proof Lab for Z-Bit Invariants.
-- Renders a 'Governance Dashboard' in the Lean Infoview.

open ProofWidgets Html

namespace Multiplicity.Widgets

/-- 
  Renders the status of a Z-Bit invariant.
--/
def invariantStatus (name : String) (status : String) (color : String) : Html :=
  <div style={json% { marginBottom: "10px", padding: "5px", borderLeft: s!"5px solid {color}", backgroundColor: "#f0f0f0" }}>
    <strong>{name}</strong>: <span style={json% { color: color }}>{status}</span>
  </div>

/--
  The Governance Dashboard Component.
--/
@[widget_module]
def GovernanceDashboard : Component Unit where
  render _ := 
    <div>
      <h3>🛡️ Z-Bit Governance Dashboard</h3>
      {invariantStatus "Mechanical (No Bypass)" "PROVEN" "green"}
      {invariantStatus "Quantum (Normalization)" "PROVEN" "green"}
      {invariantStatus "Ethical (Convergence)" "PROVEN" "green"}
      {invariantStatus "Composition (Modularity)" "SKELETON" "orange"}
      {invariantStatus "Homological (Simulability)" "SKELETON" "orange"}
      <hr/>
      <p><em>Use 'ProofWidgets' to explore proof states for skeletal theorems.</em></p>
    </div>

-- To use: #widget GovernanceDashboard
end Multiplicity.Widgets
