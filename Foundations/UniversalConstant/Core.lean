import Foundations.universal_constant.Core

/-!
# Compatibility shim: `Foundations.UniversalConstant.Core`

The canonical implementation lives at `Foundations/universal_constant/Core.lean`
(lowercase path) and declares `namespace Foundations.UniversalConstant`. This
shim makes the authored capital module identity `Foundations.UniversalConstant.Core`
resolvable on case-sensitive filesystems. Import the lowercase module directly
in new code.
-/