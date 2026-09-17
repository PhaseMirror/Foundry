import ADR.Core


/-!
# DEPRECATED — retired `ADR.ADR.*` shadow scaffold

This is a legacy copy of the canonical `ADR.*` model and declares the **same
`ADR` namespace**. It is unreferenced by the build graph and must not be
imported alongside `ADR.*` (duplicate-declaration clash). Superseded by
`ADR/Core.lean` et al.; slated for removal. See `ADR/README.md`.
-/


/-!
# ADR Registry Examples
Instantiations of the core ADR structures for all accepted ADRs.
-/

namespace ADR.Examples

open ADR

def Registry : List ADR := []

end ADR.Examples