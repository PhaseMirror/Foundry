use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Type { I32, I64, U32, U64, F32, F64 }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Register(pub u16);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Predicate(pub u8);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct BufferHandle(pub u8);

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum Address {
    BufferOffset { handle: BufferHandle, offset: u64 },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Cond { Eq, Ne, Lt, Gt, Le, Ge }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Instruction {
    ADD { ty: Type, dst: Register, src1: Register, src2: Register },
    SUB { ty: Type, dst: Register, src1: Register, src2: Register },
    MUL { ty: Type, dst: Register, src1: Register, src2: Register },
    LDG { ty: Type, dst: Register, addr: Address },
    STG { ty: Type, src: Register, addr: Address },
    BRA { target: String, pred: Option<Predicate> },
    CALL { target: String },
    EXIT,
    MOV { dst: Register, src: u64 },
    SETcc { ty: Type, dst: Predicate, src1: Register, src2: Register, cond: Cond },
}
