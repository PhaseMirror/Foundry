import Foundations.universal_atomic.Examples

/-!
# Compatibility shim: `Foundations.UniversalAtomic.Examples`

The canonical implementation lives at `Foundations/universal_atomic/Examples.lean`
(lowercase path) and declares `namespace Foundations.UniversalAtomic`. This
shim makes the authored capital module identity resolvable on case-sensitive
filesystems. Import the lowercase module directly in new code.
-/
