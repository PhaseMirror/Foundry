import Lake

open Lake DSL

require sedona_spine_core from "../../../lean"
package «the_publisher_adr» where

  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «ThePublisherAdr» where

@[default_target]
lean_exe «the_publisher_adr» where
  root := `Main
