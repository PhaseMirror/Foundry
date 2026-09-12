import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const packageDirectory = path.resolve(process.argv[2]);
const sdk = await import(pathToFileURL(path.join(packageDirectory, "fixture.js")));
const wasm = await readFile(path.join(packageDirectory, "fixture_bg.wasm"));
await sdk.default({ module_or_path: wasm });

assert.equal(sdk.prod_fixture_add(2n, 3n), 5n);
assert.equal(sdk.prod_fixture_less(2n, 3n), true);
assert.equal(sdk.prod_fixture_less(3n, 2n), false);
assert.equal(sdk.prod_fixture_echo(true), true);
assert.equal(sdk.prod_fixture_echo(false), false);

assert.throws(
  () => sdk.prod_fixture_add(2n ** 64n - 1n, 1n),
  /addition overflow/,
);
assert.throws(
  () => sdk.prod_fixture_riskyflag(2n ** 64n - 1n),
  /addition overflow/,
);
