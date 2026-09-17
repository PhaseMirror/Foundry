import Foundations.universal_closure.Core

/-!
# Compatibility shim: `Foundations.UniversalClosure.Core`

The canonical implementation lives at `Foundations/universal_closure/Core.lean`
(lowercase path) and declares `namespace Foundations.UniversalClosure`. This
shim makes the authored capital module identity `Foundations.UniversalClosure.Core`
resolvable on case-sensitive filesystems (Linux/macOS). Import the lowercase
module directly in new code.
-/