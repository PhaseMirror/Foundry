import { describe, test, expect, beforeEach, afterEach } from '@jest/globals';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import { submitArtifactOperation } from '../operations/artifact.js';
import { submitManifestOperation } from '../operations/manifest.js';
import { validateOperation } from '../operations/validate.js';
import { deleteOperation } from '../operations/delete.js';
import { ComponentIndex } from '../types.js';

const testSpecDir = '/tmp/test-hologram-spec';

describe('Index-based Component Operations', () => {
  beforeEach(() => {
    // Create test directory
    if (!fs.existsSync(testSpecDir)) {
      fs.mkdirSync(testSpecDir, { recursive: true });
    }
    // Clear any existing files
    const files = fs.readdirSync(testSpecDir);
    for (const file of files) {
      fs.unlinkSync(path.join(testSpecDir, file));
    }

    // Set up component model with index structure
    const componentModel = {
      namespace: 'hologram.component',
      conformance: false,
      parent: 'hologram',
      version: '0.1.0',
      description: 'Component model',
      conformance_requirements: {
        test: { required: false },
        docs: { required: false },
        interface: { required: false },
        manager: { required: false }
      }
    };

    const modelContent = JSON.stringify(componentModel, null, 2);
    const modelHash = crypto.createHash('sha256').update(modelContent).digest('hex');
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

    // Create hologram index and spec for base validation (using new structure)
    const baseSchema = {
      $schema: 'http://json-schema.org/draft-07/schema#',
      $id: 'hologram.spec',
      type: 'object',
      properties: {
        namespace: { type: 'string' },
        conformance: { type: 'boolean' },
        parent: { type: 'string' },
        version: { type: 'string' },
        description: { type: 'string' },
        value: { type: 'number' },  // Allow test-specific properties
      },
      required: ['namespace', 'conformance'],
    };

    const baseSchemaContent = JSON.stringify(baseSchema, null, 2);
    const baseSchemaHash = crypto.createHash('sha256').update(baseSchemaContent).digest('hex');
    const baseSchemaFile = `hologram.${baseSchemaHash}.json`;

    fs.writeFileSync(
      path.join(testSpecDir, baseSchemaFile),
      baseSchemaContent
    );

    // Create hologram index
    const hologramIndex: ComponentIndex = {
      namespace: 'hologram',
      artifacts: {
        spec: baseSchemaFile.replace('.json', ''),
      },
    };
    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.index.json'),
      JSON.stringify(hologramIndex, null, 2)
    );

    // Create hologram.test.spec for conformance validation
    const testSchema = {
      $schema: 'http://json-schema.org/draft-07/schema#',
      $id: 'hologram.test.spec',
      type: 'object',
      properties: {
        namespace: { type: 'string' },
        parent: { type: 'string' },
        conformance: { type: 'boolean' },
        version: { type: 'string' },
        description: { type: 'string' },
        test: {
          type: 'object',
          properties: {
            version: { type: 'string' },
            description: { type: 'string' },
            tests: { type: 'array' }
          },
          required: ['version', 'description', 'tests']
        }
      },
      required: ['namespace', 'parent', 'conformance', 'test']
    };

    const testSchemaContent = JSON.stringify(testSchema, null, 2);
    const testSchemaHash = crypto.createHash('sha256').update(testSchemaContent).digest('hex');
    const testSchemaFile = `hologram.test.${testSchemaHash}`;

    fs.writeFileSync(
      path.join(testSpecDir, `${testSchemaFile}.json`),
      testSchemaContent
    );

    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.test.index.json'),
      JSON.stringify({
        namespace: 'hologram.test',
        artifacts: {
          spec: testSchemaFile
        }
      }, null, 2)
    );
  });

  afterEach(() => {
    // Clean up
    if (fs.existsSync(testSpecDir)) {
      fs.rmSync(testSpecDir, { recursive: true });
    }
  });

  test('should create component with content-addressed files and index', async () => {
    // Create test component spec
    const spec = {
      $schema: 'http://json-schema.org/draft-07/schema#',
      $id: 'hologram.testcomp.spec',
      type: 'object',
      properties: {
        namespace: { type: 'string' },
        value: { type: 'number' },
      },
      required: ['namespace'],
    };

    const testConf = {
      namespace: 'hologram.testcomp.test',
      parent: 'hologram.testcomp',
      conformance: true,
      version: '0.1.0',
      description: 'Test conformance',
      test: {
        version: '0.1.0',
        description: 'Test conformance',
        tests: [],
      },
    };

    // Submit artifacts
    const specResult = await submitArtifactOperation(
      spec,
      'spec',
      testSpecDir
    );
    const specCid = JSON.parse(specResult.content[0].text).cid;

    const testResult = await submitArtifactOperation(
      testConf,
      'conformance',
      testSpecDir
    );
    const testCid = JSON.parse(testResult.content[0].text).cid;

    // Submit manifest
    const manifestResult = await submitManifestOperation(
      'hologram.testcomp',
      {
        spec: specCid,
        test: testCid,
      },
      testSpecDir
    );

    expect(manifestResult.content[0].text).toContain('Successfully created component');

    // Verify index file exists
    const indexPath = path.join(testSpecDir, 'hologram.testcomp.index.json');
    expect(fs.existsSync(indexPath)).toBe(true);

    // Verify index structure
    const index: ComponentIndex = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
    expect(index.namespace).toBe('hologram.testcomp');
    expect(index.artifacts.spec).toBeDefined();
    expect(index.artifacts.test).toBeDefined();

    // Verify content-addressed files exist
    expect(fs.existsSync(path.join(testSpecDir, `${index.artifacts.spec}.json`))).toBe(true);
    expect(fs.existsSync(path.join(testSpecDir, `${index.artifacts.test}.json`))).toBe(true);

    // Verify filenames contain SHA256 hashes
    const specHash = crypto.createHash('sha256').update(JSON.stringify(spec, null, 2)).digest('hex');
    expect(index.artifacts.spec).toBe(`hologram.testcomp.${specHash}`);
  });

  test('should validate component using index', async () => {
    // First create a component
    const spec = {
      $schema: 'http://json-schema.org/draft-07/schema#',
      $id: 'hologram.testval.spec',
      type: 'object',
      properties: {
        namespace: { type: 'string' },
      },
      required: ['namespace'],
    };

    // Create content-addressed files
    const specContent = JSON.stringify(spec, null, 2);
    const specHash = crypto.createHash('sha256').update(specContent).digest('hex');
    const specFile = `hologram.testval.${specHash}.json`;
    fs.writeFileSync(path.join(testSpecDir, specFile), specContent);

    // Create index
    const index: ComponentIndex = {
      namespace: 'hologram.testval',
      artifacts: {
        spec: specFile.replace('.json', ''),
      },
    };
    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.testval.index.json'),
      JSON.stringify(index, null, 2)
    );

    // Validate component
    const result = await validateOperation('hologram.testval', testSpecDir);
    const resultText = result.content[0].text;

    // Should validate successfully with just a spec
    expect(resultText).toContain('hologram.testval');
  });

  test('should handle multiple components with no naming conflicts', async () => {
    // Create hologram.test component
    const _testSpec = {
      $schema: 'http://json-schema.org/draft-07/schema#',
      $id: 'hologram.test.spec.json',
      type: 'object',
    };

    const testImpl = {
      namespace: 'hologram.test',
      conformance: false,
    };

    // Create hologram component with test conformance
    const _hologramSpec = {
      $schema: 'http://json-schema.org/draft-07/schema#',
      $id: 'hologram.spec.json',
      type: 'object',
    };

    const _hologramImpl = {
      namespace: 'hologram',
      conformance: false,
    };

    const hologramTestConf = {
      namespace: 'hologram.test',
      parent: 'hologram',
      conformance: true,
      test: {
        version: '0.1.0',
        description: 'Test for hologram',
        tests: [],
      },
    };

    // Create files with different hashes (they have different content)
    const testImplHash = crypto.createHash('sha256')
      .update(JSON.stringify(testImpl, null, 2))
      .digest('hex');
    const hologramTestHash = crypto.createHash('sha256')
      .update(JSON.stringify(hologramTestConf, null, 2))
      .digest('hex');

    // These would have been the same filename in old system but now are different
    const testImplFile = `hologram.test.${testImplHash}.json`;
    const hologramTestFile = `hologram.test.${hologramTestHash}.json`;

    expect(testImplFile).not.toBe(hologramTestFile); // Different hashes!

    // Write files
    fs.writeFileSync(
      path.join(testSpecDir, testImplFile),
      JSON.stringify(testImpl, null, 2)
    );
    fs.writeFileSync(
      path.join(testSpecDir, hologramTestFile),
      JSON.stringify(hologramTestConf, null, 2)
    );

    // Create indexes
    const testIndex: ComponentIndex = {
      namespace: 'hologram.test',
      artifacts: {
        spec: testImplFile.replace('.json', ''),
      },
    };

    const hologramIndex: ComponentIndex = {
      namespace: 'hologram',
      artifacts: {
        test: hologramTestFile.replace('.json', ''),
      },
    };

    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.test.index.json'),
      JSON.stringify(testIndex, null, 2)
    );
    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.index.json'),
      JSON.stringify(hologramIndex, null, 2)
    );

    // Validate - should find both components without confusion
    const result = await validateOperation(undefined, testSpecDir);
    const resultText = result.content[0].text;

    expect(resultText).toContain('hologram.test');
    expect(resultText).toContain('hologram');
  });

  test('should delete component and all associated files', async () => {
    // Create a simple component with test conformance
    const index: ComponentIndex = {
      namespace: 'hologram.testdel',
      artifacts: {
        spec: 'hologram.testdel.abc123',
        test: 'hologram.testdel.def456',
      },
    };

    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.testdel.index.json'),
      JSON.stringify(index, null, 2)
    );
    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.testdel.abc123.json'),
      JSON.stringify({ $schema: 'test' }, null, 2)
    );
    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.testdel.def456.json'),
      JSON.stringify({ namespace: 'hologram.testdel.test', conformance: true }, null, 2)
    );

    // Delete component
    const result = await deleteOperation('hologram.testdel', testSpecDir);
    expect(result.content[0].text).toContain('Successfully deleted');

    // Verify all files are gone
    expect(fs.existsSync(path.join(testSpecDir, 'hologram.testdel.index.json'))).toBe(false);
    expect(fs.existsSync(path.join(testSpecDir, 'hologram.testdel.abc123.json'))).toBe(false);
    expect(fs.existsSync(path.join(testSpecDir, 'hologram.testdel.def456.json'))).toBe(false);
  });
});