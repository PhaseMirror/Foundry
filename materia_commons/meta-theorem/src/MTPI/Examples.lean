import MTPI.ADR

namespace MTPI.Examples

def mtpi_adr_001 : ADR := {
  id := "ADR-MTPI-001",
  title := "Anchor MTPI as Materia Commons Ground Truth",
  status := ADRStatus.Accepted,
  context := "We require a formal constraint on state drift and identity.",
  decision := "Implement prime-indexed identity gating with delta(t) <= 0.3.",
  consequences := ["Circuits must enforce 0.3 drift bound.", "Identities must pass Miller-Rabin."],
  supersedes := none,
  links := [],
  h_no_self_supersession := by intro h; contradiction
}

end MTPI.Examples
