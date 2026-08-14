import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import * as fs from 'fs';
import * as path from 'path';
import { ValidationError, ComponentIndex } from '../types.js';

export class SchemaValidator {
  private ajv: any;
  private schemasLoaded: boolean = false;
  private schemaCache: Map<string, any> = new Map();
  private specDir: string;

  constructor(specDir: string = path.join(process.cwd(), 'spec')) {
    this.specDir = specDir;
    this.ajv = new (Ajv as any)({
      allErrors: true,
      strict: false,  // Allow custom keywords like namespace, parent, etc.
      validateFormats: true,
      validateSchema: true,
      verbose: true,
    });
    (addFormats as any)(this.ajv);
  }

  /**
   * Load all schemas from spec/ directory
   */
  public async loadSchemas(): Promise<void> {
    if (this.schemasLoaded) return;

    // Load schemas from index files
    const files = fs.readdirSync(this.specDir);
    const indexFiles = files.filter(f => f.endsWith('.index.json'));

    for (const indexFile of indexFiles) {
      const indexPath = path.join(this.specDir, indexFile);
      try {
        const index: ComponentIndex = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));

        // Load spec file if it exists in the index
        if (index.artifacts.spec) {
          // Add .json extension to artifact reference
          const filename = `${index.artifacts.spec}.json`;
          const specPath = path.join(this.specDir, filename);
          if (fs.existsSync(specPath)) {
            const schema = JSON.parse(fs.readFileSync(specPath, 'utf-8'));
            const schemaId = schema.$id || `${index.namespace}.spec`;
            // Check if schema already exists before adding
            if (!this.ajv.getSchema(schemaId)) {
              this.ajv.addSchema(schema, schemaId);
              this.schemaCache.set(schemaId, schema);
            }
          }
        }
      } catch (error) {
        console.error(`Failed to load schema from index ${indexFile}:`, error);
      }
    }

    this.schemasLoaded = true;
  }

  /**
   * Validate a JSON object against a schema
   */
  public async validateAgainstSchema(
    data: any,
    schemaId: string
  ): Promise<{ valid: boolean; errors: ValidationError[] }> {
    await this.loadSchemas();

    const validate = this.ajv.getSchema(schemaId);
    if (!validate) {
      return {
        valid: false,
        errors: [{ file: schemaId, message: `Schema ${schemaId} not found` }],
      };
    }

    const valid = validate(data);
    const errors: ValidationError[] = [];

    if (!valid && validate.errors) {
      for (const error of validate.errors) {
        let detailedMessage = error.message || 'Validation error';

        // Enhance error message with context
        if (error.keyword === 'enum' && error.params?.allowedValues) {
          const allowedValues = error.params.allowedValues as string[];
          detailedMessage = `${error.message} - Expected one of: [${allowedValues.join(', ')}], Got: ${JSON.stringify(error.data)}`;
        } else if (error.keyword === 'required' && error.params?.missingProperty) {
          detailedMessage = `Missing required field: '${error.params.missingProperty}'`;
        } else if (error.keyword === 'type') {
          detailedMessage = `Type mismatch at ${error.instancePath || 'root'}: expected ${error.params?.type}, got ${typeof error.data}`;
        } else if (error.keyword === 'additionalProperties') {
          detailedMessage = `Unexpected property: '${error.params?.additionalProperty}'`;
        }

        errors.push({
          file: schemaId,
          message: detailedMessage,
          path: error.instancePath,
        });
      }
    }

    return { valid, errors };
  }

  /**
   * Validate base schema compliance
   */
  public async validateBaseSchema(
    data: any
  ): Promise<{ valid: boolean; errors: ValidationError[] }> {
    return this.validateAgainstSchema(data, 'hologram.spec');
  }

  /**
   * Get component model requirements
   */
  public async getComponentRequirements(): Promise<any | null> {
    // Look for hologram.component through its index
    const indexPath = path.join(this.specDir, 'hologram.component.index.json');
    if (!fs.existsSync(indexPath)) {
      return null;
    }

    try {
      const index: ComponentIndex = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
      if (index.artifacts.spec) {
        // Load the spec file which contains conformance requirements
        const filename = `${index.artifacts.spec}.json`;
        const specPath = path.join(this.specDir, filename);
        const spec = JSON.parse(fs.readFileSync(specPath, 'utf-8'));
        // Return the spec directly - it already has the component structure
        return spec;
      }
    } catch (error) {
      console.error('Failed to load hologram.component spec:', error);
    }

    return null;
  }

  /**
   * Validate a complete component (all 6 files)
   */
  public async validateComponent(
    namespace: string
  ): Promise<{ valid: boolean; errors: ValidationError[] }> {
    const errors: ValidationError[] = [];

    // Get component requirements from model
    const componentModel = await this.getComponentRequirements();
    if (!componentModel) {
      errors.push({
        file: 'hologram.component.json',
        message: 'Component model not found',
      });
      return { valid: false, errors };
    }

    // Required conformance types based on model
    const conformanceReqs = componentModel.conformance_requirements || {};
    const requiredConformance = Object.keys(conformanceReqs)
      .filter(key => conformanceReqs[key].required);

    // Load component index
    const indexPath = path.join(this.specDir, `${namespace}.index.json`);
    if (!fs.existsSync(indexPath)) {
      errors.push({
        file: `${namespace}.index.json`,
        message: 'Component index not found',
      });
      return { valid: false, errors };
    }

    let index: ComponentIndex;
    try {
      index = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
    } catch (e) {
      errors.push({
        file: `${namespace}.index.json`,
        message: `Invalid index file: ${e instanceof Error ? e.message : 'Unknown error'}`,
      });
      return { valid: false, errors };
    }

    // Validate index structure
    if (index.namespace !== namespace) {
      errors.push({
        file: `${namespace}.index.json`,
        message: `Index namespace mismatch: expected ${namespace}, got ${index.namespace}`,
      });
    }

    // Check for missing required files in index
    if (!index.artifacts.spec) {
      errors.push({
        file: `${namespace}.index.json`,
        message: `Required spec file missing from index`,
      });
    }
    for (const conformanceType of requiredConformance) {
      if (!index.artifacts[conformanceType]) {
        errors.push({
          file: `${namespace}.index.json`,
          message: `Required ${conformanceType} conformance file missing from index`,
        });
      }
    }

    // Load component files from index
    const componentFiles: { [key: string]: any } = {};
    for (const [type, artifactRef] of Object.entries(index.artifacts)) {
      if (artifactRef) {
        // Add .json extension to artifact reference to get actual filename
        const filename = `${artifactRef}.json`;
        const filePath = path.join(this.specDir, filename);
        if (!fs.existsSync(filePath)) {
          errors.push({
            file: filename,
            message: `Artifact referenced in index not found`,
          });
          continue;
        }
        try {
          const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
          componentFiles[type] = { file: filename, artifactRef, content };
        } catch (e) {
          errors.push({
            file: filename,
            message: `Failed to parse JSON: ${e instanceof Error ? e.message : 'Unknown error'}`,
          });
        }
      }
    }

    // Validate each file that we found
    for (const [type, fileInfo] of Object.entries(componentFiles)) {
      const { file, content } = fileInfo;

      try {
        // Skip base schema validation for spec files - they're JSON Schemas
        if (type !== 'spec') {
          // Validate against base schema
          const baseValidation = await this.validateBaseSchema(content);
          if (!baseValidation.valid) {
            errors.push(...baseValidation.errors.map(e => ({
              ...e,
              file,
            })));
          }

          if (type === 'spec') {
            // Skip base schema validation for spec files - they're JSON Schemas
          } else {
            // Validate conformance file
            const conformanceType = type;

            // Verify the file has the appropriate conformance field
            if (!content[conformanceType]) {
              errors.push({
                file,
                message: `Conformance file missing required field: ${conformanceType}`,
              });
            }

            // Validate conformance files against their specs
            if (requiredConformance.includes(conformanceType)) {
              const conformanceSpec = `hologram.${conformanceType}.spec`;
              const conformanceValidation = await this.validateAgainstSchema(content, conformanceSpec);
              if (!conformanceValidation.valid) {
                errors.push(...conformanceValidation.errors.map(e => ({
                  ...e,
                  file,
                })));
              }
            }
          }
        } else {
          // For spec files, validate they're valid JSON Schemas
          try {
            const ajv = this.ajv;
            // Check if schema is already compiled
            const schemaId = content.$id || `${namespace}.spec`;
            if (!ajv.getSchema(schemaId)) {
              ajv.compile(content);
            }
          } catch (error) {
            errors.push({
              file,
              message: `Invalid JSON Schema: ${error instanceof Error ? error.message : 'Unknown error'}`,
            });
          }
        }
      } catch (error) {
        errors.push({
          file,
          message: `Validation error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        });
      }
    }

    // Handle self-referential validation (e.g., test.test.json)
    const isSelfReferential = requiredConformance.some(c =>
      namespace === `hologram.${c}`
    );
    if (isSelfReferential) {
      const selfConformanceType = namespace.replace('hologram.', '');
      if (index.artifacts[selfConformanceType] && componentFiles[selfConformanceType]) {
        const { content, file } = componentFiles[selfConformanceType];
        // Validate against the spec this component defines
        const validation = await this.validateAgainstSchema(content, `${namespace}.spec`);
        if (!validation.valid) {
          errors.push(...validation.errors.map(e => ({
            ...e,
            file,
          })));
        }
      }
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  /**
   * Validate all components in spec/
   */
  public async validateAllComponents(): Promise<{
    valid: boolean;
    componentResults: Map<string, { valid: boolean; errors: ValidationError[] }>;
  }> {
    const files = fs.readdirSync(this.specDir);
    const namespaces = new Set<string>();

    // Collect components by looking for index files
    for (const file of files) {
      if (file.endsWith('.index.json')) {
        const namespace = file.replace('.index.json', '');
        namespaces.add(namespace);
      }
    }

    const componentResults = new Map<string, { valid: boolean; errors: ValidationError[] }>();
    let allValid = true;

    for (const namespace of namespaces) {
      const result = await this.validateComponent(namespace);
      componentResults.set(namespace, result);
      if (!result.valid) {
        allValid = false;
      }
    }

    return {
      valid: allValid,
      componentResults,
    };
  }
}