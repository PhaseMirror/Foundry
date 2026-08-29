import Init
import AZTFTC.Core
import AZTFTC.Operators
import AZTFTC.GeoPotential
import AZTFTC.Boundary
import AZTFTC.Spectral
import AZTFTC.Casimir

/-! # AZ-TFTC — Export

Markdown export.
-/

namespace AZTFTC.Export

open AZTFTC
open AZTFTC.Operators
open AZTFTC.GeoPotential
open AZTFTC.Boundary
open AZTFTC.Spectral
open AZTFTC.Casimir

/-- Constants table. -/
def constantsToMd : String :=
  s!"# AZ-TFTC Constants\n\n" ++
  s!"| Symbol | Value |\n" ++
  s!"|--------|-------|\n" ++
  s!"| FP_DEN | {FP_DEN} |\n" ++
  s!"| defaultNPrimes | {defaultNPrimes} |\n" ++
  s!"| defaultM | {defaultM} |\n" ++
  s!"| defaultSigma | {defaultSigma} |\n" ++
  s!"| defaultG | {defaultG} |\n" ++
  s!"| defaultEta | {defaultEta} |\n" ++
  s!"| uMinFP | {uMinFP} |\n" ++
  s!"| uMaxFP | {uMaxFP} |\n"

/-- Prime statistics. -/
def primesToMd : String :=
  let primes := firstNPrimes defaultNPrimes
  s!"# Prime Statistics\n\n" ++
  s!"First {defaultNPrimes} primes: {primes.take 10}...\n" ++
  s!"π(100) = {pi 100}\n" ++
  s!"π(1000) = {pi 1000}\n"

/-- Geometric potential summary. -/
def geoToMd : String :=
  s!"# Geometric Potential\n\n" ++
  s!"Φ_σ length: {examplePhiSigma.length}\n" ++
  s!"V_geo length: {exampleVGeo.length}\n" ++
  s!"First 5 Φ_σ values: {examplePhiSigma.take 5}\n"

/-- Spectral results. -/
def spectralToMd : String :=
  s!"# Spectral Results\n\n" ++
  s!"Example dominant eigenvalues: {exampleSpectrum}\n" ++
  s!"Casimir deviation at 500 nm: {exampleDelta500nm}\n" ++
  s!"Curvature shift example: {exampleCurvatureShift}\n"

/-- Full export. -/
def fullExport : String :=
  constantsToMd ++ "\n" ++
  primesToMd ++ "\n" ++
  geoToMd ++ "\n" ++
  spectralToMd

end AZTFTC.Export
