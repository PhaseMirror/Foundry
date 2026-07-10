#!/usr/bin/env node
// SPDX-License-Identifier: UNLICENSED
/**
 * MTPI Circuit Test Runner
 * Runs all circuit tests with proper setup and reporting
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

console.log('═══════════════════════════════════════════════════════════════');
console.log('  MTPI/Web4 Zero-Knowledge Circuit Test Suite');
console.log('  Testing all circuits for correctness and security');
console.log('═══════════════════════════════════════════════════════════════\n');

// Ensure test infrastructure exists
const testDir = path.join(__dirname, 'test');
const cacheDir = path.join(testDir, '.cache');
const logsDir = path.join(testDir, 'logs');

if (!fs.existsSync(testDir)) {
  fs.mkdirSync(testDir, { recursive: true });
}
if (!fs.existsSync(cacheDir)) {
  fs.mkdirSync(cacheDir, { recursive: true });
}
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

console.log('✓ Test infrastructure ready\n');

// Check for required dependencies
try {
  require.resolve('circom_tester');
  require.resolve('circomlibjs');
  require.resolve('mocha');
} catch (err) {
  console.error('✗ Missing test dependencies. Installing...\n');
  try {
    execSync('pnpm add -D circom_tester mocha chai', { stdio: 'inherit' });
    console.log('\n✓ Dependencies installed\n');
  } catch (installErr) {
    console.error('✗ Failed to install dependencies');
    console.error('  Run manually: pnpm add -D circom_tester mocha chai');
    process.exit(1);
  }
}

// Define test files (in order of importance/dependencies)
const testFiles = [
  'millerRabin64.test.js',  // Library: prime testing
  'root.test.js',            // Core: state transitions
  'consent.test.js',         // Healthcare: consent proofs
  'attestation.test.js',
  'prescription.test.js',
  // Add more test files here as they are created:
  // 'eligibility.test.js',
  // 'breakglass.test.js',
  // 'recovery.test.js',
  // 'research_consent.test.js',
  // 'device_attest.test.js',
  // 'data_pointer.test.js',
  // 'driftBound.test.js',
];

// Filter to only existing test files
const existingTests = testFiles.filter(file => {
  const fullPath = path.join(__dirname, file);
  return fs.existsSync(fullPath);
});

if (existingTests.length === 0) {
  console.error('✗ No test files found');
  console.error('  Expected test files in: circuits/');
  process.exit(1);
}

console.log(`Running ${existingTests.length} test suite(s):\n`);
existingTests.forEach((file, idx) => {
  console.log(`  ${idx + 1}. ${file}`);
});
console.log('');

// Run tests using Mocha
const Mocha = require('mocha');
const mocha = new Mocha({
  timeout: 120000, // 2 minutes per test
  bail: false, // Continue on failures
  color: true
});

// Add all test files
existingTests.forEach(file => {
  const fullPath = path.join(__dirname, file);
  mocha.addFile(fullPath);
});

// Run and report
mocha.run(failures => {
  console.log('\n═══════════════════════════════════════════════════════════════');
  if (failures === 0) {
    console.log('  ✓ All circuit tests passed!');
    console.log('  MTPI/Web4 circuits are functioning correctly.');
  } else {
    console.log(`  ✗ ${failures} test(s) failed`);
    console.log('  Review errors above and fix circuit implementations.');
  }
  console.log('═══════════════════════════════════════════════════════════════\n');
  
  process.exitCode = failures ? 1 : 0;
});
