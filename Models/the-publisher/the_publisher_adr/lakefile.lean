import Lake

open Lake DSL

package «the_publisher_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

@[default_target]
lean_lib «ThePublisherAdr» where
