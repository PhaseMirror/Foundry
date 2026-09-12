import { chdir } from "node:process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Delegate to the workspace-level PTau fetcher so this package can run commands locally.
const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

chdir(repoRoot);
await import(resolve(repoRoot, "scripts", "fetch-ptau.mjs"));
