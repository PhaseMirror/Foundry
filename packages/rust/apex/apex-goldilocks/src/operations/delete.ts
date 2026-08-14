import * as fs from 'fs';
import * as path from 'path';
import { ComponentIndex } from '../types.js';

export async function deleteOperation(
  namespace: string,
  specDir: string = path.join(process.cwd(), 'spec')
): Promise<{ content: Array<{ type: string; text: string }> }> {

  try {
    // Check if component index exists
    const indexPath = path.join(specDir, `${namespace}.index.json`);
    if (!fs.existsSync(indexPath)) {
      return {
        content: [
          {
            type: 'text',
            text: `❌ Component ${namespace} not found`,
          },
        ],
      };
    }

    // Load index to get all component files
    let index: ComponentIndex;
    try {
      index = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
    } catch (e) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to read component index: ${e instanceof Error ? e.message : 'Unknown error'}`,
          },
        ],
      };
    }

    // Check for dependencies
    const dependencies = await checkDependencies(namespace, specDir);
    if (dependencies.length > 0) {
      return {
        content: [
          {
            type: 'text',
            text: `Cannot delete ${namespace}: Used by components:\n${dependencies.map(d => `  - ${d}`).join('\n')}`,
          },
        ],
      };
    }

    // Collect all files to delete from index
    const filesToDelete: string[] = [indexPath];
    for (const artifactRef of Object.values(index.artifacts)) {
      if (artifactRef) {
        // Add .json extension to artifact reference to get actual filename
        const filename = `${artifactRef}.json`;
        filesToDelete.push(path.join(specDir, filename));
      }
    }

    // Delete all component files
    const deletedFiles: string[] = [];
    for (const filePath of filesToDelete) {
      const file = path.basename(filePath);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        deletedFiles.push(file);
      }
    }

    return {
      content: [
        {
          type: 'text',
          text: `✅ Successfully deleted component ${namespace}:\n${deletedFiles.map(f => `  - Deleted ${f}`).join('\n')}`,
        },
      ],
    };
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Delete error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        },
      ],
    };
  }
}

async function checkDependencies(namespace: string, specDir: string): Promise<string[]> {
  const dependencies: string[] = [];

  // Read all index files to find dependencies
  const files = fs.readdirSync(specDir).filter(f => f.endsWith('.index.json'));

  for (const indexFile of files) {
    const componentNamespace = indexFile.replace('.index.json', '');

    // Skip the component being deleted
    if (componentNamespace === namespace) {
      continue;
    }

    try {
      const index: ComponentIndex = JSON.parse(fs.readFileSync(path.join(specDir, indexFile), 'utf-8'));

      // Check each file in this component's index
      for (const artifactRef of Object.values(index.artifacts)) {
        if (!artifactRef) continue;

        // Add .json extension to artifact reference to get actual filename
        const filename = `${artifactRef}.json`;
        const filePath = path.join(specDir, filename);
        if (!fs.existsSync(filePath)) continue;

        const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

        // Check if this component depends on the one being deleted
        if (content.parent === namespace) {
          if (!dependencies.includes(componentNamespace)) {
            dependencies.push(componentNamespace);
          }
        }

        // Check for references in schemas
        if (content.$ref && content.$ref.includes(namespace)) {
          if (!dependencies.includes(componentNamespace)) {
            dependencies.push(componentNamespace);
          }
        }

        // Check conformance requirements
        if (content.component?.conformance_requirements) {
          for (const req of Object.values(content.component.conformance_requirements)) {
            if (req && typeof req === 'object' && 'schema' in req && (req as any).schema.includes(namespace)) {
              if (!dependencies.includes(componentNamespace)) {
                dependencies.push(componentNamespace);
              }
            }
          }
        }
      }
    } catch (error) {
      // Skip files that can't be parsed
      continue;
    }
  }

  return dependencies;
}