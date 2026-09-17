import Foundations.universal_atomic.Enhancement

/-!
# Compatibility shim: `Foundations.UniversalAtomic.Enhancement`

The canonical implementation lives at `Foundations/universal_atomic/Enhancement.lean`
(lowercase path) and declares `namespace Foundations.UniversalAtomic`. This
shim makes the authored capital module identity resolvable on case-sensitive
filesystems. Import the lowercase module directly in new code.
-/
