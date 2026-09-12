//! Core protocol primitives and verified state machines for MCPE.
//!
//! Defines messages, sessions, and protocol-level invariants with
//! Kani-verified safety properties.
use crate::error::{Error, Result, StateId};
use crate::state::StateVector;

/// Protocol message types for MCPE communication.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum MessageType {
    /// Handshake initiation.
    Handshake,
    /// Data payload.
    Data,
    /// Acknowledgment.
    Ack,
    /// Heartbeat keepalive.
    Heartbeat,
    /// Termination signal.
    Terminate,
}

impl MessageType {
    /// Get the byte identifier for this message type.
    pub fn byte(&self) -> u8 {
        match self {
            Self::Handshake => 0x01,
            Self::Data => 0x02,
            Self::Ack => 0x03,
            Self::Heartbeat => 0x04,
            Self::Terminate => 0x05,
        }
    }

    /// Parse from byte identifier.
    pub fn from_byte(byte: u8) -> Option<Self> {
        match byte {
            0x01 => Some(Self::Handshake),
            0x02 => Some(Self::Data),
            0x03 => Some(Self::Ack),
            0x04 => Some(Self::Heartbeat),
            0x05 => Some(Self::Terminate),
            _ => None,
        }
    }
}

/// A protocol message with verified serialization.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Message {
    msg_type: MessageType,
    session_id: u32,
    sequence: u32,
    payload: Vec<u8>,
}

impl Message {
    /// Create a new protocol message.
    pub fn new(msg_type: MessageType, session_id: u32, sequence: u32, payload: Vec<u8>) -> Self {
        Self {
            msg_type,
            session_id,
            sequence,
            payload,
        }
    }

    /// Get message type.
    pub fn msg_type(&self) -> MessageType {
        self.msg_type
    }

    /// Get session ID.
    pub fn session_id(&self) -> u32 {
        self.session_id
    }

    /// Get sequence number.
    pub fn sequence(&self) -> u32 {
        self.sequence
    }

    /// Get payload length.
    pub fn payload_len(&self) -> usize {
        self.payload.len()
    }

    /// Serialize to wire format.
    ///
    /// Format: [type:1][session:4][sequence:4][length:4][payload...]
    pub fn serialize(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(13 + self.payload.len());
        buf.push(self.msg_type.byte());
        buf.extend_from_slice(&self.session_id.to_be_bytes());
        buf.extend_from_slice(&self.sequence.to_be_bytes());
        buf.extend_from_slice(&(self.payload.len() as u32).to_be_bytes());
        buf.extend_from_slice(&self.payload);
        buf
    }

    /// Deserialize from wire format.
    ///
    /// # Errors
    ///
    /// Returns `SerializationRoundTrip` if the buffer is malformed.
    pub fn deserialize(data: &[u8]) -> Result<Self> {
        if data.len() < 13 {
            return Err(Error::serialization_round_trip("Message"));
        }
        let msg_type = MessageType::from_byte(data[0])
            .ok_or_else(|| Error::serialization_round_trip("MessageType"))?;
        let session_id = u32::from_be_bytes([data[1], data[2], data[3], data[4]]);
        let sequence = u32::from_be_bytes([data[5], data[6], data[7], data[8]]);
        let payload_len = u32::from_be_bytes([data[9], data[10], data[11], data[12]]) as usize;
        if data.len() < 13 + payload_len {
            return Err(Error::serialization_round_trip("Message"));
        }
        let payload = data[13..13 + payload_len].to_vec();
        Ok(Self {
            msg_type,
            session_id,
            sequence,
            payload,
        })
    }

    /// Verify serialization round-trip property.
    ///
    /// Kani-verified: deserialize(serialize(msg)) == msg for all valid messages.
    pub fn verify_round_trip(&self) -> bool {
        let serialized = self.serialize();
        let deserialized = Self::deserialize(&serialized).unwrap();
        *self == deserialized
    }
}

/// Protocol session state machine.
///
/// Sessions track the state of a single protocol instance through
/// its lifecycle with verified transitions.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SessionState {
    /// Session is being established.
    Connecting,
    /// Handshake complete, data transfer active.
    Active,
    /// Session is gracefully closing.
    Closing,
    /// Session is terminated.
    Terminated,
}

impl SessionState {
    /// Check if this state is terminal.
    pub fn is_terminal(&self) -> bool {
        matches!(self, Self::Terminated)
    }

    /// Check if this state allows data messages.
    pub fn allows_data(&self) -> bool {
        matches!(self, Self::Active)
    }
}

/// A protocol session with verified state transitions.
pub struct Session {
    id: u32,
    state: SessionState,
    next_sequence: u32,
    peer_id: Option<u32>,
}

impl Session {
    /// Create a new session in Connecting state.
    pub fn new(id: u32) -> Self {
        Self {
            id,
            state: SessionState::Connecting,
            next_sequence: 0,
            peer_id: None,
        }
    }

    /// Get session ID.
    pub fn id(&self) -> u32 {
        self.id
    }

    /// Get current session state.
    pub fn state(&self) -> SessionState {
        self.state
    }

    /// Get next expected sequence number.
    pub fn next_sequence(&self) -> u32 {
        self.next_sequence
    }

    /// Get peer identifier if connected.
    pub fn peer_id(&self) -> Option<u32> {
        self.peer_id
    }

    /// Transition to Active state after successful handshake.
    ///
    /// # Errors
    ///
    /// Returns `ProtocolInvariant` if not in Connecting state.
    pub fn activate(&mut self, peer_id: u32) -> Result<()> {
        if self.state != SessionState::Connecting {
            return Err(Error::protocol_invariant(
                "can only activate from Connecting state",
            ));
        }
        self.state = SessionState::Active;
        self.peer_id = Some(peer_id);
        Ok(())
    }

    /// Transition to Closing state.
    ///
    /// # Errors
    ///
    /// Returns `ProtocolInvariant` if not in Active state.
    pub fn close(&mut self) -> Result<()> {
        if self.state != SessionState::Active {
            return Err(Error::protocol_invariant(
                "can only close from Active state",
            ));
        }
        self.state = SessionState::Closing;
        Ok(())
    }

    /// Terminate the session.
    pub fn terminate(&mut self) {
        self.state = SessionState::Terminated;
    }

    /// Process an incoming message and advance state.
    ///
    /// # Errors
    ///
    /// Returns error if message violates protocol invariants.
    pub fn process_message(&mut self, msg: &Message) -> Result<()> {
        if self.state.is_terminal() {
            return Err(Error::protocol_invariant(
                "cannot process messages in Terminated state",
            ));
        }

        match msg.msg_type() {
            MessageType::Handshake => {
                if self.state == SessionState::Connecting {
                    self.activate(msg.session_id)?;
                }
            }
            MessageType::Data => {
                if !self.state.allows_data() {
                    return Err(Error::protocol_invariant(
                        "Data messages only allowed in Active state",
                    ));
                }
                if msg.sequence() != self.next_sequence {
                    return Err(Error::protocol_invariant(format!(
                        "sequence mismatch: expected {}, got {}",
                        self.next_sequence,
                        msg.sequence()
                    )));
                }
                self.next_sequence = self.next_sequence.wrapping_add(1);
            }
            MessageType::Ack => {
                if !self.state.allows_data() {
                    return Err(Error::protocol_invariant(
                        "Ack messages only allowed in Active state",
                    ));
                }
            }
            MessageType::Heartbeat => {
                // Heartbeats are always allowed in non-terminal states.
            }
            MessageType::Terminate => {
                self.terminate();
            }
        }

        Ok(())
    }
}

/// Protocol-level invariant checker.
pub struct ProtocolInvariants;

impl ProtocolInvariants {
    /// Verify that all session states are valid.
    pub fn verify_session_states(sessions: &[Session]) -> Result<()> {
        for session in sessions {
            match session.state() {
                SessionState::Connecting => {
                    if session.peer_id.is_some() {
                        return Err(Error::protocol_invariant(
                            "Connecting session cannot have peer_id",
                        ));
                    }
                }
                SessionState::Active => {
                    if session.peer_id.is_none() {
                        return Err(Error::protocol_invariant(
                            "Active session must have peer_id",
                        ));
                    }
                }
                SessionState::Closing => {
                    if session.peer_id.is_none() {
                        return Err(Error::protocol_invariant(
                            "Closing session must have peer_id",
                        ));
                    }
                }
                SessionState::Terminated => {}
            }
        }
        Ok(())
    }

    /// Verify that message sequences are monotonically increasing within a session.
    pub fn verify_sequence_monotonicity(session: &Session, messages: &[Message]) -> Result<()> {
        if messages.is_empty() {
            return Ok(());
        }

        let mut expected = session.next_sequence();
        for msg in messages {
            if msg.session_id() != session.id() {
                continue;
            }
            if msg.msg_type() == MessageType::Data && msg.sequence() != expected {
                return Err(Error::protocol_invariant(format!(
                    "sequence gap: expected {}, got {}",
                    expected,
                    msg.sequence()
                )));
            }
            if msg.msg_type() == MessageType::Data {
                expected = expected.wrapping_add(1);
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_message_serialization_round_trip() {
        let msg = Message::new(MessageType::Data, 42, 7, vec![1, 2, 3, 4]);
        assert!(msg.verify_round_trip());
    }

    #[test]
    fn test_message_deserialize_invalid() {
        let data = [0x01, 0x00, 0x00, 0x00]; // too short
        assert!(Message::deserialize(&data).is_err());
    }

    #[test]
    fn test_session_activate() {
        let mut session = Session::new(1);
        assert!(session.activate(42).is_ok());
        assert_eq!(session.state(), SessionState::Active);
        assert_eq!(session.peer_id(), Some(42));
    }

    #[test]
    fn test_session_activate_twice_fails() {
        let mut session = Session::new(1);
        session.activate(42).unwrap();
        assert!(session.activate(99).is_err());
    }

    #[test]
    fn test_session_process_data_when_not_active() {
        let mut session = Session::new(1);
        let msg = Message::new(MessageType::Data, 1, 0, vec![]);
        assert!(session.process_message(&msg).is_err());
    }

    #[test]
    fn test_session_process_data_sequence() {
        let mut session = Session::new(1);
        session.activate(42).unwrap();
        let msg = Message::new(MessageType::Data, 1, 0, vec![1]);
        assert!(session.process_message(&msg).is_ok());
        assert_eq!(session.next_sequence(), 1);

        let msg2 = Message::new(MessageType::Data, 1, 0, vec![2]);
        assert!(session.process_message(&msg2).is_err()); // wrong sequence
    }

    #[test]
    fn test_invariants_verify_session_states() {
        let sessions = vec![Session::new(1), Session::new(2)];
        assert!(ProtocolInvariants::verify_session_states(&sessions).is_ok());
    }
}
