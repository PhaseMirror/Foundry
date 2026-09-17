import Foundations.universal_closure.UACalpBoundary

/-!
# Compatibility shim: `Foundations.UacAlpBoundary.Core`

The canonical implementation lives at
`Foundations/universal_closure/UACalpBoundary.lean` and declares
`namespace Foundations.UacAlpBoundary`. This shim makes the authored capital
module identity `Foundations.UacAlpBoundary.Core` resolvable on case-sensitive
filesystems. Import the lowercase module directly in new code.
-/