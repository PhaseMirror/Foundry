/**
 * Hologram Component Manager
 * MCP Server and Core Functionality
 */

// Core exports
export { SchemaValidator } from './core/schema-validator.js';
export { ArtifactStore } from './core/artifact-store.js';

// Operation exports
export { validateOperation } from './operations/validate.js';
export { readOperation } from './operations/read.js';
export { updateOperation } from './operations/update.js';
export { deleteOperation } from './operations/delete.js';
export { submitArtifactOperation } from './operations/artifact.js';
export { submitManifestOperation } from './operations/manifest.js';
export {
  getComponentModelOperation,
  getSchemaOperation,
  listComponentsOperation,
  getComponentExampleOperation
} from './operations/discover.js';

// Type exports
export type {
  HologramBase,
  HologramComponent,
  ComponentFiles,
  ValidationResult,
  ValidationError,
  UpdateResult,
  DeleteResult,
  ReadResult,
  ConformanceRequirement
} from './types.js';