// AEAD module for QKD Hybrid Encryption v1.0.1
// Implements AEAD encrypt/decrypt over context hash

import crypto from 'crypto';
import { MultiplicityProfile, encodeProfile, getPrimeAtIndex, defaultProfile } from './multiplicity';

export interface AEADInput {
  key: Buffer; // 32 bytes
  nonce: Buffer; // 12 bytes
  plaintext?: Buffer;
  ciphertext?: Buffer;
  authTag?: Buffer;
  aad: Buffer; // associated data (context hash, etc.)
  profile?: MultiplicityProfile; // governs nonce derivation tag via prime_index
}

// Derive a prime-indexed nonce tag appended to the base nonce for domain separation.
// prime_index 0 → prime 2 (no stretching); higher indices tighten the nonce domain.
function _nonceTag(profile: MultiplicityProfile): Buffer {
  const prime = getPrimeAtIndex(profile.prime_index);
  const tag = Buffer.alloc(4);
  tag.writeUInt32BE(prime, 0);
  return tag;
}

export function encryptAEAD({ key, nonce, plaintext, aad, profile }: AEADInput): { ciphertext: Buffer; authTag: Buffer } {
  if (!plaintext) throw new Error('Plaintext required for encryption');
  const p = profile ?? defaultProfile();
  const profileBuf = encodeProfile(p);
  const fullAad = Buffer.concat([aad, profileBuf, _nonceTag(p)]);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, nonce);
  cipher.setAAD(fullAad);
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return { ciphertext, authTag };
}

export function decryptAEAD({ key, nonce, ciphertext, authTag, aad, profile }: AEADInput): { plaintext: Buffer } {
  if (!ciphertext || !authTag) throw new Error('Ciphertext and authTag required for decryption');
  const p = profile ?? defaultProfile();
  const profileBuf = encodeProfile(p);
  const fullAad = Buffer.concat([aad, profileBuf, _nonceTag(p)]);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, nonce);
  decipher.setAAD(fullAad);
  decipher.setAuthTag(authTag);
  const plaintext = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  return { plaintext };
}
