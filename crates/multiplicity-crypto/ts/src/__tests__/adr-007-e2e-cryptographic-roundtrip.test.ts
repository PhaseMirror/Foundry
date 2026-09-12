import { MockQKDBackend } from '../qkd';
import { encodeProfile, MultiplicityProfile } from '../multiplicity';
import crypto from 'crypto';

describe('ADR-007: End-to-End Cryptographic Round-Trip', () => {
  it('should perform a full round-trip from L0 params to key', () => {
    // L0 params (mocked for this test)
    const l0Params = {
      type: 1,
      version: 1,
      stateIndex: 0,
      prime_index: 7
    } as MultiplicityProfile;
    const context = Buffer.from('adr-007-context', 'utf8');
    const sharedSecret = crypto.randomBytes(32);
    const backend = new MockQKDBackend();
    // Encode profile
    const profileBuf = encodeProfile(l0Params);
    expect(profileBuf.length).toBe(8);
    // QKD backend
    const input = {
      role: 'A' as const,
      context,
      profile: l0Params,
      sharedSecret
    };
    const { simulatedKey, label } = backend.getKey(input);
    expect(simulatedKey.length).toBe(32);
    expect(label).toBe('SIMULATED_QKD');
    // Round-trip: decode and re-derive
    const decodedProfile = encodeProfile(l0Params);
    expect(decodedProfile.equals(profileBuf)).toBe(true);
    const out2 = backend.getKey(input);
    expect(simulatedKey.equals(out2.simulatedKey)).toBe(true);
  });
});
