#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { validateOperation } from "./operations/validate.js";
import { readOperation } from "./operations/read.js";
import { updateOperation } from "./operations/update.js";
import { deleteOperation } from "./operations/delete.js";
import { submitArtifactOperation } from "./operations/artifact.js";
import { submitManifestOperation } from "./operations/manifest.js";
import {
  getComponentModelOperation,
  getSchemaOperation,
  listComponentsOperation,
  getComponentExampleOperation,
  listSchemasOperation
} from "./operations/discover.js";
import {
  validateArtifactOperation,
  explainValidationOperation
} from "./operations/preview.js";

const server = new Server(
  {
    name: "hologram-component-manager",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Handle tool listing
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "submitArtifact",
        description: "Submit and validate an individual artifact (spec or conformance)",
        inputSchema: {
          type: "object",
          properties: {
            content: {
              type: "object",
              description: "The JSON content of the artifact",
            },
            type: {
              type: "string",
              enum: ["spec", "conformance"],
              description: "Type of artifact",
            },
          },
          required: ["content", "type"],
        },
      },
      {
        name: "submitManifest",
        description: "Submit a manifest to create a complete component from validated artifacts",
        inputSchema: {
          type: "object",
          properties: {
            namespace: {
              type: "string",
              description: "Component namespace",
            },
            artifacts: {
              type: "object",
              description: "Map of artifact type to CID",
              properties: {
                spec: { type: "string" },
                interface: { type: "string" },
                docs: { type: "string" },
                test: { type: "string" },
                manager: { type: "string" },
                dependency: { type: "string" },
                build: { type: "string" },
                log: { type: "string" },
                view: { type: "string" },
              },
              required: ["spec"],
            },
          },
          required: ["namespace", "artifacts"],
        },
      },
      {
        name: "validate",
        description: "Validate component(s). Examples: validate() for all, validate({namespace: 'hologram.test'}) for specific component. Shows missing files.",
        inputSchema: {
          type: "object",
          properties: {
            namespace: {
              type: "string",
              description: "Component namespace to validate (omit to validate all)",
            },
          },
        },
      },
      {
        name: "read",
        description: "Read component files",
        inputSchema: {
          type: "object",
          properties: {
            namespace: {
              type: "string",
              description: "Component namespace",
            },
            file: {
              type: "string",
              description: "Specific file to read (omit to read all)",
            },
          },
          required: ["namespace"],
        },
      },
      {
        name: "update",
        description: "Update component files",
        inputSchema: {
          type: "object",
          properties: {
            namespace: {
              type: "string",
              description: "Component namespace",
            },
            files: {
              type: "object",
              description: "Files to update",
              properties: {
                spec: { type: "object" },
                interface: { type: "object" },
                docs: { type: "object" },
                test: { type: "object" },
                manager: { type: "object" },
                dependency: { type: "object" },
                build: { type: "object" },
                log: { type: "object" },
                view: { type: "object" },
              },
            },
          },
          required: ["namespace", "files"],
        },
      },
      {
        name: "delete",
        description: "Delete a component",
        inputSchema: {
          type: "object",
          properties: {
            namespace: {
              type: "string",
              description: "Component namespace to delete",
            },
          },
          required: ["namespace"],
        },
      },
      {
        name: "getComponentModel",
        description: "Get the Hologram component model - explains what files are needed",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "getSchema",
        description: "Get a specific schema to understand structure requirements",
        inputSchema: {
          type: "object",
          properties: {
            schemaName: {
              type: "string",
              description: "Name of schema (e.g., 'hologram.interface')",
            },
          },
          required: ["schemaName"],
        },
      },
      {
        name: "listComponents",
        description: "List all components and their validation status",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "listSchemas",
        description: "List all available schemas for component validation",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "getComponentExample",
        description: "Get example component structures as templates",
        inputSchema: {
          type: "object",
          properties: {
            componentType: {
              type: "string",
              enum: ["simple", "conformance", "operation"],
              description: "Type of example to show",
            },
          },
        },
      },
      {
        name: "validateArtifact",
        description: "Preview validation of an artifact without saving. Test before committing. Example: validateArtifact({content: {...}, type: 'conformance'})",
        inputSchema: {
          type: "object",
          properties: {
            content: {
              type: "object",
              description: "The artifact content to validate",
            },
            type: {
              type: "string",
              enum: ["spec", "conformance"],
              description: "Type of artifact",
            },
            namespace: {
              type: "string",
              description: "Optional namespace for context",
            },
          },
          required: ["content", "type"],
        },
      },
      {
        name: "explainValidation",
        description: "Explain what validations are performed on a component. Shows all checks that would be run.",
        inputSchema: {
          type: "object",
          properties: {
            namespace: {
              type: "string",
              description: "Component namespace to explain",
            },
          },
          required: ["namespace"],
        },
      },
    ],
  };
});

// Handle tool execution
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "submitArtifact":
        return await submitArtifactOperation(
          args?.content as any,
          args?.type as 'spec' | 'conformance'
        );

      case "submitManifest":
        return await submitManifestOperation(
          args?.namespace as string,
          args?.artifacts as Record<string, string>
        );

      case "validate":
        return await validateOperation(args?.namespace as string | undefined);

      case "read":
        return await readOperation(
          args?.namespace as string,
          args?.file as string | undefined
        );

      case "update":
        return await updateOperation(
          args?.namespace as string,
          args?.files as any
        );

      case "delete":
        return await deleteOperation(args?.namespace as string);

      case "getComponentModel":
        return await getComponentModelOperation();

      case "getSchema":
        return await getSchemaOperation(args?.schemaName as string);

      case "listComponents":
        return await listComponentsOperation();

      case "listSchemas":
        return await listSchemasOperation();

      case "getComponentExample":
        return await getComponentExampleOperation(
          args?.componentType as 'simple' | 'conformance' | 'operation' | undefined
        );

      case "validateArtifact":
        return await validateArtifactOperation(
          args?.content as any,
          args?.type as 'spec' | 'conformance',
          args?.namespace as string | undefined
        );

      case "explainValidation":
        return await explainValidationOperation(
          args?.namespace as string
        );

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error instanceof Error ? error.message : "Unknown error"}`,
        },
      ],
    };
  }
});

async function run() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Hologram Component Manager MCP Server running");
}

run().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});