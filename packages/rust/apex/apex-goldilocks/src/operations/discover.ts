import * as fs from 'fs';
import * as path from 'path';
import { SchemaValidator } from '../core/schema-validator.js';

/**
 * Get the component model - what files are required for a complete component
 */
export async function getComponentModelOperation(): Promise<{ content: Array<{ type: string; text: string }> }> {
  const validator = new SchemaValidator(path.join(process.cwd(), 'spec'));

  try {
    const componentModel = await validator.getComponentRequirements();

    if (!componentModel) {
      return {
        content: [{
          type: 'text',
          text: '❌ Component model (hologram.component.json) not found'
        }]
      };
    }

    // Build a guide for the LLM
    let guide = 'HOLOGRAM COMPONENT MODEL\n';
    guide += '========================\n\n';

    const conformanceCount = Object.keys(componentModel.conformance_requirements || {}).filter(
      key => (componentModel.conformance_requirements as any)[key].required
    ).length;
    const totalFiles = 1 + conformanceCount; // 1 spec + N conformance
    guide += `To create a complete Hologram component, you need exactly ${totalFiles} files:\n\n`;

    guide += '1. SPECIFICATION FILE ({namespace}.spec.json):\n';
    guide += '   - Purpose: The component definition itself\n';
    guide += '   - Contains: JSON Schema OR component properties\n';
    guide += '   - Required fields: namespace, conformance (=false), version, description\n';
    guide += '   - Note: The spec file IS the component when conformance=false\n\n';

    guide += '2. REQUIRED CONFORMANCE FILES:\n';

    const conformanceDescriptions: Record<string, string> = {
      interface: 'Every component must define its public interface',
      docs: 'Every component must have documentation',
      test: 'Every component must have tests',
      manager: 'Every component must define lifecycle management'
    };

    for (const [key, req] of Object.entries(componentModel.conformance_requirements || {})) {
      const requirement = req as any;
      if (requirement.required) {
        guide += `\n   ${key.toUpperCase()} ({namespace}.${key}.json):\n`;
        guide += `   - Purpose: ${conformanceDescriptions[key] || requirement.description || 'Required conformance'}\n`;
        guide += `   - Schema: ${requirement.schema}\n`;
        guide += `   - Required fields: namespace, parent, conformance=true, ${key}\n`;
      }
    }

    guide += '\nKEY RULES:\n';
    guide += '• All namespaces must follow pattern: hologram[.subcomponent]*\n';
    guide += '• Parent must reference the correct parent component\n';
    guide += '• Conformance flag: false for spec/component files, true for conformance files\n';
    guide += '• Every conformance component (interface, docs, test, manager) must have its own full conformance\n';
    guide += '• Self-referential conformance is required (e.g., test.test.json)\n';

    guide += '\nWORKFLOW:\n';
    guide += '1. Use submitArtifact for each file (validates individually)\n';
    guide += '2. Collect CIDs from each submission\n';
    guide += '3. Use submitManifest with namespace and CIDs to create complete component\n';

    guide += '\n⚠️ IMPORTANT SEQUENCING:\n';
    guide += '• When adding new conformance requirements:\n';
    guide += '  1. FIRST: Add conformance files to all existing components\n';
    guide += '  2. THEN: Update the spec to require the new conformance\n';
    guide += '• Update operations validate the ENTIRE component\n';
    guide += '• Cannot require conformance that doesn\'t exist yet\n';
    guide += '• Use validateArtifact to preview validation before saving\n';
    guide += '• Use explainValidation to understand what checks are performed\n';

    return {
      content: [{
        type: 'text',
        text: guide
      }]
    };
  } catch (error) {
    return {
      content: [{
        type: 'text',
        text: `Error: ${error instanceof Error ? error.message : 'Unknown error'}`
      }]
    };
  }
}

/**
 * Get a specific schema to understand structure requirements
 */
export async function getSchemaOperation(
  schemaName: string,
  specDir: string = path.join(process.cwd(), 'spec')
): Promise<{ content: Array<{ type: string; text: string }> }> {
  try {
    // Handle different schema naming patterns
    let schemaPath: string | undefined;
    let actualFile: string | undefined;

    // First try: exact match with .json
    if (schemaName.endsWith('.json')) {
      const testPath = path.join(specDir, schemaName);
      if (fs.existsSync(testPath)) {
        schemaPath = testPath;
        actualFile = schemaName;
      }
    }

    // Second try: add .spec.json
    if (!schemaPath) {
      const fileName = `${schemaName}.spec.json`;
      const testPath = path.join(specDir, fileName);
      if (fs.existsSync(testPath)) {
        schemaPath = testPath;
        actualFile = fileName;
      }
    }

    // Third try: look for index.json to find spec artifact
    if (!schemaPath && !schemaName.includes('.spec')) {
      const indexPath = path.join(specDir, `${schemaName}.index.json`);
      if (fs.existsSync(indexPath)) {
        const index = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
        if (index.artifacts?.spec) {
          actualFile = `${index.artifacts.spec}.json`;
          schemaPath = path.join(specDir, actualFile);
        }
      }
    }

    if (!schemaPath || !fs.existsSync(schemaPath)) {
      // List available schemas to help
      const specFiles = fs.readdirSync(specDir)
        .filter(f => f.endsWith('.spec.json'))
        .map(f => f.replace('.spec.json', ''));

      const indexFiles = fs.readdirSync(specDir)
        .filter(f => f.endsWith('.index.json'))
        .map(f => f.replace('.index.json', ''));

      return {
        content: [{
          type: 'text',
          text: `Schema '${schemaName}' not found.\n\nAvailable schemas:\n${specFiles.map(f => `  - ${f}`).join('\n')}\n\nComponents with specs:\n${indexFiles.map(f => `  - ${f}`).join('\n')}\n\nExamples:\n  getSchema("hologram.interface")\n  getSchema("hologram.component.spec")`
        }]
      };
    }

    const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf-8'));

    // Add helpful context
    let response = `SCHEMA: ${actualFile}\n`;
    response += '=' .repeat(50) + '\n\n';
    response += JSON.stringify(schema, null, 2);
    response += '\n\n';
    response += 'KEY POINTS:\n';

    // Extract required fields
    if (schema.required) {
      response += `• Required fields: ${schema.required.join(', ')}\n`;
    }

    // Extract properties
    if (schema.properties) {
      response += `• Properties: ${Object.keys(schema.properties).join(', ')}\n`;
    }

    // Note patterns
    if (schema.properties?.namespace?.pattern) {
      response += `• Namespace pattern: ${schema.properties.namespace.pattern}\n`;
    }

    return {
      content: [{
        type: 'text',
        text: response
      }]
    };
  } catch (error) {
    return {
      content: [{
        type: 'text',
        text: `Error: ${error instanceof Error ? error.message : 'Unknown error'}`
      }]
    };
  }
}

/**
 * List all components and their status
 */
export async function listComponentsOperation(): Promise<{ content: Array<{ type: string; text: string }> }> {
  const validator = new SchemaValidator(path.join(process.cwd(), 'spec'));

  try {
    const validation = await validator.validateAllComponents();

    let response = 'HOLOGRAM COMPONENTS STATUS\n';
    response += '=' .repeat(50) + '\n\n';

    const components = Array.from(validation.componentResults.keys()).sort();

    for (const namespace of components) {
      const result = validation.componentResults.get(namespace);
      const status = result?.valid ? '✅' : '❌';

      response += `${status} ${namespace}`;

      if (!result?.valid && result?.errors) {
        const missingFiles = result.errors
          .filter(e => e.message.includes('Required file missing'))
          .map(e => e.file.replace(`${namespace}.`, '').replace('.json', ''));

        if (missingFiles.length > 0) {
          response += ` (missing: ${missingFiles.join(', ')})`;
        }
      }

      response += '\n';
    }

    response += '\n' + '=' .repeat(50) + '\n';
    response += `Total: ${components.length} components\n`;
    response += `Valid: ${Array.from(validation.componentResults.values()).filter(r => r.valid).length}\n`;
    response += `Invalid: ${Array.from(validation.componentResults.values()).filter(r => !r.valid).length}\n`;

    response += '\nTo create a new component, use getComponentModel() for guidance';

    return {
      content: [{
        type: 'text',
        text: response
      }]
    };
  } catch (error) {
    return {
      content: [{
        type: 'text',
        text: `Error: ${error instanceof Error ? error.message : 'Unknown error'}`
      }]
    };
  }
}

/**
 * List all available schemas
 */
export async function listSchemasOperation(
  specDir: string = path.join(process.cwd(), 'spec')
): Promise<{ content: Array<{ type: string; text: string }> }> {

  try {
    // Find all spec files
    const specFiles = fs.readdirSync(specDir)
      .filter(f => f.endsWith('.spec.json'))
      .map(f => f.replace('.spec.json', ''));

    // Find all components with specs via index files
    const componentsWithSpecs: string[] = [];
    const indexFiles = fs.readdirSync(specDir)
      .filter(f => f.endsWith('.index.json'));

    for (const indexFile of indexFiles) {
      const namespace = indexFile.replace('.index.json', '');
      const indexPath = path.join(specDir, indexFile);
      try {
        const index = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
        if (index.artifacts?.spec) {
          componentsWithSpecs.push(namespace);
        }
      } catch (e) {
        // Skip invalid index files
      }
    }

    let response = 'AVAILABLE SCHEMAS\n';
    response += '=' .repeat(50) + '\n\n';

    response += 'Direct Schema Files:\n';
    for (const spec of specFiles.sort()) {
      response += `  • ${spec}\n`;
    }

    response += '\nComponent Schemas (access via namespace):\n';
    for (const comp of componentsWithSpecs.sort()) {
      response += `  • ${comp}\n`;
    }

    response += '\nUsage Examples:\n';
    response += '  getSchema("hologram.component.spec")\n';
    response += '  getSchema("hologram.interface")\n';
    response += '  getSchema("hologram.view")\n';

    response += '\nNote: For conformance components, use the namespace\n';
    response += '(e.g., "hologram.test") to get the spec schema.';

    return {
      content: [{
        type: 'text',
        text: response
      }]
    };
  } catch (error) {
    return {
      content: [{
        type: 'text',
        text: `Error listing schemas: ${error instanceof Error ? error.message : 'Unknown error'}`
      }]
    };
  }
}

/**
 * Get an example component structure to use as a template
 */
export async function getComponentExampleOperation(
  componentType?: 'simple' | 'conformance' | 'operation'
): Promise<{ content: Array<{ type: string; text: string }> }> {
  const type = componentType || 'simple';

  let example = `EXAMPLE: Creating a ${type} component\n`;
  example += '=' .repeat(50) + '\n\n';

  switch (type) {
    case 'conformance':
      example += 'EXAMPLE: hologram.newconformance\n\n';
      example += '1. Spec file (hologram.newconformance.spec.json):\n';
      example += JSON.stringify({
        "$schema": "http://json-schema.org/draft-07/schema#",
        "$id": "hologram.newconformance.spec.json",
        "title": "New Conformance Type",
        "type": "object",
        "properties": {
          "namespace": { "type": "string" },
          "parent": { "type": "string" },
          "conformance": { "type": "boolean" },
          "newconformance": {
            "type": "object",
            "properties": {
              "version": { "type": "string" },
              "description": { "type": "string" }
            }
          }
        },
        "required": ["namespace", "parent", "conformance", "newconformance"]
      }, null, 2);

      example += '\n\n2. Component Definition (hologram.newconformance.json):\n';
      example += JSON.stringify({
        "namespace": "hologram.newconformance",
        "parent": "hologram",
        "conformance": false,
        "version": "0.1.0",
        "description": "Defines new conformance type"
      }, null, 2);

      example += '\n\n3. SELF-REFERENTIAL conformance (hologram.newconformance.newconformance.json):\n';
      example += JSON.stringify({
        "namespace": "hologram.newconformance.newconformance",
        "parent": "hologram.newconformance",
        "conformance": true,
        "newconformance": {
          "version": "0.1.0",
          "description": "Conformance for the conformance spec itself!"
        }
      }, null, 2);
      break;

    default:
      example += 'COMPLETE WORKING EXAMPLE: hologram.example\n\n';
      example += 'This is a complete, valid component you can use as a template:\n\n';

      example += '1. SPEC FILE (hologram.example.spec.json):\n';
      example += '// Note: This IS the component itself when conformance=false\n';
      example += JSON.stringify({
        "$schema": "http://json-schema.org/draft-07/schema#",
        "$id": "hologram.example.spec.json",
        "namespace": "hologram.example",
        "parent": "hologram",
        "conformance": false,
        "version": "0.1.0",
        "description": "Example component - this spec file IS the component",
        "type": "object",
        "properties": {
          "config": {
            "type": "object",
            "properties": {
              "enabled": { "type": "boolean" },
              "settings": { "type": "object" }
            }
          }
        }
      }, null, 2);

      example += '\n\n2. INTERFACE (hologram.example.interface.json):\n';
      example += JSON.stringify({
        "namespace": "hologram.example.interface",
        "parent": "hologram.example",
        "conformance": true,
        "interface": {
          "version": "0.1.0",
          "description": "Public interface for example component",
          "methods": {
            "initialize": {
              "description": "Initialize the example component",
              "input": { "type": "object" },
              "output": { "type": "boolean" }
            },
            "execute": {
              "description": "Execute example operation",
              "input": { "type": "object" },
              "output": { "type": "object" }
            }
          }
        }
      }, null, 2);

      example += '\n\n3. DOCS (hologram.example.docs.json):\n';
      example += JSON.stringify({
        "namespace": "hologram.example.docs",
        "parent": "hologram.example",
        "conformance": true,
        "docs": {
          "version": "0.1.0",
          "description": "Documentation for example component",
          "sections": [
            {
              "title": "Overview",
              "content": "This example component demonstrates the structure of a Hologram component."
            },
            {
              "title": "Usage",
              "content": "Use this as a template for creating new components."
            }
          ]
        }
      }, null, 2);

      example += '\n\n4. TEST (hologram.example.test.json):\n';
      example += JSON.stringify({
        "namespace": "hologram.example.test",
        "parent": "hologram.example",
        "conformance": true,
        "test": {
          "version": "0.1.0",
          "description": "Tests for example component",
          "tests": [
            {
              "name": "initialization",
              "description": "Test component initialization",
              "type": "unit"
            },
            {
              "name": "execution",
              "description": "Test component execution",
              "type": "integration"
            }
          ]
        }
      }, null, 2);

      example += '\n\n5. MANAGER (hologram.example.manager.json):\n';
      example += JSON.stringify({
        "namespace": "hologram.example.manager",
        "parent": "hologram.example",
        "conformance": true,
        "manager": {
          "version": "0.1.0",
          "description": "Lifecycle management for example component",
          "operations": {
            "create": { "supported": true },
            "read": { "supported": true },
            "update": { "supported": true },
            "delete": { "supported": true },
            "validate": { "supported": true }
          }
        }
      }, null, 2);

      example += '\n\nWORKFLOW TO CREATE THIS COMPONENT:\n';
      example += '1. Call submitArtifact() with each JSON above\n';
      example += '2. Collect the CID from each response\n';
      example += '3. Call submitManifest() with:\n';
      example += JSON.stringify({
        "namespace": "hologram.example",
        "artifacts": {
          "spec": "cid:...",
          "interface": "cid:...",
          "docs": "cid:...",
          "test": "cid:...",
          "manager": "cid:...",
          "dependency": "cid:...",
          "build": "cid:...",
          "log": "cid:...",
          "view": "cid:..."
        }
      }, null, 2);
      break;
  }

  return {
    content: [{
      type: 'text',
      text: example
    }]
  };
}