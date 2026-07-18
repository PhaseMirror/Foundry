import SnapKitty.Core

def getPolicyId (pid : String) : String := pid

def main : IO Unit := do
  let pid := "example-policy"
  let _ := getPolicyId pid
  IO.println s!"SnapKittyWasm main executed with pid {pid}"
