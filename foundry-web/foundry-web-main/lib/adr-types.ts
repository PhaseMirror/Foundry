export type ADRStatus = 'Proposed' | 'Accepted' | 'Deprecated' | 'Superseded';

export type ArtifactKind = 'GitCommit' | 'LeanDeclaration' | 'SourceFile' | 'SpecificationDoc';

export interface ArtifactLink {
  uri: string;
  kind: ArtifactKind;
  description: string;
}

export interface ADR {
  id: string;
  title: string;
  status: ADRStatus;
  context: string;
  decision: string;
  consequences: string[];
  supersedes: string | null;
  links: ArtifactLink[];
}

export interface Claim {
  owner: string;
  claim: string;
}

export interface ADRRegistry {
  adrs: ADR[];
  claims: Claim[];
}

export interface FoundryMachineryStatus {
  version: string;
  ADRs: {
    total: number;
    accepted: number;
    proposed: number;
    deprecated: number;
    superseded: number;
  };
  registryValid: boolean;
  acyclic: boolean;
  noConflicts: boolean;
  exportAvailable: boolean;
  lastExport: string | null;
  /** Additive fields returned when the portal is wired to the Foundry engine. */
  engine?: {
    connected: boolean;
    root: string | null;
    readonly: boolean;
  };
  verification?: {
    total: number;
    passed: number;
    failed: number;
  };
  proofDebt?: {
    manifestVersion: string | null;
    permitted: number;
    manifestDrift: number | null;
    lastAudit: string | null;
    ok: boolean;
  };
  source?: 'engine' | 'fallback';
}

export interface FoundryAuditEntry {
  ADR_ID: string;
  Action: string;
  Timestamp: string;
  Status: string;
  Author: string;
}
