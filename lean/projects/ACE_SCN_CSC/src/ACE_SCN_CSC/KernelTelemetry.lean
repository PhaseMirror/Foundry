namespace ACE_SCN_CSC

structure KernelTelemetry where
  xn_kernel : Float
  wt_max_kernel : Float
  protection_zeta : Float
  is_valid_kernel : Bool
  telemetry_version : Nat

structure ACECertificate where
  theta : List Nat
  xn_kernel : Float
  wt_max_kernel : Float
  protection_zeta : Float
  is_valid_kernel : Nat
  telemetry_version : Nat
  outputs : List Nat

end ACE_SCN_CSC
