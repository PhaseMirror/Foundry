use atlas_isa::{Instruction, Type, Register, Address};
use pirtm_rs::{AuditChain, SpectralGovernor};
use std::collections::HashMap;
use anyhow::{Result, anyhow};

pub struct RegisterFile {
    regs: HashMap<u16, (Type, u64)>,
}

impl RegisterFile {
    pub fn new() -> Self {
        Self { regs: HashMap::new() }
    }

    pub fn write(&mut self, reg: Register, val: u64, ty: Type) {
        self.regs.insert(reg.0, (ty, val));
    }

    pub fn read(&self, reg: Register) -> Result<u64> {
        self.regs.get(&reg.0).map(|(_, val)| *val).ok_or(anyhow!("Uninitialized register"))
    }
}

pub struct AtlasProcessor {
    registers: RegisterFile,
    pc: usize,
    governor: SpectralGovernor,
    audit: AuditChain,
    memory: HashMap<u64, u64>, // Simple memory for LDG/STG
}

impl AtlasProcessor {
    pub fn new(dim: usize) -> Self {
        Self {
            registers: RegisterFile::new(),
            pc: 0,
            governor: SpectralGovernor::new(dim),
            audit: AuditChain::new(),
            memory: HashMap::new(),
        }
    }

    pub fn execute_program(&mut self, program: &[Instruction]) -> Result<()> {
        while self.pc < program.len() {
            let inst = &program[self.pc];
            self.execute_instruction(inst)?;
        }
        Ok(())
    }

    fn execute_instruction(&mut self, inst: &Instruction) -> Result<()> {
        // Stability Gating: check bifurcation boundary
        let report = self.governor.analyze(|v| nalgebra::DVector::from_element(v.len(), 0.0));
        if !report.contraction_feasible {
            return Err(anyhow!("Bifurcation boundary crossed"));
        }

        match inst {
            Instruction::ADD { ty, dst, src1, src2 } => {
                let a = self.registers.read(*src1)?;
                let b = self.registers.read(*src2)?;
                self.registers.write(*dst, a + b, *ty);
                self.pc += 1;
            }
            Instruction::SUB { ty, dst, src1, src2 } => {
                let a = self.registers.read(*src1)?;
                let b = self.registers.read(*src2)?;
                self.registers.write(*dst, a - b, *ty);
                self.pc += 1;
            }
            Instruction::MUL { ty, dst, src1, src2 } => {
                let a = self.registers.read(*src1)?;
                let b = self.registers.read(*src2)?;
                self.registers.write(*dst, a * b, *ty);
                self.pc += 1;
            }
            Instruction::LDG { ty, dst, addr } => {
                match addr {
                    Address::BufferOffset { offset, .. } => {
                        let val = self.memory.get(offset).copied().unwrap_or(0);
                        self.registers.write(*dst, val, *ty);
                    }
                }
                self.pc += 1;
            }
            Instruction::STG { ty, src, addr } => {
                let val = self.registers.read(*src)?;
                match addr {
                    Address::BufferOffset { offset, .. } => {
                        self.memory.insert(*offset, val);
                    }
                }
                self.pc += 1;
            }
            Instruction::BRA { target, pred: _ } => {
                let mut payload = std::collections::HashMap::new();
                payload.insert("type", serde_json::json!("BRA"));
                payload.insert("target", serde_json::to_value(target).unwrap());
                payload.insert("pc", serde_json::to_value(self.pc).unwrap());
                self.audit.append_payload(payload);
                self.pc = target.parse().unwrap_or(self.pc + 1);
            }
            Instruction::CALL { target } => {
                let mut payload = std::collections::HashMap::new();
                payload.insert("type", serde_json::json!("CALL"));
                payload.insert("target", serde_json::to_value(target).unwrap());
                payload.insert("pc", serde_json::to_value(self.pc).unwrap());
                self.audit.append_payload(payload);
                self.pc = target.parse().unwrap_or(self.pc + 1);
            }
            Instruction::MOV { dst, src } => {
                self.registers.write(*dst, *src, Type::U64);
                self.pc += 1;
            }
            Instruction::SETcc { ty: _, dst, src1, src2, cond } => {
                let a = self.registers.read(*src1)?;
                let b = self.registers.read(*src2)?;
                let val = match cond {
                    atlas_isa::Cond::Eq => a == b,
                    atlas_isa::Cond::Ne => a != b,
                    atlas_isa::Cond::Lt => a < b,
                    atlas_isa::Cond::Gt => a > b,
                    atlas_isa::Cond::Le => a <= b,
                    atlas_isa::Cond::Ge => a >= b,
                };
                self.registers.write(Register(dst.0.into()), val as u64, Type::U32);
                self.pc += 1;
            }
            Instruction::EXIT => {
                self.pc = usize::MAX;
            }
        }
        Ok(())
    }
}
