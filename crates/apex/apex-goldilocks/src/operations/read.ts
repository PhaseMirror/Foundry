import * as fs from 'fs';
import * as path from 'path';
import { ReadResult, ComponentFiles, ComponentIndex } from '../types.js';

export async function readOperation(
  namespace: string,
  file?: string,
  specDir: string = path.join(process.cwd(), 'spec')
): Promise<{ content: Array<{ type: string; text: string }> }> {

  try {
    // Load component index
    const indexPath = path.join(specDir, `${namespace}.index.json`);
    if (!fs.existsSync(indexPath)) {
      return {
        content: [
          {
            type: 'text',
            text: `Component ${namespace} not found (no index file)`,
          },
        ],
      };
    }

    let index: ComponentIndex;
    try {
      index = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Failed to read index: ${error instanceof Error ? error.message : 'Unknown error'}`,
          },
        ],
      };
    }

    if (file) {
      // Read specific file from index
      let fileType: string;
      if (file.endsWith('.json')) {
        // Extract type from filename
        fileType = file.replace(`${namespace}.`, '').replace('.json', '');
      } else {
        fileType = file;
      }

      const artifactRef = index.artifacts[fileType];
      if (!artifactRef) {
        return {
          content: [
            {
              type: 'text',
              text: `Artifact type '${fileType}' not found in component ${namespace}`,
            },
          ],
        };
      }

      // Add .json extension to artifact reference to get actual filename
      const filename = `${artifactRef}.json`;
      const filePath = path.join(specDir, filename);
      if (!fs.existsSync(filePath)) {
        return {
          content: [
            {
              type: 'text',
              text: `Artifact referenced in index not found: ${artifactRef}`,
            },
          ],
        };
      }

      const content = fs.readFileSync(filePath, 'utf-8');
      return {
        content: [
          {
            type: 'text',
            text: content,
          },
        ],
      };
    } else {
      // Read all component files from index
      const files: Partial<ComponentFiles> = {};

      for (const [type, artifactRef] of Object.entries(index.artifacts)) {
        if (!artifactRef) continue;

        // Add .json extension to artifact reference to get actual filename
        const filename = `${artifactRef}.json`;
        const filePath = path.join(specDir, filename);
        if (fs.existsSync(filePath)) {
          try {
            const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
            files[type] = content;
          } catch (error) {
            // Include parse errors in response
            files[type] = {
              error: `Failed to parse ${filename}: ${error instanceof Error ? error.message : 'Unknown error'}`
            };
          }
        } else {
          files[type] = {
            error: `Artifact not found: ${artifactRef}`
          };
        }
      }

      const result: ReadResult = {
        success: Object.keys(files).length > 0,
        namespace,
        files,
      };

      if (result.success) {
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(files, null, 2),
            },
          ],
        };
      } else {
        return {
          content: [
            {
              type: 'text',
              text: `No files found for component ${namespace}`,
            },
          ],
        };
      }
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Read error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        },
      ],
    };
  }
}