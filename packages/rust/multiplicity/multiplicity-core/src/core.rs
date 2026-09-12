pub fn nat_sub_self(n: u32) -> u32 {
    n - n
}

pub fn nat_zero_le(_a: u32) -> bool {
    true
}

pub fn nat_zero_lt_one() -> bool {
    0 < 1
}

pub fn nat_le_of_lt(a: u32, b: u32) -> bool {
    a < b
}

pub fn nat_add_comm(a: u32, b: u32) -> u32 {
    a + b
}

pub fn nat_add_assoc(a: u32, b: u32, c: u32) -> u32 {
    (a + b) + c
}

pub fn nat_add_le_add_left(a: u32, b: u32, c: u32) -> bool {
    c + a <= c + b
}

pub fn nat_add_le_add_right(a: u32, b: u32, c: u32) -> bool {
    a + c <= b + c
}

pub fn nat_le_trans(a: u32, b: u32, c: u32) -> bool {
    a <= b && b <= c
}

pub fn nat_antisymm(a: u32, b: u32) -> bool {
    a <= b && b <= a
}

pub fn nat_min_comm(a: u32, b: u32) -> u32 {
    a.min(b)
}

pub fn nat_min_le_left(a: u32, b: u32) -> bool {
    a.min(b) <= a
}

pub fn nat_min_le_right(a: u32, b: u32) -> bool {
    a.min(b) <= b
}

pub fn nat_max_comm(a: u32, b: u32) -> u32 {
    a.max(b)
}

pub fn nat_le_max_left(a: u32, b: u32) -> bool {
    a <= a.max(b)
}

pub fn nat_le_max_right(a: u32, b: u32) -> bool {
    b <= a.max(b)
}

pub fn nat_sub_self_add(a: u32, b: u32) -> u32 {
    (a - b) + b
}

pub fn nat_add_sub_cancel(a: u32, b: u32) -> u32 {
    a + (b - a)
}

pub fn nat_sub_nonneg(_a: u32, _b: u32) -> bool {
    true
}
