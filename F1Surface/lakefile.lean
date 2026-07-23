import Lake
open Lake DSL

require std from git "https://github.com/leanprover/std4" @ "v4.32.0"

lean_lib ComplexKappa where
  srcDir := "."
  roots := #[`ComplexKappa.SpectralAttractor]

lean_exe spectral_attractor_tests where
  srcDir := "."
  root := `ComplexKappa.SpectralAttractor.Tests
