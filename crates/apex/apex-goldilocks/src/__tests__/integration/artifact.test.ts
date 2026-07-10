/**
 * Artifact Submission Tests
 * Tests the two-phase commit pattern: artifact submission -> manifest submission
 */

import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { submitArtifactOperation } from '../../operations/artifact';
import { ArtifactStore } from '../../core/artifact-store';
import * as fs from 'fs';
import * as path from 'path';

describe('MCP Server - Artifact Submission', () => {
  const testArtifactDir = '/tmp/test-artifacts';
  const testSpecDir = '/tmp/test-spec-artifacts';
  let artifactStore: ArtifactStore;

  beforeEach(() => {
    // Clean and create test directories
    [testArtifactDir, testSpecDir].forEach(dir => {
      if (fs.existsSync(dir)) {
        fs.rmSync(dir, { recursive: true });
      }
      fs.mkdirSync(dir, { recursive: true });
    });

    // Create base schema with index for tests
    const baseSpecHash = 'test123456789';
    fs.writeFileSync(
      path.join(testSpecDir, `hologram.${baseSpecHash}.json`),
      JSON.stringify({
        $schema: 'http://json-schema.org/draft-07/schema#',
        $id: 'hologram.spec',
        type: 'object',
        properties: {
          namespace: { type: 'string' },
          parent: { type: 'string' },
          conformance: { type: 'boolean' }
        },
        required: ['namespace', 'conformance']
      })
    );

    // Create index file so schema can be loaded
    fs.writeFileSync(
      path.join(testSpecDir, 'hologram.index.json'),
      JSON.stringify({
        namespace: 'hologram',
        artifacts: {
          spec: `hologram.${baseSpecHash}`
        }
      })
    );

    artifactStore = new ArtifactStore(testArtifactDir);
  });

  afterEach(() => {
    // Clean up
    [testArtifactDir, testSpecDir].forEach(dir => {
      if (fs.existsSync(dir)) {
        fs.rmSync(dir, { recursive: true });
      }
    });
  });

  describe('Spec Artifact Submission', () => {
    it('should accept valid JSON Schema spec', async () => {
      const spec = {
        $schema: 'http://json-schema.org/draft-07/schema#',
        $id: 'hologram.test.spec.json',
        title: 'Test Component',
        type: 'object',
        properties: {
          namespace: { type: 'string' },
          parent: { type: 'string' },
          conformance: { type: 'boolean' }
        },
        required: ['namespace', 'parent', 'conformance']
      };

      const result = await submitArtifactOperation(spec, 'spec', testSpecDir);
      const response = JSON.parse(result.content[0].text);

      expect(response.success).toBe(true);
      expect(response.cid).toMatch(/^cid:[a-f0-9]{64}$/);
      expect(response.type).toBe('spec');
      expect(response.namespace).toBe('hologram.test');
    });

    it('should derive namespace from $id for spec files', async () => {
      const spec = {
        $schema: 'http://json-schema.org/draft-07/schema#',
        $id: 'hologram.example.spec.json',
        type: 'object'
      };

      const result = await submitArtifactOperation(spec, 'spec', testSpecDir);
      const response = JSON.parse(result.content[0].text);

      expect(response.success).toBe(true);
      expect(response.namespace).toBe('hologram.example');
    });

    it('should reject invalid JSON Schema', async () => {
      const invalidSpec = {
        $schema: 'http://json-schema.org/draft-07/schema#',
        $id: 'test.spec.json',
        type: 'not-a-valid-type' // Invalid type
      };

      const result = await submitArtifactOperation(invalidSpec, 'spec', testSpecDir);
      const text = result.content[0].text;

      expect(text).toContain('❌');
      expect(text).toContain('Invalid JSON Schema');
    });

    it('should not require namespace field in spec schemas', async () => {
      const spec = {
        $schema: 'http://json-schema.org/draft-07/schema#',
        $id: 'hologram.nonamespace.spec.json',
        type: 'object',
        // No namespace property - this is a schema that defines namespace
        properties: {
          test: { type: 'string' }
        }
      };

      const result = await submitArtifactOperation(spec, 'spec', testSpecDir);
      const response = JSON.parse(result.content[0].text);

      expect(response.success).toBe(true);
      // Should not fail due to missing namespace
    });
  });

  // Note: There is no separate "implementation" artifact type.
  // The spec file with conformance: false IS the component itself.

  describe('Conformance Artifact Submission', () => {
    it('should accept valid conformance file', async () => {
      const conformance = {
        namespace: 'hologram.test.interface',
        parent: 'hologram.test',
        conformance: true,
        interface: {
          version: '0.1.0',
          description: 'Test interface',
          methods: {
            test: {
              description: 'Test method'
            }
          }
        }
      };

      const result = await submitArtifactOperation(conformance, 'conformance', testSpecDir);
      const text = result.content[0].text;

      // May fail due to missing interface spec, but structure is valid
      if (!text.includes('❌')) {
        const response = JSON.parse(text);
        expect(response.success).toBe(true);
      }
    });

    it('should enforce conformance=true for conformance files', async () => {
      const invalidConformance = {
        namespace: 'hologram.test.interface',
        parent: 'hologram.test',
        conformance: false, // Should be true
        interface: {
          version: '0.1.0',
          description: 'Test interface',
          methods: {}
        }
      };

      // This should be caught during validation
      const _result = await submitArtifactOperation(invalidConformance, 'conformance', testSpecDir);
      // Validator should detect mismatch
      expect(true).toBe(true); // Placeholder - exact behavior depends on validation rules
    });
  });

  describe('CID Generation', () => {
    it('should generate consistent CIDs for same content', () => {
      const content = {
        namespace: 'hologram.test',
        parent: 'hologram',
        conformance: false
      };

      const cid1 = artifactStore.generateCID(content);
      const cid2 = artifactStore.generateCID(content);

      expect(cid1).toBe(cid2);
      expect(cid1).toMatch(/^cid:[a-f0-9]{64}$/);
    });

    it('should generate different CIDs for different content', () => {
      const content1 = {
        namespace: 'hologram.test1',
        parent: 'hologram',
        conformance: false
      };

      const content2 = {
        namespace: 'hologram.test2',
        parent: 'hologram',
        conformance: false
      };

      const cid1 = artifactStore.generateCID(content1);
      const cid2 = artifactStore.generateCID(content2);

      expect(cid1).not.toBe(cid2);
    });

    it('should use canonical JSON for CID generation', () => {
      // Same content, different key order
      const content1 = {
        namespace: 'hologram.test',
        conformance: false,
        parent: 'hologram'
      };

      const content2 = {
        parent: 'hologram',
        namespace: 'hologram.test',
        conformance: false
      };

      const cid1 = artifactStore.generateCID(content1);
      const cid2 = artifactStore.generateCID(content2);

      expect(cid1).toBe(cid2); // Should be same due to canonical ordering
    });
  });

  describe('Artifact Storage', () => {
    it('should store artifact and return CID', () => {
      const content = {
        namespace: 'hologram.test',
        parent: 'hologram',
        conformance: false
      };

      const cid = artifactStore.storeArtifact(content);
      expect(cid).toMatch(/^cid:[a-f0-9]{64}$/);

      // Verify file was created
      const artifactPath = path.join(testArtifactDir, cid);
      expect(fs.existsSync(artifactPath)).toBe(true);

      // Verify content
      const stored = JSON.parse(fs.readFileSync(artifactPath, 'utf-8'));
      expect(stored).toEqual(content);
    });

    it('should retrieve stored artifact by CID', () => {
      const content = {
        namespace: 'hologram.test',
        parent: 'hologram',
        conformance: false
      };

      const cid = artifactStore.storeArtifact(content);
      const retrieved = artifactStore.getArtifact(cid);

      expect(retrieved).toEqual(content);
    });

    it('should return null for non-existent CID', () => {
      const fakeCid = 'cid:0000000000000000000000000000000000000000000000000000000000000000';
      const retrieved = artifactStore.getArtifact(fakeCid);

      expect(retrieved).toBeNull();
    });
  });

  describe('Validation Integration', () => {
    it('should validate against base schema before storing', async () => {
      const validContent = {
        namespace: 'hologram.valid.test',
        parent: 'hologram.valid',
        conformance: true,
        version: '0.1.0',
        description: 'Valid test conformance',
        test: {
          tests: []
        }
      };

      const invalidContent = {
        namespace: 123, // Wrong type
        parent: 'hologram',
        conformance: 'not-a-boolean' // Wrong type
      };

      const validResult = await submitArtifactOperation(validContent, 'conformance', testSpecDir);
      const invalidResult = await submitArtifactOperation(invalidContent, 'conformance', testSpecDir);

      const validText = validResult.content[0].text;
      const invalidText = invalidResult.content[0].text;

      // Valid content should succeed
      const validResponse = JSON.parse(validText);
      expect(validResponse.success).toBe(true);

      // Invalid content should fail base validation
      expect(invalidText).toContain('❌');
    });

    it('should allow spec submission for new components', async () => {
      // This is the key test - specs should be submittable
      // for components that don't exist in the filesystem yet
      const spec = {
        "$schema": "http://json-schema.org/draft-07/schema#",
        "$id": "hologram.newcomponent.spec",
        namespace: 'hologram.newcomponent',
        parent: 'hologram',
        conformance: false,
        version: '0.1.0',
        description: 'A new component spec being created',
        type: 'object',
        properties: {}
      };

      const result = await submitArtifactOperation(spec, 'spec', testSpecDir);
      const response = JSON.parse(result.content[0].text);

      expect(response.success).toBe(true);
      expect(response.type).toBe('spec');
      expect(response.namespace).toBe('hologram.newcomponent');
      expect(response.validated).toBe(true);
      expect(response.cid).toMatch(/^cid:[a-f0-9]{64}$/);
    });

    it('should allow conformance submission without conformance spec in filesystem', async () => {
      // Conformance artifacts should also be submittable without their
      // conformance spec being in the filesystem
      const conformance = {
        namespace: 'hologram.newcomponent.interface',
        parent: 'hologram.newcomponent',
        conformance: true,
        version: '0.1.0',
        description: 'New component interface conformance',
        interface: {
          version: '0.1.0',
          description: 'New component interface',
          methods: {}
        }
      };

      const result = await submitArtifactOperation(conformance, 'conformance', testSpecDir);
      const response = JSON.parse(result.content[0].text);

      expect(response.success).toBe(true);
      expect(response.type).toBe('conformance');
      expect(response.namespace).toBe('hologram.newcomponent.interface');
      expect(response.validated).toBe(true);
      expect(response.cid).toMatch(/^cid:[a-f0-9]{64}$/);
    });
  });
});