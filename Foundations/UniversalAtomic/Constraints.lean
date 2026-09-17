import Foundations.universal_atomic.Constraints

/-!
# Compatibility shim: `Foundations.UniversalAtomic.Constraints`

The canonical implementation lives at `Foundations/universal_atomic/Constraints.lean`
(lowercase path) and declares `namespace Foundations.UniversalAtomic`. This
shim makes the authored capital module identity resolvable on case-sensitive
filesystems. Import the lowercase module directly in new code.
-/
