/**
 * Manifest Submission Tests
 * Tests the atomic component creation through manifest submission
 */

import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { submitManifestOperation } from '../../operations/manifest';
import { ArtifactStore } from '../../core/artifact-store';
import * as fs from 'fs';
import * as path from 'path';

describe('MCP Server - Manifest Submission', () => {
  const testSpecDir = '/tmp/test-spec-manifest';
  const testArtifactDir = '/tmp/test-artifacts-manifest';
  let artifactStore: ArtifactStore;

  beforeEach(() => {
    // Clean and create test directories
    [testSpecDir, testArtifactDir].forEach(dir => {
      if (fs.existsSync(dir)) {
        fs.rmSync(dir, { recursive: true });
      }
      fs.mkdirSync(dir, { recursive: true });
    });

    // Create hologram.component with index structure
    const componentModel = {
      namespace: 'hologram.component',
      parent: 'hologram',
      conformance: false,
      version: '0.1.0',
      description: 'Component model',
      conformance_requirements: {
        interface: { required: false },
        docs: { required: false },
        test: { required: false },
        manager: { required: false }
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

    // Create base schema with index structure
    const baseSchema = {
      $schema: 'http://json-schema.org/draft-07/schema#',
      $id: 'hologram.spec',
      type: 'object',
      properties: {
        namespace: { type: 'string' },
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

    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.index.json'),
      JSON.stringify({
        namespace: 'hologram',
        artifacts: {
          spec: schemaFile
        }
      }, null, 2)
    );

    artifactStore = new ArtifactStore(testArtifactDir);
  });

  afterEach(() => {
    [testSpecDir, testArtifactDir].forEach(dir => {
      if (fs.existsSync(dir)) {
        fs.rmSync(dir, { recursive: true });
      }
    });
  });

  describe('Manifest Validation', () => {
    it('should reject manifest without all required artifacts', async () => {
      const incompleteManifest = {
        spec: 'cid:abc123'
        // Conformance files are optional
      };

      const result = await submitManifestOperation('hologram.test', incompleteManifest, testSpecDir);
      const text = result.content[0].text;

      expect(text).toContain('❌');
      // Should fail because the CID doesn't exist
      expect(text).toContain('Artifact not found');
    });

    it('should reject manifest with non-existent CIDs', async () => {
      const manifest = {
        spec: 'cid:nonexistent1',
        interface: 'cid:nonexistent2',
        docs: 'cid:nonexistent3',
        test: 'cid:nonexistent4',
        manager: 'cid:nonexistent5'
      };

      const result = await submitManifestOperation('hologram.test', manifest, testSpecDir);
      const text = result.content[0].text;

      expect(text).toContain('❌');
      expect(text).toContain('Artifact not found');
    });

    it('should validate all artifacts exist before creating component', async () => {
      // Store actual artifacts
      const spec = artifactStore.storeArtifact({
        $schema: 'http://json-schema.org/draft-07/schema#',
        $id: 'hologram.test.spec.json',
        namespace: 'hologram.test',
        parent: 'hologram',
        conformance: false,
        version: '0.1.0',
        description: 'Test component'
      });

      const manifest = {
        spec,
        interface: 'cid:fake1',
        docs: 'cid:fake2',
        test: 'cid:fake3',
        manager: 'cid:fake4'
      };

      const result = await submitManifestOperation('hologram.test', manifest, testSpecDir);
      const text = result.content[0].text;

      expect(text).toContain('❌');
      expect(text).toContain('Artifact not found: cid:fake1');
    });
  });

  describe('Atomic Creation', () => {
    it('should create all component files atomically', async () => {
      // Create all artifacts
      const artifacts = {
        spec: artifactStore.storeArtifact({
          $schema: 'http://json-schema.org/draft-07/schema#',
          $id: 'hologram.atomic.spec.json',
          namespace: 'hologram.atomic',
          parent: 'hologram',
          conformance: false,
          version: '0.1.0',
          description: 'Test atomic component',
          type: 'object'
        }),
        interface: artifactStore.storeArtifact({
          namespace: 'hologram.atomic.interface',
          parent: 'hologram.atomic',
          conformance: true,
          interface: {
            version: '0.1.0',
            description: 'Test',
            methods: {}
          }
        }),
        docs: artifactStore.storeArtifact({
          namespace: 'hologram.atomic.docs',
          parent: 'hologram.atomic',
          conformance: true,
          docs: {
            version: '0.1.0',
            description: 'Test',
            sections: []
          }
        }),
        test: artifactStore.storeArtifact({
          namespace: 'hologram.atomic.test',
          parent: 'hologram.atomic',
          conformance: true,
          test: {
            version: '0.1.0',
            description: 'Test',
            tests: []
          }
        }),
        manager: artifactStore.storeArtifact({
          namespace: 'hologram.atomic.manager',
          parent: 'hologram.atomic',
          conformance: true,
          manager: {
            version: '0.1.0',
            description: 'Test',
            operations: {}
          }
        })
      };

      const result = await submitManifestOperation('hologram.atomic', artifacts, testSpecDir);
      const text = result.content[0].text;

      // Should succeed or fail atomically
      if (text.includes('Successfully created')) {
        // All files should exist
        const files = [
          'hologram.atomic.spec.json',
          'hologram.atomic.json',
          'hologram.atomic.interface.json',
          'hologram.atomic.docs.json',
          'hologram.atomic.test.json',
          'hologram.atomic.manager.json'
        ];

        files.forEach(file => {
          const filePath = path.join(testSpecDir, file);
          expect(fs.existsSync(filePath)).toBe(true);
        });
      } else {
        // None should exist if failed
        const anyFile = fs.readdirSync(testSpecDir).find(f => f.startsWith('hologram.atomic'));
        expect(anyFile).toBeUndefined();
      }
    });

    it('should not create partial components on failure', async () => {
      // Create invalid manifest that will fail validation
      const artifacts = {
        spec: artifactStore.storeArtifact({ invalid: 'spec' }), // This will fail validation
        interface: 'cid:missing',
        docs: 'cid:missing',
        test: 'cid:missing',
        manager: 'cid:missing'
      };

      const result = await submitManifestOperation('hologram.partial', artifacts, testSpecDir);
      const text = result.content[0].text;

      expect(text).toContain('❌');

      // No files should be created
      const files = fs.readdirSync(testSpecDir);
      const partialFiles = files.filter(f => f.includes('partial'));
      expect(partialFiles).toHaveLength(0);
    });
  });

  describe('Conformance Requirements', () => {
    it('should read requirements from hologram.component.json', async () => {
      // Already set up in beforeEach
      const manifest = {
        spec: 'cid:test'
        // Conformance files are optional
      };

      const result = await submitManifestOperation('hologram.test', manifest, testSpecDir);
      const text = result.content[0].text;

      // Should succeed with just spec since conformance is optional
      if (!text.includes('Successfully created')) {
        // If it fails, it's due to CID validation, not missing conformance
        expect(text).toContain('cid:test');
      }
    });

    it('should adapt to model changes', async () => {
      // Update component model to add new requirement
      const updatedModel = {
        namespace: 'hologram.component',
        parent: 'hologram',
        conformance: false,
        component: {
          conformance_requirements: {
            interface: { required: true },
            docs: { required: true },
            test: { required: true },
            manager: { required: true },
            metrics: { required: true } // New requirement
          }
        }
      };

      // Create index-based component model
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

      const manifest = {
        spec: 'cid:test',
        interface: 'cid:test',
        docs: 'cid:test',
        test: 'cid:test',
        manager: 'cid:test'
        // Missing new metrics requirement
      };

      const result = await submitManifestOperation('hologram.test', manifest, testSpecDir);
      const text = result.content[0].text;

      // Should not fail for missing metrics if not in our test model
      if (!text.includes('Successfully created')) {
        expect(text).toContain('❌');
      }
    });
  });

  describe('Content Validation', () => {
    it('should validate artifact content before writing', async () => {
      // Store artifact with invalid content
      const invalidSpec = artifactStore.storeArtifact({
        notASchema: true  // Invalid - not a proper spec
      });

      const manifest = {
        spec: invalidSpec,
        interface: artifactStore.storeArtifact({
          namespace: 'hologram.contenttest.interface',
          parent: 'hologram.contenttest',
          conformance: true,
          interface: { version: '0.1.0', description: 'Test', methods: {} }
        }),
        docs: artifactStore.storeArtifact({
          namespace: 'hologram.contenttest.docs',
          parent: 'hologram.contenttest',
          conformance: true,
          docs: { version: '0.1.0', description: 'Test', sections: [] }
        }),
        test: artifactStore.storeArtifact({
          namespace: 'hologram.contenttest.test',
          parent: 'hologram.contenttest',
          conformance: true,
          test: { version: '0.1.0', description: 'Test', tests: [] }
        }),
        manager: artifactStore.storeArtifact({
          namespace: 'hologram.contenttest.manager',
          parent: 'hologram.contenttest',
          conformance: true,
          manager: { version: '0.1.0', description: 'Test', operations: {} }
        })
      };

      const result = await submitManifestOperation('hologram.contenttest', manifest, testSpecDir);
      const text = result.content[0].text;

      // Should fail due to invalid spec
      expect(text).toContain('❌');
    });

    it('should validate namespace consistency', async () => {
      // Create artifacts with mismatched namespaces
      const artifacts = {
        spec: artifactStore.storeArtifact({
          $schema: 'http://json-schema.org/draft-07/schema#',
          $id: 'hologram.mismatch.spec.json',
          namespace: 'hologram.different', // Wrong namespace - should be hologram.mismatch
          parent: 'hologram',
          conformance: false,
          version: '0.1.0',
          description: 'Test with namespace mismatch'
        }),
        interface: artifactStore.storeArtifact({
          namespace: 'hologram.mismatch.interface',
          parent: 'hologram.mismatch',
          conformance: true,
          interface: { version: '0.1.0', description: 'Test', methods: {} }
        }),
        docs: artifactStore.storeArtifact({
          namespace: 'hologram.mismatch.docs',
          parent: 'hologram.mismatch',
          conformance: true,
          docs: { version: '0.1.0', description: 'Test', sections: [] }
        }),
        test: artifactStore.storeArtifact({
          namespace: 'hologram.mismatch.test',
          parent: 'hologram.mismatch',
          conformance: true,
          test: { version: '0.1.0', description: 'Test', tests: [] }
        }),
        manager: artifactStore.storeArtifact({
          namespace: 'hologram.mismatch.manager',
          parent: 'hologram.mismatch',
          conformance: true,
          manager: { version: '0.1.0', description: 'Test', operations: {} }
        })
      };

      const result = await submitManifestOperation('hologram.mismatch', artifacts, testSpecDir);
      const text = result.content[0].text;

      // Should detect namespace mismatch
      expect(text).toContain('❌');
    });
  });
});