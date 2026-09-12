import * as path from 'path';
import { SchemaValidator } from '../core/schema-validator.js';
import { ArtifactStore } from '../core/artifact-store.js';
import { ValidationError } from '../types.js';

const artifactStore = new ArtifactStore();

export async function submitArtifactOperation(
  content: any,
  type: 'spec' | 'conformance',
  specDir: string = path.join(process.cwd(), 'spec')
): Promise<{ content: Array<{ type: string; text: string }> }> {
  const validator = new SchemaValidator(specDir);
  const errors: ValidationError[] = [];

  try {
    // Phase 1: Basic JSON validation
    if (!content || typeof content !== 'object') {
      return {
        content: [
          {
            type: 'text',
            text: '❌ Invalid JSON content provided',
          },
        ],
      };
    }

    // Phase 2: Determine schema based on type and namespace
    const namespace = content.namespace || content.$id?.replace('.spec.json', '');

    // Determine appropriate schema
    if (type === 'spec') {
      // Spec files should be valid JSON schemas

      // Validate it's a proper JSON schema
      try {
        const ajv = (validator as any).ajv;
        ajv.compile(content);
      } catch (error) {
        errors.push({
          file: namespace || 'artifact',
          message: `Invalid JSON Schema: ${error instanceof Error ? error.message : 'Unknown error'}`,
        });
      }
    } else {
      // Conformance files validate against base schema
      const baseValidation = await validator.validateBaseSchema(content);
      if (!baseValidation.valid) {
        errors.push(...baseValidation.errors);
      }

      // Schema validation will check for required fields like namespace
      // NOTE: Conformance validation against their specs
      // happens in the manifest phase, not here, because those specs might
      // only exist in the artifact store and not in the filesystem yet.
      // This allows for atomic component creation where all artifacts are
      // submitted first, then validated together during manifest submission.
    }

    // Phase 3: Verify all $ref and $schema references are valid
    if (content.$ref || content.$schema) {
      // Basic reference validation
      const ref = content.$ref || content.$schema;
      if (typeof ref !== 'string') {
        errors.push({
          file: namespace || 'artifact',
          message: 'Invalid $ref or $schema reference',
        });
      }
    }

    // Phase 4: If validation passed, generate CID and store
    if (errors.length === 0) {
      const cid = artifactStore.storeArtifact(content);

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              success: true,
              cid,
              type,
              namespace,
              validated: true,
            }, null, 2),
          },
        ],
      };
    } else {
      // Return validation errors
      let errorText = `❌ Artifact validation failed:\n\n`;
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
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Artifact submission error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        },
      ],
    };
  }
}