import Lake
open Lake DSL

package «dca-system» where

@[default_target]
lean_lib DCA where
  roots := #[`DCA.Attributes, `DCA.Core, `DCA.Proofs, `DCA.Examples, `DCA.Export, `DCA.Test]

lean_exe dca_system where
  root := `Main

lean_exe test where
  root := `DCA.Test
