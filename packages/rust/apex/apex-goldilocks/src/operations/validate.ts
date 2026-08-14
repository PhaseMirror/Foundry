import * as path from 'path';
import { SchemaValidator } from '../core/schema-validator.js';
import { ValidationResult } from '../types.js';

export async function validateOperation(
  namespace?: string,
  specDir: string = path.join(process.cwd(), 'spec')
): Promise<{ content: Array<{ type: string; text: string }> }> {
  const validator = new SchemaValidator(specDir);

  try {
    let result: ValidationResult;

    if (namespace) {
      // Validate single component
      const validation = await validator.validateComponent(namespace);
      result = {
        success: validation.valid,
        namespace,
        errors: validation.errors,
      };
    } else {
      // Validate all components
      const validation = await validator.validateAllComponents();
      const errors: any[] = [];
      const componentSummary: string[] = [];

      for (const [ns, componentResult] of validation.componentResults) {
        if (!componentResult.valid) {
          errors.push(...componentResult.errors.map(e => ({
            ...e,
            component: ns,
          })));
          componentSummary.push(`❌ ${ns}: ${componentResult.errors.length} errors`);
        } else {
          componentSummary.push(`✅ ${ns}: valid`);
        }
      }

      result = {
        success: validation.valid,
        errors,
      };

      // Build detailed response
      let responseText = `Validation Results:\n\n`;
      responseText += componentSummary.join('\n');

      if (!validation.valid) {
        responseText += '\n\nDetailed Errors:\n';
        for (const [ns, componentResult] of validation.componentResults) {
          if (!componentResult.valid) {
            responseText += `\n${ns}:\n`;
            for (const error of componentResult.errors) {
              responseText += `  - ${error.file}: ${error.message}`;
              if (error.path) {
                responseText += ` (at ${error.path})`;
              }
              responseText += '\n';
            }
          }
        }
      }

      return {
        content: [
          {
            type: 'text',
            text: responseText,
          },
        ],
      };
    }

    // Format single component result
    if (result.success) {
      return {
        content: [
          {
            type: 'text',
            text: `✅ Component ${namespace} is valid and fully conformant`,
          },
        ],
      };
    } else {
      let errorText = `❌ Component ${namespace} validation failed:\n\n`;
      if (result.errors) {
        for (const error of result.errors) {
          errorText += `- ${error.file}: ${error.message}`;
          if (error.path) {
            errorText += ` (at ${error.path})`;
          }
          errorText += '\n';
        }
      }

      // Check for model evolution issues
      const validator2 = new SchemaValidator(specDir);
      const componentModel = await validator2.getComponentRequirements();
      if (componentModel) {
        errorText += '\n\nRequired conformance (from hologram.component.json):\n';
        for (const [key, req] of Object.entries(componentModel.conformance_requirements || {})) {
          const requirement = req as any;
          if (requirement.required) {
            errorText += `- ${key}: ${requirement.description}\n`;
          }
        }
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
          text: `Validation error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        },
      ],
    };
  }
}