// SPDX-License-Identifier: UNLICENSED
/**
 * Circuit Test Helpers
 * Utilities for testing MTPI/Web4 Zero-Knowledge circuits
 */

const { buildPoseidon } = require("circomlibjs");

/**
 * Create Poseidon hash instance
 * @returns {Promise<Object>} Poseidon hasher
 */
async function getPoseidon() {
  return await buildPoseidon();
}

/**
 * Hash two field elements using Poseidon
 * @param {Object} poseidon - Poseidon instance
 * @param {BigInt} a - First input
 * @param {BigInt} b - Second input
 * @returns {BigInt} Hash output
 */
function poseidon2(poseidon, a, b) {
  const hash = poseidon([a, b]);
  return poseidon.F.toObject(hash);
}

/**
 * Hash three field elements using Poseidon
 * @param {Object} poseidon - Poseidon instance
 * @param {BigInt} a - First input
 * @param {BigInt} b - Second input
 * @param {BigInt} c - Third input
 * @returns {BigInt} Hash output
 */
function poseidon3(poseidon, a, b, c) {
  const hash = poseidon([a, b, c]);
  return poseidon.F.toObject(hash);
}

/**
 * Hash four field elements using Poseidon
 * @param {Object} poseidon - Poseidon instance
 * @param {BigInt} a - First input
 * @param {BigInt} b - Second input
 * @param {BigInt} c - Third input
 * @param {BigInt} d - Fourth input
 * @returns {BigInt} Hash output
 */
function poseidon4(poseidon, a, b, c, d) {
  const hash = poseidon([a, b, c, d]);
  return poseidon.F.toObject(hash);
}

/**
 * Generate a random field element
 * @returns {BigInt} Random field element
 */
function randomFieldElement() {
  const bytes = new Uint8Array(32);
  if (typeof crypto !== 'undefined' && crypto.getRandomValues) {
    crypto.getRandomValues(bytes);
  } else {
    // Node.js fallback
    const cryptoNode = require('crypto');
    cryptoNode.randomFillSync(bytes);
  }
  
  // Convert to BigInt and mod by field size (approximation for safety)
  const BN254_FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;
  let result = 0n;
  for (let i = 0; i < 32; i++) {
    result = (result << 8n) | BigInt(bytes[i]);
  }
  return result % BN254_FIELD_SIZE;
}

/**
 * Known small primes for testing
 */
const KNOWN_PRIMES = [
  2n, 3n, 5n, 7n, 11n, 13n, 17n, 19n, 23n, 29n,
  31n, 37n, 41n, 43n, 47n, 53n, 59n, 61n, 67n, 71n,
  73n, 79n, 83n, 89n, 97n, 101n, 103n, 107n, 109n, 113n
];

/**
 * Known composites for testing
 */
const KNOWN_COMPOSITES = [
  4n, 6n, 8n, 9n, 10n, 12n, 14n, 15n, 16n, 18n,
  20n, 21n, 22n, 24n, 25n, 26n, 27n, 28n, 30n, 32n
];

/**
 * Assert that arrays are equal
 * @param {Array} a - First array
 * @param {Array} b - Second array
 * @param {string} message - Error message
 */
function assertArrayEquals(a, b, message) {
  if (a.length !== b.length) {
    throw new Error(`${message}: Array lengths differ (${a.length} vs ${b.length})`);
  }
  for (let i = 0; i < a.length; i++) {
    if (BigInt(a[i]) !== BigInt(b[i])) {
      throw new Error(`${message}: Arrays differ at index ${i} (${a[i]} vs ${b[i]})`);
    }
  }
}

/**
 * Assert that BigInts are equal
 * @param {BigInt} a - First value
 * @param {BigInt} b - Second value
 * @param {string} message - Error message
 */
function assertBigIntEquals(a, b, message) {
  if (BigInt(a) !== BigInt(b)) {
    throw new Error(`${message}: ${a} !== ${b}`);
  }
}

/**
 * Get current Unix epoch timestamp
 * @returns {BigInt} Current timestamp in seconds
 */
function getCurrentEpoch() {
  return BigInt(Math.floor(Date.now() / 1000));
}

/**
 * Get future epoch timestamp
 * @param {number} secondsAhead - Seconds in the future
 * @returns {BigInt} Future timestamp
 */
function getFutureEpoch(secondsAhead) {
  return getCurrentEpoch() + BigInt(secondsAhead);
}

/**
 * Convert hex string to BigInt
 * @param {string} hex - Hex string (with or without 0x prefix)
 * @returns {BigInt} BigInt value
 */
function hexToBigInt(hex) {
  const cleanHex = hex.startsWith('0x') ? hex.slice(2) : hex;
  return BigInt('0x' + cleanHex);
}

/**
 * Convert BigInt to hex string
 * @param {BigInt} value - BigInt value
 * @param {number} padLength - Optional padding length
 * @returns {string} Hex string with 0x prefix
 */
function bigIntToHex(value, padLength = 0) {
  const hex = value.toString(16);
  const padded = padLength > 0 ? hex.padStart(padLength, '0') : hex;
  return '0x' + padded;
}

/**
 * Test result logger
 */
class TestLogger {
  constructor(circuitName) {
    this.circuitName = circuitName;
    this.passed = 0;
    this.failed = 0;
    this.startTime = Date.now();
  }

  success(testName) {
    this.passed++;
    console.log(`  ✓ ${testName}`);
  }

  failure(testName, error) {
    this.failed++;
    console.log(`  ✗ ${testName}`);
    console.log(`    ${error.message || error}`);
  }

  summary() {
    const elapsed = ((Date.now() - this.startTime) / 1000).toFixed(2);
    console.log(`\n${this.circuitName} Summary:`);
    console.log(`  Passed: ${this.passed}`);
    console.log(`  Failed: ${this.failed}`);
    console.log(`  Time: ${elapsed}s`);
    console.log('');
    
    return this.failed === 0;
  }
}

module.exports = {
  getPoseidon,
  poseidon2,
  poseidon3,
  poseidon4,
  randomFieldElement,
  KNOWN_PRIMES,
  KNOWN_COMPOSITES,
  assertArrayEquals,
  assertBigIntEquals,
  getCurrentEpoch,
  getFutureEpoch,
  hexToBigInt,
  bigIntToHex,
  TestLogger
};
