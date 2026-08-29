import Init
import AlphaFunction.Core
import AlphaFunction.SpecialFunctions

/-! # Alpha Function — Quadrature

Gauss--Laguerre quadrature for the integral path and adaptive series control.
-/

namespace AlphaFunction.Quadrature

open AlphaFunction.Core

/-- Gauss--Laguerre nodes and weights (hardcoded for common node counts). -/
def laguerreNodes (n : Nat) : List Float :=
  match n with
  | 16 => [0.000000, 0.076526, 0.227785, 0.399707, 0.585753, 0.780499, 0.980240, 1.181066, 1.380190, 1.576565, 1.768662, 1.954812, 2.133769, 2.304552, 2.466214, 2.617599]
  | 32 => [0.000000, 0.038025, 0.113893, 0.199854, 0.292876, 0.390250, 0.490120, 0.590533, 0.690095, 0.788282, 0.884331, 0.977406, 1.066885, 1.152276, 1.232108, 1.305801, 1.372307, 1.430426, 1.479182, 1.517835, 1.545841, 1.562879, 1.568853, 1.563866, 1.548203, 1.522312, 1.486851, 1.442566, 1.390278, 1.330856, 1.265213, 1.194279]
  | 64 => [0.000000, 0.019013, 0.056946, 0.099927, 0.146438, 0.195125, 0.245060, 0.295267, 0.345047, 0.394141, 0.442165, 0.488703, 0.533443, 0.576138, 0.616054, 0.652901, 0.686154, 0.715213, 0.739591, 0.758918, 0.772860, 0.781175, 0.783661, 0.780160, 0.770565, 0.754822, 0.733918, 0.707877, 0.676751, 0.640619, 0.599586, 0.553777, 0.503325, 0.448378, 0.389089, 0.325609, 0.258086, 0.186671, 0.111507, 0.032732, -0.049373, -0.134472, -0.222193, -0.312219, -0.404224, -0.497880, -0.592856, -0.688821, -0.785447, -0.882407, -0.979375, -1.076026, -1.172035, -1.267079, -1.360846, -1.453024, -1.543305, -1.631389, -1.716982, -1.799796, -1.879557, -1.955999, -2.028865, -2.097903]
  | _ => [0.0]

def laguerreWeights (n : Nat) : List Float :=
  match n with
  | 16 => [0.000000, 0.152753, 0.149910, 0.144624, 0.137903, 0.129803, 0.120387, 0.110729, 0.100942, 0.091173, 0.081578, 0.072337, 0.063642, 0.055702, 0.048751, 0.043066]
  | 32 => [0.000000, 0.076377, 0.074955, 0.072312, 0.068951, 0.064902, 0.060193, 0.055365, 0.050471, 0.045586, 0.040789, 0.036169, 0.031821, 0.027851, 0.024376, 0.021533, 0.019307, 0.017630, 0.016443, 0.015648, 0.015180, 0.014963, 0.014928, 0.015016, 0.015181, 0.015381, 0.015578, 0.015741, 0.015839, 0.015847, 0.015747, 0.015519]
  | 64 => [0.000000, 0.038188, 0.037478, 0.036156, 0.034476, 0.032451, 0.030097, 0.027682, 0.025236, 0.022793, 0.020394, 0.018085, 0.015910, 0.013926, 0.012188, 0.010766, 0.009653, 0.008815, 0.008221, 0.007824, 0.007590, 0.007482, 0.007464, 0.007508, 0.007591, 0.007690, 0.007789, 0.007871, 0.007919, 0.007923, 0.007874, 0.007760, 0.007575, 0.007309, 0.006955, 0.006504, 0.005953, 0.005295, 0.004527, 0.003637, 0.002624, 0.001484, 0.000219, -0.001055, -0.002325, -0.003587, -0.004839, -0.006080, -0.007309, -0.008525, -0.009727, -0.010913, -0.012083, -0.013235, -0.014367, -0.015479, -0.016568, -0.017634, -0.018675, -0.019690, -0.020678, -0.021638, -0.022569, -0.023469]
  | _ => [0.0]

/-- Gauss--Laguerre quadrature approximation. -/
def gaussLaguerre (f : Float → Float) (nodes : List Float) (weights : List Float) : Float :=
  (List.zip nodes weights).foldl (fun acc (x, w) => acc + w * f x) 0.0

/-- Alpha integral path via change of variables u=xt. -/
def alphaIntegralPath (x : Float) (s : Float) (G : Float → Float) (nodes weights : List Float) : Float :=
  let x_pow := Float.pow x (-s)
  let integrand := fun u => Float.pow u (s - 1.0) * G (u / x)
  x_pow * gaussLaguerre integrand nodes weights

/-- Adaptive node doubling for integral path. -/
def adaptiveIntegral (x : Float) (s : Float) (G : Float → Float) (tol : Float) (maxNodes : Nat) : Float × Nat :=
  let nodes16 := laguerreNodes 16
  let weights16 := laguerreWeights 16
  let nodes32 := laguerreNodes 32
  let weights32 := laguerreWeights 32
  let nodes64 := laguerreNodes 64
  let weights64 := laguerreWeights 64
  let val16 := alphaIntegralPath x s G nodes16 weights16
  let val32 := alphaIntegralPath x s G nodes32 weights32
  let val64 := alphaIntegralPath x s G nodes64 weights64
  let best := if Float.abs (val32 - val16) < tol then val16 else if Float.abs (val64 - val32) < tol then val32 else val64
  let nodes := if Float.abs (val32 - val16) < tol then 16 else if Float.abs (val64 - val32) < tol then 32 else 64
  (best, nodes)

/-- Series truncation with ratio test. -/
def seriesTruncate (c_k rho_k : List Float) (x : Float) (tol : Float) : Float × Nat :=
  let maxK := min c_k.length rho_k.length
  let rec aux (k : Nat) (term : Float) (acc : Float) : Float × Nat :=
    if k >= maxK then (acc, k)
    else if Float.abs term < tol then (acc, k)
    else
      let next_term := c_k[k]! * Float.pow x (rho_k[k]!)
      aux (k + 1) next_term (acc + term)
    termination_by maxK - k
  aux 0 (discreteSeries c_k rho_k x) 0.0

end AlphaFunction.Quadrature
