#!/usr/bin/env node
/**
 * Garbage Collection for Hologram spec/ directory
 * Identifies and optionally removes orphaned content-addressed files
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

interface GCOptions {
  specDir?: string;
  clean?: boolean;
  verbose?: boolean;
}

interface GCResult {
  totalFiles: number;
  indexFiles: number;
  contentFiles: number;
  referencedFiles: number;
  orphanedFiles: string[];
  duplicates: Map<string, string[]>;
}

export function analyzeSpec(options: GCOptions = {}): GCResult {
  const specDir = options.specDir || path.join(__dirname, '..', '..', '..', 'spec');
  const verbose = options.verbose ?? false;

  // Get all files in spec directory
  const allFiles = fs.readdirSync(specDir).filter(f => f.endsWith('.json'));

  // Separate index files and content files
  const indexFiles = allFiles.filter(f => f.endsWith('.index.json'));
  const contentFiles = allFiles.filter(f => !f.endsWith('.index.json'));

  // Collect all referenced hashes from index files
  const referencedHashes = new Set<string>();
  const componentMap = new Map<string, string>();

  for (const indexFile of indexFiles) {
    const indexPath = path.join(specDir, indexFile);
    const namespace = indexFile.replace('.index.json', '');

    try {
      const index = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
      if (index.artifacts) {
        for (const [type, artifactRef] of Object.entries(index.artifacts)) {
          if (artifactRef && typeof artifactRef === 'string') {
            // Extract hash from artifact reference
            const hash = artifactRef.split('.').pop();
            if (hash) {
              referencedHashes.add(hash);
              componentMap.set(hash, `${namespace}.${type}`);
            }
          }
        }
      }
    } catch (e) {
      if (verbose) {
        console.error(`Error reading ${indexFile}: ${e instanceof Error ? e.message : 'Unknown error'}`);
      }
    }
  }

  // Check for orphaned files
  const orphanedFiles: string[] = [];
  for (const contentFile of contentFiles) {
    // Extract hash from filename
    const hash = contentFile.replace('.json', '').split('.').pop();
    if (hash && !referencedHashes.has(hash)) {
      orphanedFiles.push(contentFile);
    }
  }

  // Check for duplicate content
  const contentHashes = new Map<string, string[]>();
  for (const contentFile of contentFiles) {
    const filePath = path.join(specDir, contentFile);
    const hash = contentFile.replace('.json', '').split('.').pop();

    if (hash && referencedHashes.has(hash)) {
      try {
        const content = fs.readFileSync(filePath, 'utf-8');
        const contentHash = crypto.createHash('sha256').update(content).digest('hex');

        if (!contentHashes.has(contentHash)) {
          contentHashes.set(contentHash, []);
        }
        contentHashes.get(contentHash)!.push(contentFile);
      } catch (e) {
        // Ignore read errors
      }
    }
  }

  // Find duplicates
  const duplicates = new Map<string, string[]>();
  for (const [hash, files] of contentHashes.entries()) {
    if (files.length > 1) {
      duplicates.set(hash, files);
    }
  }

  return {
    totalFiles: allFiles.length,
    indexFiles: indexFiles.length,
    contentFiles: contentFiles.length,
    referencedFiles: referencedHashes.size,
    orphanedFiles,
    duplicates
  };
}

export function cleanOrphans(options: GCOptions = {}): { deleted: string[]; failed: string[] } {
  const specDir = options.specDir || path.join(__dirname, '..', '..', '..', 'spec');
  const result = analyzeSpec(options);
  const deleted: string[] = [];
  const failed: string[] = [];

  for (const file of result.orphanedFiles) {
    const filePath = path.join(specDir, file);
    try {
      fs.unlinkSync(filePath);
      deleted.push(file);
    } catch (e) {
      failed.push(file);
    }
  }

  return { deleted, failed };
}

// CLI interface
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const clean = args.includes('--clean');
  const verbose = args.includes('--verbose');

  console.log('🔍 Hologram Spec Directory Garbage Collection\n');

  const result = analyzeSpec({ verbose });

  console.log(`📊 Statistics:`);
  console.log(`   Total files: ${result.totalFiles}`);
  console.log(`   Index files: ${result.indexFiles}`);
  console.log(`   Content files: ${result.contentFiles}`);
  console.log(`   Referenced files: ${result.referencedFiles}`);
  console.log(`   Orphaned files: ${result.orphanedFiles.length}\n`);

  if (result.orphanedFiles.length > 0) {
    console.log('🗑️  Orphaned files (not referenced by any index):');
    for (const file of result.orphanedFiles) {
      console.log(`   - ${file}`);
    }

    if (clean) {
      console.log('\n🧹 Cleaning orphaned files...');
      const cleanResult = cleanOrphans({ verbose });
      console.log(`✅ Deleted ${cleanResult.deleted.length} files`);
      if (cleanResult.failed.length > 0) {
        console.log(`❌ Failed to delete ${cleanResult.failed.length} files`);
      }
    } else {
      console.log('\n⚠️  To remove these orphaned files, run:');
      console.log('   make gc-clean\n');
    }
  } else {
    console.log('✅ No orphaned files found. The spec directory is clean!');
  }

  if (result.duplicates.size > 0) {
    console.log('\n⚠️  Found files with identical content:');
    for (const [hash, files] of result.duplicates.entries()) {
      console.log(`   Content hash: ${hash.substring(0, 12)}...`);
      for (const file of files) {
        console.log(`     • ${file}`);
      }
    }
  }
}