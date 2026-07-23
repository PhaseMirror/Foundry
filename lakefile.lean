import Lake
open Lake DSL

require std from git "https://github.com/leanprover/std4" @ "v4.32.0"

package "ADR-Scaffold" {
  srcDir := "src"
  testDriver := "test"
}

@[default_target]
lean_lib ADR {
  roots := #[
    `ADR.Core,
    `ADR.Proofs,
    `ADR.Governance,
    `ADR.ControlSurface,
    `ADR.Examples,
    `ADR.Resonance,
    `ADR.PhaseMirror,
    `ADR.Export,
    `ADR.Dissonance,
    `ADR.LambdaProofBinding,
    `ADR.SocioAtomic,
    `ADR.Test,
    `ADR.UAC.Constraints,
    `ADR.UAC.Phases,
    `ADR.UAC.Enhancement,
    `ADR.UAC.Proofs,
    `ADR.UAC.Examples,
    `ADR.Kappa.PrimeIndex,
    `ADR.Kappa.Oscillator,
    `ADR.Kappa.KappaExp,
    `ADR.Kappa.Stability,
    `ADR.Kappa.Spectral,
    `ADR.Kappa.Examples,
    `ComplexKappa.Core,
    `ComplexKappa.HilbertTransform,
    `ComplexKappa.Distributions,
    `ComplexKappa.KramersKronig,
    `ComplexKappa.WardIdentity,
    `ComplexKappa.EffectiveCoupling,
    `ComplexKappa.Zeta,
    `ComplexKappa.ZetaComb,
    `ComplexKappa.GUE,
    `ComplexKappa.MainTheorem,
    `ComplexKappa.CPTPIntertwiner,
    `ComplexKappa.IsometryProofs,
    `ComplexKappa.Test,
  ]
}

lean_exe test {
  root := `TestMain
  supportInterpreter := true
}
