import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import { SchemaValidator } from '../core/schema-validator.js';
import { ArtifactStore } from '../core/artifact-store.js';
import { ValidationError, ComponentIndex } from '../types.js';

const artifactStore = new ArtifactStore();

export async function submitManifestOperation(
  namespace: string,
  artifacts: Record<string, string>,
  specDir: string = path.join(process.cwd(), 'spec')
): Promise<{ content: Array<{ type: string; text: string }> }> {
  const validator = new SchemaValidator(specDir);
  const errors: ValidationError[] = [];

  try {
    // Phase 1: Load hologram.component.json to get requirements
    const componentModel = await validator.getComponentRequirements();
    if (!componentModel) {
      return {
        content: [
          {
            type: 'text',
            text: '❌ hologram.component.json not found - cannot determine requirements',
          },
        ],
      };
    }

    // Phase 1.5: Validate namespace and check if component already exists
    // Check for conformance-like patterns in namespace
    const conformanceTypes = Object.keys(componentModel.conformance_requirements || {});
    const namespaceParts = namespace.split('.');
    if (namespaceParts.length > 2) {
      const lastPart = namespaceParts[namespaceParts.length - 1];
      if (conformanceTypes.includes(lastPart)) {
        return {
          content: [
            {
              type: 'text',
              text: `❌ Invalid component namespace "${namespace}". The namespace appears to be a conformance file pattern (ends with .${lastPart}). Components should not have conformance type suffixes.`,
            },
          ],
        };
      }
    }

    const indexPath = path.join(specDir, `${namespace}.index.json`);
    if (fs.existsSync(indexPath)) {
      return {
        content: [
          {
            type: 'text',
            text: `❌ Component ${namespace} already exists. Use update to modify it or delete it first before creating a new one.`,
          },
        ],
      };
    }

    // Phase 2: Verify ALL required artifacts present
    const conformanceReqs = componentModel.conformance_requirements || {};
    const requiredConformance = Object.keys(conformanceReqs)
      .filter(key => conformanceReqs[key].required);

    // Check for spec (required)
    if (!artifacts.spec) {
      errors.push({
        file: `${namespace}.spec.json`,
        message: 'Missing spec artifact CID',
      });
    }

    // Check for all required conformance
    for (const conformanceType of requiredConformance) {
      if (!artifacts[conformanceType]) {
        errors.push({
          file: `${namespace}.${conformanceType}.json`,
          message: `Missing ${conformanceType} conformance artifact CID`,
        });
      }
    }

    if (errors.length > 0) {
      return formatErrors(namespace, errors);
    }

    // Phase 3: Load all artifacts by CID
    const loadedArtifacts: Map<string, any> = new Map();

    for (const [type, cid] of Object.entries(artifacts)) {
      const artifact = artifactStore.getArtifact(cid);
      if (!artifact) {
        errors.push({
          file: type,
          message: `Artifact not found: ${cid}`,
        });
      } else {
        loadedArtifacts.set(type, artifact);
      }
    }

    if (errors.length > 0) {
      return formatErrors(namespace, errors);
    }

    // Phase 4: Validate each artifact against its schema AGAIN
    for (const [type, content] of loadedArtifacts) {
      // Skip base schema validation for spec files - they're JSON Schemas
      if (type !== 'spec') {
        // Validate against base schema
        const baseValidation = await validator.validateBaseSchema(content);
        if (!baseValidation.valid) {
          errors.push(...baseValidation.errors.map(e => ({
            ...e,
            file: `${namespace}.${type}.json`,
          })));
        }

        // Validate namespace consistency
        const expectedNamespace = `${namespace}.${type}`;

        if (content.namespace !== expectedNamespace) {
          errors.push({
            file: `${namespace}.${type}.json`,
            message: `Namespace mismatch: expected ${expectedNamespace}, got ${content.namespace}`,
          });
        }

        // Validate conformance flag - conformance files must have conformance: true
        const expectedConformance = true; // All non-spec artifacts are conformance files
        if (content.conformance !== expectedConformance) {
          errors.push({
            file: `${namespace}.${type}.json`,
            message: `Conformance flag mismatch: expected ${expectedConformance}, got ${content.conformance}`,
          });
        }
      } else {
        // For spec files, validate they're valid JSON Schemas
        try {
          const ajv = (validator as any).ajv;
          // Check if schema is already compiled (from artifact phase)
          const schemaId = content.$id || `${namespace}.spec.json`;
          if (!ajv.getSchema(schemaId)) {
            ajv.compile(content);
          }
        } catch (error) {
          errors.push({
            file: `${namespace}.spec.json`,
            message: `Invalid JSON Schema: ${error instanceof Error ? error.message : 'Unknown error'}`,
          });
        }
      }
    }

    // Phase 5: No implementation validation needed anymore

    // Each conformance validates against its conformance spec
    const allConformanceTypes = Object.keys(componentModel.conformance_requirements || {});
    for (const conformanceType of allConformanceTypes) {
      const conformance = loadedArtifacts.get(conformanceType);
      if (conformance) {
        const conformanceSpecFile = `hologram.${conformanceType}.spec`;
        const conformanceValidation = await validator.validateAgainstSchema(conformance, conformanceSpecFile);
        if (!conformanceValidation.valid) {
          errors.push(...conformanceValidation.errors.map(e => ({
            ...e,
            file: `${namespace}.${conformanceType}.json`,
          })));
        }
      }
    }

    // Phase 6: Handle recursive validation
    // Detect self-referential conformance (e.g., test.test)
    const isSelfReferential = allConformanceTypes.some(c =>
      namespace === `hologram.${c}`
    );

    if (isSelfReferential) {
      const selfConformanceType = namespace.replace('hologram.', '');
      const selfConformance = loadedArtifacts.get(selfConformanceType);
      const spec = loadedArtifacts.get('spec');

      if (selfConformance && spec) {
        // Temporarily save spec for validation
        const specPath = path.join(specDir, `${namespace}.spec.json`);
        const tempSpecExists = fs.existsSync(specPath);

        if (!tempSpecExists) {
          fs.writeFileSync(specPath, JSON.stringify(spec, null, 2));
        }

        // Validate self-referential conformance against the spec this component defines
        const validation = await validator.validateAgainstSchema(selfConformance, `${namespace}.spec.json`);
        if (!validation.valid) {
          errors.push(...validation.errors.map(e => ({
            ...e,
            file: `${namespace}.${selfConformanceType}.json`,
          })));
        }

        // Clean up temp spec if we created it
        if (!tempSpecExists) {
          fs.unlinkSync(specPath);
        }
      }
    }

    // Phase 7: If ANY validation fails, reject
    if (errors.length > 0) {
      return formatErrors(namespace, errors);
    }

    // Phase 8: Atomic write - all or nothing with content-addressed filenames
    const writtenFiles: string[] = [];
    const index: ComponentIndex = {
      namespace,
      artifacts: {},
    };

    try {
      // Helper to calculate SHA256 and write content-addressed file
      const writeContentAddressed = (_type: string, content: any): string => {
        const jsonContent = JSON.stringify(content, null, 2);
        const hash = crypto.createHash('sha256').update(jsonContent).digest('hex');
        const filename = `${namespace}.${hash}.json`;
        const filepath = path.join(specDir, filename);
        fs.writeFileSync(filepath, jsonContent);
        writtenFiles.push(filename);
        // Return artifact reference without .json extension
        return `${namespace}.${hash}`;
      };

      // Write spec
      const specContent = loadedArtifacts.get('spec');
      index.artifacts.spec = writeContentAddressed('spec', specContent);

      // Write all provided conformance files
      // First get all possible conformance types from the model
      const modelConformanceTypes = Object.keys(componentModel.conformance_requirements || {});
      // Then add any conformance types that are actually provided in the artifacts
      const providedConformanceTypes = new Set([...modelConformanceTypes]);
      for (const [type] of loadedArtifacts) {
        if (type !== 'spec') {
          providedConformanceTypes.add(type);
        }
      }

      // Write all provided conformance files
      for (const conformanceType of providedConformanceTypes) {
        const conformanceContent = loadedArtifacts.get(conformanceType);
        if (conformanceContent) {
          index.artifacts[conformanceType] = writeContentAddressed(conformanceType, conformanceContent);
        }
      }

      // Write the index file last
      fs.writeFileSync(indexPath, JSON.stringify(index, null, 2));
      writtenFiles.push(`${namespace}.index.json`);

      // Final validation of complete component
      const finalValidation = await validator.validateComponent(namespace);
      if (!finalValidation.valid) {
        // Rollback if final validation fails
        for (const fileName of writtenFiles) {
          try {
            fs.unlinkSync(path.join(specDir, fileName));
          } catch {
            // Ignore cleanup errors
          }
        }
        return formatErrors(namespace, finalValidation.errors);
      }

      // Success - artifacts are now persisted in spec/
      // The artifact store will be cleaned by the Makefile when needed

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              success: true,
              namespace,
              component: {
                files: writtenFiles,
                artifacts: artifacts,
              },
              message: `✅ Successfully created component ${namespace} with ${writtenFiles.length} files`,
            }, null, 2),
          },
        ],
      };

    } catch (writeError) {
      // Rollback on error
      for (const fileName of writtenFiles) {
        const filePath = path.join(specDir, fileName);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      }
      throw writeError;
    }

  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Manifest submission error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        },
      ],
    };
  }
}

function formatErrors(namespace: string, errors: ValidationError[]) {
  let errorText = `❌ Failed to create component ${namespace} from manifest:\n\n`;
  for (const error of errors) {
    errorText += `- ${error.file}: ${error.message}`;
    if (error.path) {
      errorText += ` (at ${error.path})`;
    }
    errorText += '\n';
  }

  return {
    content: [
      {
        type: 'text',
        text: errorText,
      },
    ],
  };
}