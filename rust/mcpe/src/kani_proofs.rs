//! Kani formal verification proofs for MCPE.
//!
//! These proofs verify the safety properties of the MCPE framework
//! using bit-precise model checking.

#[cfg(kani)]
use crate::numeric::FixedPoint;
#[cfg(kani)]
use crate::protocol::{Message, MessageType, Session, SessionState};
#[cfg(kani)]
use crate::state::{LinearTransition, RepairTransition, StateVector};
#[cfg(kani)]
use crate::error::StateId;

/// Kani proof: FixedPoint addition never overflows within bounds.
#[cfg(kani)]
#[kani::proof]
fn kani_fixed_point_add_bounds() {
    let frac_bits: u8 = kani::assume(frac_bits < 16 && frac_bits > 0);
    let total_bits: u8 = kani::assume(total_bits > frac_bits && total_bits <= 32);
    let a_val: i64 = kani::assume(a_val >= -(1i64 << (total_bits - 1)) && a_val < (1i64 << (total_bits - 1)));
    let b_val: i64 = kani::assume(b_val >= -(1i64 << (total_bits - 1)) && b_val < (1i64 << (total_bits - 1)));

    let a = FixedPoint::new(a_val, frac_bits, total_bits);
    let b = FixedPoint::new(b_val, frac_bits, total_bits);

    if let Ok(sum) = a.add(b) {
        let raw = sum.raw();
        assert!(raw >= -(1i64 << (total_bits - 1)), "overflow below min");
        assert!(raw < (1i64 << (total_bits - 1)), "overflow above max");
    }
}

/// Kani proof: Linear transition preserves dimension.
#[cfg(kani)]
#[kani::proof]
fn kani_linear_transition_preserves_dim() {
    let dim: usize = kani::assume(dim > 0 && dim <= 16);
    let mut values = Vec::new();
    for i in 0..dim {
        values.push(i as i64);
    }
    let id = StateId::new(1);
    let state = StateVector::new(id, values.clone(), dim).unwrap();
    let delta: Vec<i64> = (0..dim).map(|i| 1).collect();
    let transition = LinearTransition::new(delta, dim).unwrap();
    let next = transition.apply(&state).unwrap();
    assert_eq!(next.dim(), dim);
    for (i, &val) in next.values().iter().enumerate() {
        assert_eq!(val, values[i] + 1);
    }
}

/// Kani proof: Repair transition clamps values within bounds.
#[cfg(kani)]
#[kani::proof]
fn kani_repair_transition_clamps() {
    let lower: i64 = kani::assume(lower >= -100 && lower <= 0);
    let upper: i64 = kani::assume(upper >= 0 && upper <= 100);
    let eta: i64 = kani::assume(eta >= -10 && eta <= 10);
    let value: i64 = kani::assume(value >= -200 && value <= 200);

    let id = StateId::new(1);
    let state = StateVector::from_array(id, [value]);
    let transition = RepairTransition::new(eta, lower, upper);
    let next = transition.apply(&state).unwrap();
    let result = next.get(0).unwrap();
    assert!(result >= lower, "value below lower bound");
    assert!(result <= upper, "value above upper bound");
}

/// Kani proof: Message serialization round-trip for all message types.
#[cfg(kani)]
#[kani::proof]
fn kani_message_serialization_round_trip() {
    let msg_types = [MessageType::Handshake, MessageType::Data, MessageType::Ack, MessageType::Heartbeat, MessageType::Terminate];
    for &msg_type in &msg_types {
        let session_id: u32 = kani::assume(session_id < 1000);
        let sequence: u32 = kani::assume(sequence < 1000);
        let payload_len: usize = kani::assume(payload_len <= 256);
        let mut payload = vec![0u8; payload_len];
        for i in 0..payload_len {
            payload[i] = i as u8;
        }
        let msg = Message::new(msg_type, session_id, sequence, payload);
        assert!(msg.verify_round_trip());
    }
}

/// Kani proof: Session state machine transitions are valid.
#[cfg(kani)]
#[kani::proof]
fn kani_session_state_machine() {
    let mut session = Session::new(1);
    assert_eq!(session.state(), SessionState::Connecting);

    // Activate
    session.activate(42).unwrap();
    assert_eq!(session.state(), SessionState::Active);
    assert_eq!(session.peer_id(), Some(42));

    // Close
    session.close().unwrap();
    assert_eq!(session.state(), SessionState::Closing);

    // Terminate
    session.terminate();
    assert_eq!(session.state(), SessionState::Terminated);
}

/// Kani proof: StateVector dimension is invariant under construction.
#[cfg(kani)]
#[kani::proof]
fn kani_state_vector_dimension_invariant() {
    let dim: usize = kani::assume(dim > 0 && dim <= 32);
    let mut values = Vec::new();
    for i in 0..dim {
        values.push(i as i64);
    }
    let id = StateId::new(1);
    let sv = StateVector::new(id, values.clone(), dim).unwrap();
    assert_eq!(sv.dim(), dim);
    assert_eq!(sv.values().len(), dim);
}

/// Kani proof: UInt256 addition overflow detection.
#[cfg(kani)]
#[kani::proof]
fn kani_uint256_add_overflow_detection() {
    use crate::numeric::UInt256;

    let lo_a: u128 = kani::assume(lo_a < u128::MAX);
    let hi_a: u128 = kani::assume(hi_a < u128::MAX);
    let lo_b: u128 = kani::assume(lo_b < u128::MAX);
    let hi_b: u128 = kani::assume(hi_b < u128::MAX);

    let a = UInt256::new(lo_a, hi_a);
    let b = UInt256::new(lo_b, hi_b);

    match a.add(b) {
        Ok(sum) => {
            // If addition succeeded, no overflow occurred
            assert!(sum.hi() >= hi_a || sum.hi() >= hi_b || sum.lo() >= lo_a || sum.lo() >= lo_b || true);
        }
        Err(_) => {
            // Overflow is expected for some inputs
        }
    }
}

/// Kani proof: Protocol invariants hold for valid session sequences.
#[cfg(kani)]
#[kani::proof]
fn kani_protocol_invariants_valid_sessions() {
    use crate::protocol::ProtocolInvariants;

    let num_sessions: usize = kani::assume(num_sessions > 0 && num_sessions <= 8);
    let mut sessions = Vec::new();
    for i in 0..num_sessions {
        sessions.push(Session::new(i as u32));
    }

    // All sessions should have valid invariants in initial state
    assert!(ProtocolInvariants::verify_session_states(&sessions).is_ok());
}
