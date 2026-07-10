#!/usr/bin/env node
import { validateOperation } from './operations/validate.js';

async function main() {
  const namespace = process.argv[2];

  console.log('🔍 Validating Hologram components...\n');

  const result = await validateOperation(namespace);

  for (const item of result.content) {
    if (item.type === 'text') {
      console.log(item.text);
    }
  }

  process.exit(0);
}

main().catch(error => {
  console.error('Validation error:', error);
  process.exit(1);
});