import Lake
open Lake DSL

package ElasticTether

lean_lib ElasticTether

@[default_target]
lean_exe ElasticTetherTest {
  root := `ElasticTether.Main
}
