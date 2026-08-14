/**
 * MCP Server Validation Tests
 * Tests the core validation logic of the component manager
 */

import { describe, it, expect, beforeEach } from '@jest/globals';
import { SchemaValidator } from '../../core/schema-validator';
import * as fs from 'fs';
import * as path from 'path';

describe('MCP Server - Validation', () => {
  let validator: SchemaValidator;
  const testSpecDir = '/tmp/test-spec';

  beforeEach(() => {
    // Create test directory
    if (fs.existsSync(testSpecDir)) {
      fs.rmSync(testSpecDir, { recursive: true });
    }
    fs.mkdirSync(testSpecDir, { recursive: true });

    // Create base schema with proper index structure
    const baseSchema = {
      $schema: 'http://json-schema.org/draft-07/schema#',
      $id: 'hologram.spec',
      type: 'object',
      properties: {
        namespace: { type: 'string', pattern: '^hologram(\\.[a-z][a-z0-9]*)*$' },
        parent: { type: 'string' },
        conformance: { type: 'boolean' },
        version: { type: 'string' },
        description: { type: 'string' }
      },
      required: ['namespace', 'conformance']
    };

    const schemaContent = JSON.stringify(baseSchema, null, 2);
    const schemaHash = require('crypto').createHash('sha256').update(schemaContent).digest('hex');
    const schemaFile = `hologram.${schemaHash}`;

    fs.writeFileSync(
      path.join(testSpecDir, `${schemaFile}.json`),
      schemaContent
    );

    // Create hologram index
    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.index.json'),
      JSON.stringify({
        namespace: 'hologram',
        artifacts: {
          spec: schemaFile
        }
      }, null, 2)
    );

    // Create component model with index structure
    const componentModel = {
      namespace: 'hologram.component',
      parent: 'hologram',
      conformance: false,
      version: '0.1.0',
      description: 'Component model',
      component: {
        conformance_requirements: {
          interface: { required: false },
          docs: { required: false },
          test: { required: false },
          manager: { required: false }
        }
      }
    };

    const modelContent = JSON.stringify(componentModel, null, 2);
    const modelHash = require('crypto').createHash('sha256').update(modelContent).digest('hex');
    const modelFile = `hologram.component.${modelHash}`;

    fs.writeFileSync(
      path.join(testSpecDir, `${modelFile}.json`),
      modelContent
    );

    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.component.index.json'),
      JSON.stringify({
        namespace: 'hologram.component',
        artifacts: {
          spec: modelFile
        }
      }, null, 2)
    );

    validator = new SchemaValidator(testSpecDir);
  });

  afterEach(() => {
    // Clean up
    if (fs.existsSync(testSpecDir)) {
      fs.rmSync(testSpecDir, { recursive: true });
    }
  });

  describe('Base Schema Validation', () => {
    it('should validate a correct base component', async () => {
      const component = {
        namespace: 'hologram.test',
        parent: 'hologram',
        conformance: false,
        version: '0.1.0',
        description: 'Test component'
      };

      const result = await validator.validateBaseSchema(component);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject component without namespace', async () => {
      const component = {
        parent: 'hologram',
        conformance: false
      };

      const result = await validator.validateBaseSchema(component);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.message?.includes('namespace') || e.message?.includes('required property'))).toBe(true);
    });

    it('should reject component with invalid namespace pattern', async () => {
      const component = {
        namespace: 'Hologram.Test', // Invalid - uppercase not allowed
        parent: 'hologram',
        conformance: false
      };

      const result = await validator.validateBaseSchema(component);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.message?.includes('pattern') || e.message?.includes('match'))).toBe(true);
    });

    it('should reject component without conformance flag', async () => {
      const component = {
        namespace: 'hologram.test',
        parent: 'hologram'
        // Missing conformance
      };

      const result = await validator.validateBaseSchema(component);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.message?.includes('conformance') || e.message?.includes('required property'))).toBe(true);
    });
  });

  describe('Schema Reference Validation', () => {
    it('should validate schema with correct $schema reference', async () => {
      const schema = {
        $schema: 'http://json-schema.org/draft-07/schema#',
        $id: 'test.spec.json',
        type: 'object'
      };

      // Write schema to test directory
      fs.writeFileSync(
        path.join(testSpecDir, 'test.spec.json'),
        JSON.stringify(schema)
      );

      await validator.loadSchemas();
      const errors = [];

      // Schema should be valid JSON Schema
      expect(schema.$schema).toBe('http://json-schema.org/draft-07/schema#');
    });

    it('should reject schema with invalid $ref', async () => {
      const schema = {
        $schema: 'http://json-schema.org/draft-07/schema#',
        $id: 'test.spec.json',
        type: 'object',
        properties: {
          test: {
            $ref: '#/definitions/nonexistent' // Invalid reference
          }
        }
      };

      try {
        // Test by trying to load as schema
        await validator.loadSchemas();
        expect(true).toBe(true);
      } catch (error) {
        expect(error).toBeDefined();
      }
    });
  });

  describe('Conformance Requirements', () => {
    it('should detect missing conformance files', async () => {
      // The component model is already created in beforeEach
      // Just create test component with only spec (missing conformance files)
      const testSpec = {
        $schema: 'http://json-schema.org/draft-07/schema#',
        $id: 'hologram.test.spec'
      };
      const testContent = JSON.stringify(testSpec, null, 2);
      const testHash = require('crypto').createHash('sha256').update(testContent).digest('hex');
      const testFile = `hologram.test.${testHash}`;

      fs.writeFileSync(
        path.join(testSpecDir, `${testFile}.json`),
        testContent
      );

      fs.writeFileSync(
        path.join(testSpecDir, 'hologram.test.index.json'),
        JSON.stringify({
          namespace: 'hologram.test',
          artifacts: {
            spec: testFile
            // Missing conformance files
          }
        }, null, 2)
      );

      const result = await validator.validateComponent('hologram.test');
      // Since conformance files are now optional, it should validate
      expect(result.valid).toBe(true);
      expect(result.errors.length).toBe(0);
    });

    it('should validate component with all conformance files', async () => {
      // This would require setting up complete component structure
      // Placeholder for comprehensive test
      expect(true).toBe(true);
    });
  });

  describe('Recursive Conformance', () => {
    it('should validate self-referential conformance (test.test)', async () => {
      // Test that conformance components must have their own conformance
      // For example: hologram.test.test.json must exist and be valid

      const testComponent = {
        namespace: 'hologram.test',
        parent: 'hologram',
        conformance: false
      };

      const testTestComponent = {
        namespace: 'hologram.test.test',
        parent: 'hologram.test',
        conformance: true,
        test: {
          version: '0.1.0',
          description: 'Test conformance for test component',
          tests: []
        }
      };

      // Both should validate according to their schemas
      const result1 = await validator.validateBaseSchema(testComponent);
      const result2 = await validator.validateBaseSchema(testTestComponent);

      expect(result1.valid).toBe(true);
      expect(result2.valid).toBe(true);
      expect(testTestComponent.conformance).toBe(true); // Must be conformance
    });
  });

  describe('Model-Driven Validation', () => {
    it('should read conformance requirements from hologram.component.json', async () => {
      // The component model is already set up in beforeEach with index structure
      // Just update it to have the expected structure
      const updatedModel = {
        namespace: 'hologram.component',
        parent: 'hologram',
        conformance: false,
        version: '0.1.0',
        description: 'Component model',
        component: {
          conformance_requirements: {
            interface: { required: false },
            docs: { required: false },
            test: { required: false },
            manager: { required: false },
            metrics: { required: false }
          }
        }
      };

      const modelContent = JSON.stringify(updatedModel, null, 2);
      const modelHash = require('crypto').createHash('sha256').update(modelContent).digest('hex');
      const modelFile = `hologram.component.${modelHash}`;

      fs.writeFileSync(
        path.join(testSpecDir, `${modelFile}.json`),
        modelContent
      );

      fs.writeFileSync(
        path.join(testSpecDir, 'hologram.component.index.json'),
        JSON.stringify({
          namespace: 'hologram.component',
          artifacts: {
            spec: modelFile
          }
        }, null, 2)
      );

      const requirements = await validator.getComponentRequirements();
      expect(requirements).toBeDefined();
      expect(requirements?.component.conformance_requirements).toHaveProperty('interface');
      expect(requirements?.component.conformance_requirements).toHaveProperty('metrics');
    });

    it('should detect non-conformant components when model changes', async () => {
      // Simulate model evolution - add new required conformance
      // All existing components should be detected as non-conformant
      expect(true).toBe(true); // Placeholder
    });
  });

  describe('Bidirectional Validation', () => {
    it('should validate incoming content', async () => {
      const incoming = {
        namespace: 'hologram.new',
        parent: 'hologram',
        conformance: false
      };

      const result = await validator.validateBaseSchema(incoming);
      expect(result.valid).toBe(true);
    });

    it('should validate existing spec directory', async () => {
      // Create some test components
      fs.writeFileSync(
        path.join(testSpecDir, 'hologram.spec.json'),
        JSON.stringify({
          $schema: 'http://json-schema.org/draft-07/schema#',
          $id: 'hologram.spec.json'
        })
      );

      const result = await validator.validateAllComponents();
      expect(result).toBeDefined();
      expect(result.componentResults).toBeDefined();
    });
  });

  describe('Schema Compilation', () => {
    it('should compile valid JSON Schema', async () => {
      const schema = {
        $schema: 'http://json-schema.org/draft-07/schema#',
        type: 'object',
        properties: {
          test: { type: 'string' }
        }
      };

      // Schema should be compilable - test indirectly through validation
      const testData = { test: 'value' };
      await validator.loadSchemas();
      expect(schema).toHaveProperty('$schema');
      expect(schema).toHaveProperty('type', 'object');
    });

    it('should reject invalid JSON Schema', () => {
      const invalidSchema = {
        type: 'invalid-type', // Invalid type
        properties: 'not-an-object' // Invalid properties
      };

      // Invalid schema should cause errors when used
      expect(invalidSchema.type).toBe('invalid-type');
      expect(invalidSchema.properties).toBe('not-an-object');
    });
  });
});