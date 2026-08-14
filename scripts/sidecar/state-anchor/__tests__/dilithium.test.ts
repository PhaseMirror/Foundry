import { execSync } from 'child_process';
import { ethers } from 'ethers';

jest.mock('child_process');
jest.mock('ethers');

const mockedExecSync = jest.mocked<typeof execSync>(execSync);

import { signWithDilithium } from '../index';

function mockExecSync(stdout: string) {
  mockedExecSync.mockImplementation(() => stdout as any);
}

describe('signWithDilithium', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetAllMocks();
    process.env = { ...originalEnv };
    delete (process.env as any).DILITHIUM_SK_PATH;
    delete (process.env as any).DILITHIUM_SIGNER_BIN;
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('throws when DILITHIUM_SK_PATH is missing', async () => {
    delete process.env.DILITHIUM_SK_PATH;
    try {
      await signWithDilithium('0xabc');
      fail('expected signWithDilithium to throw');
    } catch (err) {
      expect((err as Error).message).toBe('DILITHIUM_SK_PATH is not set');
    }
  });

  it('invokes the dilithium-signer CLI and returns 0x-prefixed signature', async () => {
    process.env.DILITHIUM_SK_PATH = '/tmp/sk.bin';
    process.env.DILITHIUM_SIGNER_BIN = '/usr/local/bin/dilithium-signer';
    mockExecSync('0xdeadbeef');

    const result = await signWithDilithium('0xcaafe');
    expect(result).toBe('0xdeadbeef');
    expect(mockedExecSync).toHaveBeenCalledTimes(1);
    const callArg = (mockedExecSync.mock.calls[0] as [string, any])[0];
    expect(callArg).toContain('dilithium-signer');
    expect(callArg).toContain('sign');
    expect(callArg).toContain('--sk-path "/tmp/sk.bin"');
    expect(callArg).toContain('--msg-hex "0xcaafe"');
  });

  it('falls back to PATH binary when configured path does not exist', async () => {
    process.env.DILITHIUM_SK_PATH = '/tmp/sk.bin';
    delete process.env.DILITHIUM_SIGNER_BIN;
    mockExecSync('0xcafe');

    const result = await signWithDilithium('0xcaafe');
    expect(result).toBe('0xcafe');
    expect(mockedExecSync).toHaveBeenCalledTimes(1);
    const callArg = (mockedExecSync.mock.calls[0] as [string, any])[0];
    expect(callArg).toContain('dilithium-signer');
  });

  it('throws on unexpected CLI output', async () => {
    process.env.DILITHIUM_SK_PATH = '/tmp/sk.bin';
    mockExecSync('error: unknown command');

    try {
      await signWithDilithium('0xabc');
      fail('expected signWithDilithium to throw');
    } catch (err) {
      expect((err as Error).message).toContain('Unexpected dilithium-signer output');
    }
  });

  it('throws when CLI exits non-zero', async () => {
    process.env.DILITHIUM_SK_PATH = '/tmp/sk.bin';
    mockedExecSync.mockImplementation(() => {
      throw new Error('exit status 1');
    });

    try {
      await signWithDilithium('0xabc');
      fail('expected signWithDilithium to throw');
    } catch (err) {
      expect((err as Error).message).toBe('exit status 1');
    }
  });
});
