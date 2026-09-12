//! Integration tests for MCPE framework.
//!
//! These tests verify end-to-end functionality and serve as examples
//! for library consumers.

use mcpe::{
    error::{Error, StateId},
    numeric::{FixedPoint, UInt256},
    protocol::{Message, MessageType, ProtocolInvariants, Session, SessionState},
    state::{LinearTransition, RepairTransition, StateVector, Transition},
};

#[test]
fn test_fixed_point_arithmetic_chain() {
    let a = FixedPoint::from_f64(1.5, 8, 16).unwrap();
    let b = FixedPoint::from_f64(2.5, 8, 16).unwrap();
    let sum = a.add(b).unwrap();
    assert_eq!(sum.to_f64(), 4.0);

    let diff = sum.sub(a).unwrap();
    assert_eq!(diff.to_f64(), 2.5);
}

    #[test]
    fn test_uint256_operations() {
        let a = UInt256::from_u128(u128::MAX);
        let b = UInt256::from_u128(1);
        let sum = a.add(b).unwrap();
        assert_eq!(sum.lo(), 0);
        assert_eq!(sum.hi(), 1);
    }

#[test]
fn test_state_vector_lifecycle() {
    let id = StateId::new(1);
    let sv = StateVector::from_array(id, [10, 20, 30]);
    assert_eq!(sv.l2_norm(), 10.0_f64.hypot(20.0).hypot(30.0));

    let transition = RepairTransition::new(-5, 0, 100);
    let next = transition.apply(&sv).unwrap();
    assert_eq!(next.values(), &[5, 15, 25]);
}

#[test]
fn test_linear_transition_chain() {
    let id = StateId::new(1);
    let sv = StateVector::from_array(id, [0, 0, 0]);
    let delta = vec![1, 2, 3];
    let transition = LinearTransition::new(delta, 3).unwrap();

    let mut current = sv;
    for i in 1..=5 {
        current = transition.apply(&current).unwrap();
        assert_eq!(current.values(), &[i as i64, 2 * i as i64, 3 * i as i64]);
    }
}

#[test]
fn test_message_serialization_all_types() {
    let types = [
        MessageType::Handshake,
        MessageType::Data,
        MessageType::Ack,
        MessageType::Heartbeat,
        MessageType::Terminate,
    ];

    for &msg_type in &types {
        let msg = Message::new(msg_type, 42, 7, vec![0xAB, 0xCD, 0xEF]);
        assert!(msg.verify_round_trip());
    }
}

#[test]
fn test_session_lifecycle() {
    let mut session = Session::new(1);

    // Initial state
    assert_eq!(session.state(), SessionState::Connecting);
    assert_eq!(session.next_sequence(), 0);

    // Activate
    session.activate(100).unwrap();
    assert_eq!(session.state(), SessionState::Active);
    assert_eq!(session.peer_id(), Some(100));

    // Process data messages
    let msg = Message::new(MessageType::Data, 1, 0, vec![1, 2, 3]);
    session.process_message(&msg).unwrap();
    assert_eq!(session.next_sequence(), 1);

    // Close
    session.close().unwrap();
    assert_eq!(session.state(), SessionState::Closing);

    // Terminate
    session.terminate();
    assert_eq!(session.state(), SessionState::Terminated);
}

#[test]
fn test_protocol_invariants_valid_sessions() {
    let sessions = vec![Session::new(1), Session::new(2), Session::new(3)];
    assert!(ProtocolInvariants::verify_session_states(&sessions).is_ok());
}

#[test]
fn test_protocol_invariants_sequence_gap() {
    let mut session = Session::new(1);
    session.activate(42).unwrap();

    let msg1 = Message::new(MessageType::Data, 1, 0, vec![1]);
    session.process_message(&msg1).unwrap();

    // Sequence gap should be detected
    let msg2 = Message::new(MessageType::Data, 1, 5, vec![2]);
    assert!(session.process_message(&msg2).is_err());
}

#[test]
fn test_repair_transition_bounds() {
    let transition = RepairTransition::new(-10, -50, 50);

    // Value within bounds after repair
    let id = StateId::new(1);
    let sv = StateVector::from_array(id, [100]);
    let next = transition.apply(&sv).unwrap();
    assert_eq!(next.get(0).unwrap(), 50);

    // Value below lower bound
    let sv2 = StateVector::from_array(id, [-100]);
    let next2 = transition.apply(&sv2).unwrap();
    assert_eq!(next2.get(0).unwrap(), -50);

    // Value within bounds unchanged after repair
    let sv3 = StateVector::from_array(id, [25]);
    let next3 = transition.apply(&sv3).unwrap();
    assert_eq!(next3.get(0).unwrap(), 15); // 25 + (-10) = 15
}

#[test]
fn test_error_recovery() {
    let id = StateId::new(1);
    let err = Error::protocol_invariant("test");
    assert!(err.to_string().contains("test"));

    let err2 = Error::numeric_overflow("test_op", 42);
    assert!(err2.to_string().contains("test_op"));
    assert!(err2.to_string().contains("42"));
}

#[test]
fn test_state_vector_out_of_bounds() {
    let id = StateId::new(1);
    let sv = StateVector::from_array(id, [1, 2, 3]);
    assert!(sv.get(5).is_err());
}
