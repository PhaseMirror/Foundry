import pytest
from genesis_governance.types import SurfaceState
from genesis_governance.multiplicity.encoder import MultiplicityEncoder
from genesis_governance.multiplicity.decoder import MultiplicityDecoder
from genesis_governance.multiplicity.allocator import PrimeBandAllocator

@pytest.fixture
def allocator():
    return PrimeBandAllocator()

@pytest.fixture
def encoder(allocator):
    return MultiplicityEncoder(allocator=allocator)

@pytest.fixture
def decoder(allocator):
    return MultiplicityDecoder(allocator=allocator)

def test_encoding_decoding_roundtrip(encoder, decoder):
    # Setup a sample state
    state = SurfaceState(
        substrate="metallurgical",
        coherence=0.8,
        stability_threshold=1.0,
        effective_stress=0.5,
        logical_state="ON",
        frequency=1.0
    )
    
    # Encode
    encoding = encoder.encode(state)
    assert encoding.prime_signature == [2, 3, 7, 13]
    assert encoding.exponent_vector[2] == 4  # 0.8 * 5
    assert encoding.exponent_vector[3] == 5  # 0.5 * 10
    assert encoding.exponent_vector[7] == 1  # "ON"
    
    # Decode
    recon_c, recon_s, recon_state, recon_th = decoder.decode(encoding)
    
    # Reconstructed coherence should be mid-bin (4+0.5)/5 = 0.9
    # Wait, 0.8 * 5 = 4. Bin 4 covers [0.8, 1.0). Center is 0.9.
    assert recon_c == pytest.approx(0.9)
    assert recon_s == pytest.approx(0.55) # (5+0.5)/10
    assert recon_state == "ON"
    assert recon_th == False # 0.5 > 0.5 is False
    
def test_threshold_encoding(encoder, decoder):
    state = SurfaceState(
        substrate="Semi",
        coherence=0.9,
        stability_threshold=1.0,
        effective_stress=0.6,
        switching_threshold=0.5,
        logical_state="ON"
    )
    encoding = encoder.encode(state)
    assert encoding.exponent_vector[5] == 1 # 0.6 > 0.5
    
    recon_c, recon_s, recon_state, recon_th = decoder.decode(encoding)
    assert recon_th == True

def test_reconstruction_score(encoder, decoder):
    state = SurfaceState(
        substrate="metallurgical",
        coherence=0.82,
        stability_threshold=1.0,
        effective_stress=0.51,
        logical_state="ON"
    )
    
    encoding = encoder.encode(state)
    score = decoder.compute_reconstruction_score(state, encoding)
    
    assert 0.0 <= score <= 1.0
    assert score > 0.8 # Should be high for close values

def test_sparsity_index(encoder):
    state = SurfaceState(
        substrate="metallurgical",
        coherence=0.0, # Will result in 0 exponent for coherence prime
        stability_threshold=1.0,
        effective_stress=0.0,
        logical_state="OFF", # Not "ON", so 2, still active
        frequency=0.0
    )
    
    encoding = encoder.encode(state)
    # Exponents: c=0, s=0, l=2, f=0. Only prime 7 is in signature if e > 0
    # Wait, the encoder says: prime_signature = [p for p, e in exponent_vector.items() if e > 0]
    assert len(encoding.prime_signature) == 1
    assert encoding.sparsity_index == 0.1 # 1 / 10 available primes

def test_module_quarantine(encoder):
    # Verify that encoding does NOT mutate the scalar value of the state itself, 
    # only the metadata field.
    state = SurfaceState(
        substrate="metallurgical",
        coherence=0.8,
        stability_threshold=1.0,
        effective_stress=0.5
    )
    
    original_coherence = state.coherence
    attached_state = encoder.attach(state)
    
    assert attached_state.coherence == original_coherence
    assert attached_state.multiplicity is not None
    assert attached_state.multiplicity.exponent_vector[2] == 4
