use serde::{Deserialize, Serialize};

#[derive(Debug, PartialEq, Clone, Serialize, Deserialize)]
pub enum RaftState {
    Follower,
    Candidate,
    Leader,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VoteRequest {
    pub candidate_id: String,
    pub term: u64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VoteResponse {
    pub term: u64,
    pub vote_granted: bool,
}

/// Distributed Consensus Hook (Raft) mapping over the Swarm RPC
pub struct RaftNode {
    pub node_id: String,
    pub current_term: u64,
    pub state: RaftState,
    pub voted_for: Option<String>,
}

impl RaftNode {
    pub fn new(node_id: &str) -> Self {
        Self {
            node_id: node_id.to_string(),
            current_term: 0,
            state: RaftState::Follower,
            voted_for: None,
        }
    }

    /// Receives a vote request from a candidate in the swarm
    pub fn handle_vote_request(&mut self, req: VoteRequest) -> VoteResponse {
        if req.term > self.current_term {
            self.current_term = req.term;
            self.state = RaftState::Follower;
            self.voted_for = Some(req.candidate_id.clone());
            return VoteResponse {
                term: self.current_term,
                vote_granted: true,
            };
        }

        if req.term == self.current_term {
            if self.voted_for.is_none() || self.voted_for.as_deref() == Some(&req.candidate_id) {
                self.voted_for = Some(req.candidate_id);
                return VoteResponse {
                    term: self.current_term,
                    vote_granted: true,
                };
            }
        }

        VoteResponse {
            term: self.current_term,
            vote_granted: false,
        }
    }
}
