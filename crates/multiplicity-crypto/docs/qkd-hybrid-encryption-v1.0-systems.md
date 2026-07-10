---
slug: qkd-hybrid-encryption-v1-0
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 05-systems/cryptography/Qkd Hybrid Encryption V1.0.md
  last_synced: '2026-03-20T17:17:17.924113Z'
---

Quantum‑Assisted Hybrid Encryption System —
Version 1.0.1
This document compiles the final interoperable clarifications, byte‑exact test vectors, and the latest
correction (HKDF‑Extract PRK debug anchor) into one consistent reference.




1) Normative clarifications (v1.0.1)

1.1 Endianness (wire formats)

All integer fields in all wire formats are big‑endian (network byte order): - uint16 = 2 bytes MSB first -
uint32 = 4 bytes MSB first - uint64 = 8 bytes MSB first


Applies to: - message_sequence , payload_length - AEAD seq64 - Any length prefixes used in
transcript components


1.2 Two message formats and bootstrap transition

     • BOOTSTRAP_MESSAGE (pre‑ K_auth ): no HMAC tag
     • CLASSICAL_MESSAGE (post‑ K_auth ): includes
        authentication_tag = HMAC‑SHA256(K_auth, …)

The first message after K_auth derivation MUST use CLASSICAL_MESSAGE.


1.3 Strict per‑sender message sequence validation (all protocol messages)

Receiver MUST enforce strict in‑order validation for both bootstrap and secured frames: 1. Maintain
 expected_next_sequence[sender]           (init  0)   2.  Reject  if   message_sequence     !=
expected_next_sequence[sender]           3. Abort session on validation failure (recommended v1.0.1
behavior) 4. Increment expected counter on accept


1.4 Per‑sender transcript hash chains

Compute per‑sender hash chains and combine: - SID = SHA256(nonce_A || nonce_B) - H_A0 =
SHA256(VERSION || SID || ALICE_LABEL) - H_B0 = SHA256(VERSION || SID || BOB_LABEL) -
H_A(i+1)     =   SHA256(H_A(i)      ||   m_A(i))    -       H_B(j+1)   =   SHA256(H_B(j)   ||   m_B(j))   -
context_hash = SHA256(H_A_final || H_B_final)


Buffering rule: buffer HELO and HELO_RESP until ML‑KEM_CT arrives, then compute SID , initialize
chains, and replay buffered messages into the appropriate sender chain in arrival order.




                                                        1
1.5 Role labels (exact length)

Both labels are exactly 8 bytes: - ALICE_LABEL = 41 4c 49 43 45 00 00 00 ("ALICE" + 3 NUL) -
 BOB_LABEL        = 42 4f 42 00 00 00 00 00 ("BOB" + 5 NUL)


1.6 HMAC input bytes (exact)

For CLASSICAL_MESSAGE , HMAC input is the exact on‑wire bytes:


 message_type || message_sequence || payload_length || payload


(1 byte) || (4 bytes big‑endian) || (2 bytes big‑endian) || (payload_length bytes)


Optional hardening: MAY prefix with SENDER_LABEL to mitigate reflection, but must be negotiated
(capability flag) if used.


1.7 Directional AEAD keys and per‑direction replay state

Implementations MUST use separate AEAD keys per direction and maintain separate replay state.


Key derivation (HKDF‑SHA256): -        K_enc_A2B     =    HKDF(K,    salt,    info="AEAD-ENC-A2B"     ||
ALICE_LABEL                    ||                  context_hash,                     L=32)                  -
 K_enc_B2A = HKDF(K, salt, info="AEAD-ENC-B2A" || BOB_LABEL                      || context_hash, L=32)


Replay state must be per direction: - Maintain            next_seq_expected[SID,      DIRECTION]      where
 DIRECTION ∈ {A2B, B2A} - Accept iff seq64 == next_seq_expected[SID, DIRECTION] , then
increment by 1


1.8 AEAD nonce prefix derivation (deterministic)

AEAD nonce is prefix32 || seq64 .


Deterministic prefix derivation: -    prefix32_A2B        =   SHA256("IVPFX-A2B"     ||   K_enc_A2B    ||
context_hash)[0:4] - prefix32_B2A = SHA256("IVPFX-B2A" || K_enc_B2A || context_hash)
[0:4]


 seq64 starts at 0 per direction and increments by 1 per encryption.


1.9 Payload length limits

 payload_length is uint16 , max 65535. - v1.0.1 does not support fragmentation. - Sender MUST NOT
encode larger payloads. - Receiver MUST abort on malformed frames.




                                                      2
1.10 String constants (byte‑exact)

All strings are ASCII bytes, no null terminators, case‑sensitive.


     • "IVPFX-A2B" = 49 56 50 46 58 2d 41 32 42 (9 bytes)
     • "IVPFX-B2A" = 49 56 50 46 58 2d 42 32 41 (9 bytes)
     • "AEAD-ENC-A2B" = 41 45 41 44 2d 45 4e 43 2d 41 32 42 (12 bytes)
     • "AEAD-ENC-B2A" = 41 45 41 44 2d 45 4e 43 2d 42 32 41 (12 bytes)




2) HKDF salt rule (test vectors)

2.1 Normative salt for v1.0.1 test vectors

For v1.0.1 test vectors (not necessarily live protocol), HKDF uses: - salt = 00 * 32 (32 bytes of zero) for
SHA‑256


This avoids cross‑library ambiguity.




3) Normative test suite (byte‑exact)

Test 1 — Hash chain

     • SESSION_ID :
     • 0e35a53871304db5962bedd5562462cf086ab5dd2fa0fdc00cf15902211feaa1
     • context_hash :
     • e4b71278b8c643fc0c3ec88ea0efa1b58ae2561aed98959e4f26ea9670298c88

(Intermediate chain values remain as previously published in the v1.0 test vector set.)


Test 2 — Basis packing

     • [0,1,2,3] → 0xE4
     • [0,0,0,0] → 0x00
     • [3,3,3,3] → 0xFF
     • [1,2,3,0] → 0x39

Test 3 — Strict replay protection

Input: [0,1,2,3,5,4,6,5,6] Output: [A,A,A,A,R,A,R,A,A] Final next_seq_expected = 7


Test 4 — HMAC computation

     • Input bytes: 0400000001000401020304
     • Tag:




                                                      3
     • 3d700ffa04462dca05efce29e6ec166e1387f11872d453dffbac5dfbdb456d2d

Test 5 — Directional key derivation (HKDF‑SHA256)

Inputs:    -   K        =     00      *   32        -    salt           =    00   *   32      -    context_hash          =
e4b71278b8c643fc0c3ec88ea0efa1b58ae2561aed98959e4f26ea9670298c88                                   -       ALICE_LABEL       =
414c494345000000 - BOB_LABEL                       = 424f420000000000 - info_a2b = "AEAD-ENC-A2B" ||
ALICE_LABEL        ||       context_hash       -    info_b2a        =       "AEAD-ENC-B2A"    ||   BOB_LABEL             ||
context_hash


Expected                           outputs:                         -                      K_enc_A2B :                           -
dd70c9f5110ea586dac2ba20569481ad03d8df346c9d17cd78cbf70a9cd2c9e5                                       -     K_enc_B2A :         -
da2273fed3c28f397e687de459ea37f5bef4fa7af6047c0af48ab3c98f390c6a


Test 6 — Deterministic nonce prefix derivation

     • prefix32_A2B :
     • ff54b8c0
     • prefix32_B2A :
     • bc58de4c




4) Debug anchors (v1.0.1)

4.1 Corrected HKDF‑Extract PRK (Test 5)

This is a debug anchor to isolate HKDF‑Extract from HKDF‑Expand.


Inputs: - salt = 00 * 32 - IKM                = 00 * 32


Correct        output:               -             PRK          =              HMAC‑SHA256(salt,              IKM) :             -
33ad0a1c607ec03b09e6cd9893680ce210adf300aa1f2660e1b22e10f170f92a


Note: A previously published PRK value starting with 5f5c… was incorrect.


4.2 HKDF‑Expand anchors

For L=32 with SHA‑256, the first expand block T(1) equals the final OKM. Therefore: - T(1)_A2B =
K_enc_A2B - T(1)_B2A = K_enc_B2A




                                                                4
5) Minimal reference pseudocode (for conformance)

5.1 HKDF (RFC 5869) with explicit test salt

    • Extract: PRK = HMAC‑SHA256(salt, IKM)
    • Expand: OKM = HMAC‑SHA256(PRK, T(0)||info||0x01) truncated to 32 bytes

5.2 Nonce prefix

    • prefix32 = SHA256(prefix_string || K_enc || context_hash)[0:4]




6) Implementation checklist (v1.0.1)
    • [ ] Big‑endian encoding everywhere
    • [ ] 8‑byte role labels exactly as specified
    • [ ] Strict message_sequence validation for bootstrap and secured messages
    • [ ] HMAC input = exact wire bytes (no struct packing)
    • [ ] Directional AEAD keys + per‑direction replay state
    • [ ] Deterministic nonce prefix derivation
    • [ ] Pass Tests 1–6 exactly
    • [ ] (Debug) Verify Test 5 PRK anchor matches 33ad…f92a




7) Change log (high‑level)
    • Added/clarified per‑direction AEAD keys and replay state
    • Clarified strict sequence validation applies to all protocol messages
    • Defined exact HMAC input bytes
    • Standardized role labels to 8 bytes (ALICE/BOB)
    • Clarified test‑vector HKDF salt as explicit 00*32
    • Added deterministic nonce prefix derivation and test vectors
    • Corrected HKDF‑Extract PRK debug anchor for Test 5




                                                     5
