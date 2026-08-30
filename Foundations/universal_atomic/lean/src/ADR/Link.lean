/-!
  ArtifactLink – minimal representation of a link from an ADR to an external artifact
  (e.g., a Git commit, a design document, or a Lean declaration).
-/
namespace UAC.ADR

structure ArtifactLink where
  description : String          -- human‑readable description
  url         : String          -- absolute URL or git commit hash
  deriving Repr

end UAC.ADR
