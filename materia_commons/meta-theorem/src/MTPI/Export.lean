import MTPI.ADR

namespace MTPI.Export

def exportToMarkdown (adr : ADR) : String :=
  s!"# {adr.id}: {adr.title}\n\n**Status:** {repr adr.status}\n\n**Context:** {adr.context}\n\n**Decision:** {adr.decision}"

end MTPI.Export
