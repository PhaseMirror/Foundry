import { chdir } from "node:process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Run the workspace-level build script from the repo root.
const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

chdir(repoRoot);
await import(resolve(repoRoot, "scripts", "build-circuits.mjs"));
