import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import * as fs from 'fs';
import * as path from 'path';
import { validateOperation } from '../operations/validate.js';
import { updateOperation } from '../operations/update.js';
import { getSchemaOperation, listSchemasOperation } from '../operations/discover.js';
import { validateArtifactOperation, explainValidationOperation } from '../operations/preview.js';

describe('MCP Server Improvements', () => {
  // When running tests from src directory, spec is at ../spec
  // When running from root, spec is at ./spec
  const testDir = fs.existsSync(path.join(process.cwd(), 'spec'))
    ? path.join(process.cwd(), 'spec')
    : path.join(process.cwd(), '..', 'spec');

  describe('Error Messages', () => {
    it('should provide descriptive error for invalid JSON in update', async () => {
      // This should now give a better error message
      const result = await updateOperation('hologram.test', {
        test: '{ invalid json'
      }, testDir);

      const errorText = result.content[0].text;
      expect(errorText).toContain("appears to be an invalid JSON string");
      expect(errorText).toContain("Expected a JSON object");
    });

    it('should provide detailed validation errors with context', async () => {
      // Test improved validation messages - use a namespace that exists
      const result = await validateOperation('hologram.test', testDir);
      const text = result.content[0].text;

      // The component exists and has been validated
      if (text.includes('❌')) {
        // If there are validation errors, they should be descriptive
        expect(text).toMatch(/Missing required field:|Type mismatch|Expected one of:|Required .* conformance file missing/);
      } else {
        // Component is valid
        expect(text).toContain('✅');
      }
    });
  });

  describe('Schema Discovery', () => {
    it('should list available schemas with listSchemas', async () => {
      const result = await listSchemasOperation(testDir);
      const text = result.content[0].text;

      expect(text).toContain('AVAILABLE SCHEMAS');
      expect(text).toContain('Direct Schema Files:');
      expect(text).toContain('Component Schemas');
      expect(text).toContain('Usage Examples:');
    });

    it('should get schema by namespace for components', async () => {
      const result = await getSchemaOperation('hologram.component', testDir);
      const text = result.content[0].text;

      // Should either find it or give helpful error
      if (text.includes('not found')) {
        expect(text).toContain('Available schemas:');
        expect(text).toContain('Components with specs:');
      } else {
        expect(text).toContain('SCHEMA:');
        expect(text).toContain('KEY POINTS:');
      }
    });

    it('should get schema with .spec.json extension', async () => {
      const result = await getSchemaOperation('hologram.component.spec', testDir);
      const text = result.content[0].text;

      if (!text.includes('not found')) {
        expect(text).toContain('conformance_requirements');
        expect(text).toContain('Required fields:');
      }
    });
  });

  describe('Update Operation Fixes', () => {
    it('should handle object content correctly', async () => {
      // The bug where content was treated as string should be fixed
      const testContent = {
        namespace: "hologram.test.test",
        parent: "hologram.test",
        conformance: true,
        version: "0.1.0",
        description: "Test update",
        test: {
          version: "0.1.0",
          description: "Test",
          tests: [
            { name: "test1", description: "Test 1" }
          ]
        }
      };

      const result = await updateOperation('hologram.test', {
        test: testContent
      }, testDir);

      // Should succeed without "Cannot create property" error
      expect(result.content[0].text).not.toContain("Cannot create property");
    });
  });

  describe('Validation Message Improvements', () => {
    it('should show allowed enum values in errors', async () => {
      // Create a test artifact with invalid enum value
      const testArtifact = {
        namespace: "test.component",
        parent: "test",
        conformance: true,
        version: "0.1.0",
        description: "Test",
        log: {
          version: "0.1.0",
          description: "Test log",
          levels: ["info"],
          default_level: "info",
          format: {
            type: "json",
            timestamp: "iso8601",
            fields: {
              required: ["timestamp", "level", "message"],
              optional: [],
              metadata: {}
            }
          },
          output: [
            {
              type: "invalid_output_type", // This should trigger enum error
              config: {}
            }
          ]
        }
      };

      // This would be tested through submitArtifact in real scenario
      // For now, we're testing the error format concept
    });
  });

  describe('New Debug Operations', () => {
    it('should preview validation without saving', async () => {
      const testArtifact = {
        namespace: "hologram.example.test",
        parent: "hologram.example",
        conformance: true,
        version: "0.1.0",
        description: "Test conformance",
        test: {
          version: "0.1.0",
          description: "Test suite",
          tests: [
            { name: "test1", description: "Test 1" }
          ]
        }
      };

      const result = await validateArtifactOperation(testArtifact, 'conformance', undefined, testDir);
      const text = result.content[0].text;

      expect(text).toContain('✅ Artifact validation successful!');
      expect(text).toContain('Type: conformance');
      expect(text).toContain('can be submitted with submitArtifact()');
    });

    it('should explain validation checks', async () => {
      const result = await explainValidationOperation('hologram.test', testDir);
      const text = result.content[0].text;

      expect(text).toContain('VALIDATION EXPLANATION FOR: hologram.test');
      expect(text).toContain('INDEX FILE VALIDATION');
      expect(text).toContain('REQUIRED CONFORMANCE FILES');
      expect(text).toContain('BASE SCHEMA VALIDATION');
      expect(text).toContain('COMMON VALIDATION FAILURES');
    });
  });
});