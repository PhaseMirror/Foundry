import Multiplicity.Lake
open Lake DSL

require std from git "https://github.com/leanprover/std4" @ "v4.32.0"

package «integrative_solver_adr» where
  -- Settings for production builds
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩
  ]

@[default_target]
lean_lib IntegrativeSolver where
  roots := #[`IntegrativeSolver.Core, `IntegrativeSolver.Diffusion,
    `IntegrativeSolver.Intervention, `IntegrativeSolver.Audit,
    `IntegrativeSolver.Test]

@[test_runner]
lean_exe test where
  root := `IntegrativeSolver.Test
