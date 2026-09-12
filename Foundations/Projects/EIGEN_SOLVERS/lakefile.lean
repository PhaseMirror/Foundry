import Lake
open Lake DSL

package eigen_solvers {
  srcDir := "."
}

@[default_target]
lean_lib EigenSolvers where
  roots := #[`EigenSolvers, `EigenSolvers.Core, `EigenSolvers.Tensor, `EigenSolvers.Proofs, `EigenSolvers.Examples, `EigenSolvers.Test]

@[test_driver]
lean_exe eigen_test where
  root := `EigenSolvers.Test
