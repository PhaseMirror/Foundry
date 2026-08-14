# Architecture Decision Record (ADR) Scaffold

This directory contains the production‑grade ADR scaffold for the **Genesis ODE** Lean substrate.

## Directory Structure
```
adr/
  ADR-001_Core_vs_Experimental_Scope_v1_2.md
  ADR-002_Experimental_Branch_Governance_v1.1.md
  ADR-003_Track_A_Metallurgical_Exploder_MVP.md
  ADR-004-ADR-Scaffold.md      # This file
  ADR-005-architecture.md
  ADR-006-Embed-BRA.md
  ADR-007.md
  ADR-008.md
  ADR-009.md
  ADR-010.md
  ADR-011.md
  ADR-012.md
  ADR-013.md
  ADR-014.md
  ADR-015.md
  ADR-016.md
  ADR-033-Implementation-Lock.md
```

## Usage
1. **Create a new ADR**: copy `adr/ADR-XXXX-Template.md` to a new file with a sequential number and descriptive title.
2. **Fill in the sections**: each ADR follows the template below.
3. **Link from documentation**: reference ADRs in `main.md` or other docs using markdown links.

---

### ADR Template (`ADR-XXXX-Template.md`)
```markdown
# ADR XXXX: <Title>

*Status*: Proposed | Accepted | Superseded | Deprecated
*Date*: YYYY‑MM‑DD

## Context
Explain the problem or situation that prompted this decision.

## Decision
State the chosen approach clearly.

## Consequences
List positive and negative impacts of the decision.

## Links
- Related ADRs
- Relevant source files
```
