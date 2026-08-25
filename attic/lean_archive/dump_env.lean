import Lean
open Lean

def dumpPerms : MetaM Unit := do
  let env ← getEnv
  let mut perms := #[]
  for (name, cinfo) in env.constants.toList do
    let n := name.toString
    if n.contains 'P' && n.contains 'e' && n.contains 'r' && n.contains 'm' then
      perms := perms.push n
  IO.println (String.intercalate "\n" perms.toList)

#eval! dumpPerms
