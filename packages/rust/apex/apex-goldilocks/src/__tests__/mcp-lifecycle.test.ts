import { describe, test, expect, beforeAll, afterAll } from '@jest/globals';
import * as fs from 'fs';
import * as path from 'path';
import { submitArtifactOperation } from '../operations/artifact.js';
import { submitManifestOperation } from '../operations/manifest.js';
import { validateOperation } from '../operations/validate.js';
import { readOperation } from '../operations/read.js';
import { updateOperation } from '../operations/update.js';
import { deleteOperation } from '../operations/delete.js';

const testSpecDir = '/tmp/test-mcp-lifecycle';

describe('MCP Server - Full Component Lifecycle', () => {
  beforeAll(() => {
    // Create test directory
    if (!fs.existsSync(testSpecDir)) {
      fs.mkdirSync(testSpecDir, { recursive: true });
    }

    // Copy essential spec files from the real spec directory
    const realSpecDir = path.join(process.cwd(), '..', 'spec');
    if (fs.existsSync(realSpecDir)) {
      const essentialFiles = fs.readdirSync(realSpecDir).filter(f =>
        f.startsWith('hologram.') && (f.endsWith('.json') || f.endsWith('.index.json'))
      );

      for (const file of essentialFiles) {
        const sourcePath = path.join(realSpecDir, file);
        const destPath = path.join(testSpecDir, file);
        fs.copyFileSync(sourcePath, destPath);
      }
    }

  });

  afterAll(() => {
    // Clean up test directory
    if (fs.existsSync(testSpecDir)) {
      fs.rmSync(testSpecDir, { recursive: true, force: true });
    }
  });

  test('Complete component lifecycle: Create → Read → Update → Validate → Delete', async () => {
    const namespace = 'hologram.lifecycle';
    const artifacts: Record<string, string> = {};

    // Phase 1: Submit all artifacts
    console.log('Phase 1: Submitting artifacts...');

    // Submit spec artifact
    const specContent = {
      "$schema": "http://json-schema.org/draft-07/schema#",
      "$id": `${namespace}.spec.json`,
      "namespace": namespace,
      "parent": "hologram",
      "conformance": false,
      "version": "0.1.0",
      "description": "Test lifecycle component",
      "type": "object",
      "properties": {
        "enabled": { "type": "boolean", "default": true }
      }
    };

    const specResult = await submitArtifactOperation(specContent, 'spec', testSpecDir);
    expect(specResult.content[0].text).toContain('success');
    const specResponse = JSON.parse(specResult.content[0].text);
    expect(specResponse.success).toBe(true);
    artifacts.spec = specResponse.cid;

    // Submit conformance artifacts
    const conformanceTypes = ['interface', 'docs', 'test', 'manager', 'dependency', 'build', 'log', 'view'];

    for (const type of conformanceTypes) {
      const conformanceContent: any = {
        namespace: `${namespace}.${type}`,
        parent: namespace,
        conformance: true,
        version: "0.1.0",
        description: `${type} conformance for lifecycle test`
      };

      // Add type-specific content
      if (type === 'interface') {
        conformanceContent.interface = {
          version: "0.1.0",
          description: "Interface for lifecycle test",
          methods: {
            "start": { "description": "Start", "input": {}, "output": { "type": "boolean" } }
          }
        };
      } else if (type === 'docs') {
        conformanceContent.docs = {
          version: "0.1.0",
          description: "Documentation",
          sections: [{ "title": "Overview", "content": "Test component" }]
        };
      } else if (type === 'test') {
        conformanceContent.test = {
          version: "0.1.0",
          description: "Tests",
          tests: [{ "name": "test1", "description": "Test 1", "type": "unit" }]
        };
      } else if (type === 'manager') {
        conformanceContent.manages = namespace;
        conformanceContent.operations = {
          validate: { description: "Validate" },
          create: {
            description: "Create",
            artifact_submission: { description: "Submit artifacts" },
            manifest_submission: { description: "Submit manifest" }
          },
          read: { description: "Read" },
          update: { description: "Update" },
          delete: { description: "Delete" }
        };
        conformanceContent.storage = { type: "filesystem" };
        conformanceContent.atlas = { canonical: true, deterministic: true, verifiable: true };
        conformanceContent.manager = {
          version: "0.1.0",
          description: "Manager operations",
          operations: {
            create: { description: "Create" },
            read: { description: "Read" },
            update: { description: "Update" },
            delete: { description: "Delete" },
            validate: { description: "Validate" }
          }
        };
      } else if (type === 'dependency') {
        conformanceContent.dependency = {
          required: [{ namespace: "hologram", version: ">=0.1.0", type: "conformance", reason: "Base" }],
          optional: [], development: [], conflicts: []
        };
        conformanceContent.dependencies = {
          required: [{ namespace: "hologram", version: ">=0.1.0", type: "conformance", reason: "Base" }],
          optional: [], development: [], conflicts: []
        };
      } else if (type === 'build') {
        conformanceContent.build = {
          type: "script",
          steps: [{ name: "build", command: "echo build" }],
          artifacts: { schemas: [], binaries: [], libraries: [], documentation: [] },
          requirements: { tools: [] }
        };
      } else if (type === 'log') {
        conformanceContent.log = {
          version: "0.1.0",
          description: "Logging",
          levels: ["info", "error"],
          default_level: "info",
          format: {
            type: "json",
            timestamp: "iso8601",
            fields: { required: ["timestamp", "level", "message"], optional: [] }
          },
          output: [{ type: "stdout", config: { level: "info" } }]
        };
      } else if (type === 'view') {
        conformanceContent.view = {
          version: "0.1.0",
          description: "View",
          type: "dashboard",
          layout: {
            sections: [{ name: "status", type: "indicator", properties: { label: "Status" } }]
          }
        };
      }

      const conformanceResult = await submitArtifactOperation(conformanceContent, 'conformance', testSpecDir);
      expect(conformanceResult.content[0].text).toContain('success');
      const conformanceResponse = JSON.parse(conformanceResult.content[0].text);
      expect(conformanceResponse.success).toBe(true);
      artifacts[type] = conformanceResponse.cid;
    }

    // Phase 2: Create component with manifest
    console.log('Phase 2: Creating component from manifest...');
    const manifestResult = await submitManifestOperation(namespace, artifacts, testSpecDir);
    expect(manifestResult.content[0].text).toContain('✅');
    expect(manifestResult.content[0].text).toContain('Successfully created component');

    // Phase 3: Read component
    console.log('Phase 3: Reading component...');
    const readResult = await readOperation(namespace, undefined, testSpecDir);
    expect(readResult.content[0].text).toContain(namespace);
    const readResponse = JSON.parse(readResult.content[0].text);
    expect(readResponse.spec.namespace).toBe(namespace);

    // Phase 4: Validate component
    console.log('Phase 4: Validating component...');
    const validateResult = await validateOperation(namespace, testSpecDir);
    expect(validateResult.content[0].text).toContain('✅');
    expect(validateResult.content[0].text).toContain('valid');

    // Phase 5: Update component
    console.log('Phase 5: Updating component...');
    const updatedSpec = {
      ...specContent,
      description: "Updated test lifecycle component",
      properties: {
        ...specContent.properties,
        timeout: { type: "number", minimum: 0 }
      }
    };
    const updateResult = await updateOperation(namespace, { spec: updatedSpec }, testSpecDir);
    expect(updateResult.content[0].text).toContain('✅');
    expect(updateResult.content[0].text).toContain('Successfully updated');

    // Phase 6: Validate after update
    console.log('Phase 6: Validating after update...');
    const validateAfterUpdate = await validateOperation(namespace, testSpecDir);
    expect(validateAfterUpdate.content[0].text).toContain('✅');

    // Phase 7: Delete component
    console.log('Phase 7: Deleting component...');
    const deleteResult = await deleteOperation(namespace, testSpecDir);
    expect(deleteResult.content[0].text).toContain('✅');
    expect(deleteResult.content[0].text).toContain('Successfully deleted');

    // Phase 8: Verify deletion
    console.log('Phase 8: Verifying deletion...');
    const readAfterDelete = await readOperation(namespace, undefined, testSpecDir);
    expect(readAfterDelete.content[0].text).toContain('not found');
  });

  test('Validation catches missing conformance files', async () => {
    const namespace = 'hologram.incomplete';

    // Submit only spec and partial conformance
    const specContent = {
      "$schema": "http://json-schema.org/draft-07/schema#",
      "$id": `${namespace}.spec.json`,
      "namespace": namespace,
      "parent": "hologram",
      "conformance": false,
      "version": "0.1.0",
      "description": "Incomplete component"
    };

    const specResult = await submitArtifactOperation(specContent, 'spec', testSpecDir);
    const specResponse = JSON.parse(specResult.content[0].text);

    // Try to create component with only spec
    const manifestResult = await submitManifestOperation(namespace, { spec: specResponse.cid }, testSpecDir);
    expect(manifestResult.content[0].text).toContain('❌');
    expect(manifestResult.content[0].text).toContain('Missing');
  });
});