import Lean
import Std

open Lean

def dumpLists : MetaM Unit := do
  let env ← getEnv
  let mut res := #[]
  for (name, cinfo) in env.constants.toList do
    let n := name.toString
    if n.startsWith "List.perm" || n.startsWith "List.Perm" then
      if n.contains 'i' && n.contains 'd' && n.contains 'x' && n.contains 'B' then
        res := res.push n
  IO.println (String.intercalate "\n" res.toList)

#eval! dumpLists
