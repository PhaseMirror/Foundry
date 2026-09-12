import { MockQKDBackend } from '../qkd';
import { encodeProfile, MultiplicityProfile } from '../multiplicity';
import crypto from 'crypto';

describe('QKD End-to-End Round-Trip', () => {
  it('should derive the same key for same input', () => {
    const backend = new MockQKDBackend();
    const profile: MultiplicityProfile = {
      type: 1,
      version: 1,
      stateIndex: 123,
      prime_index: 3
    };
    const context = Buffer.from('test-context', 'utf8');
    const sharedSecret = crypto.randomBytes(32);
    const input = {
      role: 'A' as const,
      context,
      profile,
      sharedSecret
    };
    const out1 = backend.getKey(input);
    const out2 = backend.getKey(input);
    expect(out1.simulatedKey.equals(out2.simulatedKey)).toBe(true);
    expect(out1.label).toBe('SIMULATED_QKD');
  });
});
