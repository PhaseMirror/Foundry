//! Classical Boolean Logic Module

pub struct ClassicalLogic;

impl ClassicalLogic {
    pub fn not(x: bool) -> bool {
        !x
    }

    pub fn and(x: bool, y: bool) -> bool {
        x && y
    }

    pub fn or(x: bool, y: bool) -> bool {
        x || y
    }

    pub fn implies(x: bool, y: bool) -> bool {
        !x || y
    }
}
