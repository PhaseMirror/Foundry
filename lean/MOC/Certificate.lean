import MOC.Core

namespace MOC

structure Certificate where
  prime_decomposition : List Nat
  spectral_radius_num : Nat
  spectral_radius_den : Nat
  drift : Nat

def is_contractive (c : Certificate) : Prop :=
  c.spectral_radius_num < c.spectral_radius_den

def generate_certificate_json (c : Certificate) : String :=
  "{\n  \"prime_decomposition\": " ++ toString c.prime_decomposition ++ ",\n" ++
  "  \"spectral_radius\": {\"num\": " ++ toString c.spectral_radius_num ++ ", \"den\": " ++ toString c.spectral_radius_den ++ "},\n" ++
  "  \"drift\": " ++ toString c.drift ++ "\n}"

def canonical_cert : Certificate :=
  { prime_decomposition := [2, 3, 5],
    spectral_radius_num := 999999,
    spectral_radius_den := 1000000,
    drift := 0 }

#eval IO.println (generate_certificate_json canonical_cert)

end MOC
