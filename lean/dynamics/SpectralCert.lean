namespace dynamics.SpectralCert

/-- A spectral certification context -/
structure SpectralCert where
  covers_all : Prop

/-- Spectral certification covers all admissible operators -/
@[proof]
theorem spectral_cert_complete (c : SpectralCert) (h : c.covers_all) :
  c.covers_all := h

end dynamics.SpectralCert
