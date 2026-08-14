#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Transform {
    Rotate,   // R
    Triality, // D
    Twist,    // T
}

pub struct ClassSystem;

impl ClassSystem {
    /// Decodes a canonical byte into its constituent resonance components.
    pub fn decode_byte_to_components(byte: u8) -> (u8, u8, u8) {
        let c1 = (byte >> 6) & 0x03;
        let c2 = (byte >> 3) & 0x07;
        let c3 = byte & 0x07;
        (c1, c2, c3)
    }

    /// Encodes component triplets back into a canonical byte.
    pub fn encode_components_to_byte(c1: u8, c2: u8, c3: u8) -> u8 {
        ((c1 & 0x03) << 6) | ((c2 & 0x07) << 3) | (c3 & 0x07)
    }

    /// Applies constitutional transforms (R, T, D) to a resonance byte.
    pub fn apply_transform(byte: u8, transform: Transform) -> u8 {
        let (c1, c2, c3) = Self::decode_byte_to_components(byte);
        match transform {
            Transform::Rotate => Self::encode_components_to_byte(c1, c3, c2),
            Transform::Triality => Self::encode_components_to_byte(c3, c1, c2),
            Transform::Twist => Self::encode_components_to_byte(c2, c1, c3),
        }
    }

    /// Computes the linear address for a given class/page/byte coordinate.
    pub fn compute_belt_address(class_index: u8, page: u8, byte: u8) -> u64 {
        const CLASS_STRIDE: u64 = 12288;
        (class_index as u64 * CLASS_STRIDE) + (page as u64 * 256) + (byte as u64)
    }
}
