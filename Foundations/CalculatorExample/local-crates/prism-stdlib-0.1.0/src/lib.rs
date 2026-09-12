#![cfg_attr(not(feature = "std"), no_std)]
#![allow(dead_code, non_snake_case, unused_parens, unused_variables)]
extern crate alloc;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ComputeError {
    AddOverflow,
    MulOverflow,
    ShiftExponentTooLarge,
    ShiftOverflow,
    PowExponentTooLarge,
    PowOverflow,
    OutputTooSmall,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct StandardsProfile {
    pub architectureEdition: u64,
    pub applicationSecurityEdition: u64,
    pub controlEdition: u64,
    pub riskEdition: u64,
    pub qualityEdition: u64,
}

pub fn appendBytes(left: alloc::vec::Vec<u8>, right: alloc::vec::Vec<u8>) -> alloc::vec::Vec<u8> {
    { let _x_1 = 0; { let _x_2 = { let mut __value = left; __value.extend_from_slice(&right); __value }; _x_2 } }
}

pub fn byteAt(value: alloc::vec::Vec<u8>, offset: u64) -> Option<u8> {
    { let _x_1 = 0; { let _x_2 = usize::try_from(offset).ok().and_then(|__index| (value).get(__index).cloned()); _x_2 } }
}

pub fn byteLength(value: alloc::vec::Vec<u8>) -> u64 {
    { let _x_1 = 0; { let _x_2 = (value).len() as u64; _x_2 } }
}

pub fn compareBytes(left: alloc::vec::Vec<u8>, right: alloc::vec::Vec<u8>) -> core::cmp::Ordering {
    { let _x_1 = (left).cmp(&right); _x_1 }
}

pub fn sliceBytes(value: alloc::vec::Vec<u8>, start: u64, count: u64) -> Option<alloc::vec::Vec<u8>> {
    { let _x_1 = 0; { let _x_2 = { let __start = usize::try_from(start).ok(); let __count = usize::try_from(count).ok(); match (__start, __count) { (Some(__start), Some(__count)) => __start.checked_add(__count).and_then(|__end| (value).get(__start..__end).map(|__slice| __slice.to_vec())), _ => None } }; _x_2 } }
}

pub fn formatInt64(value: i64) -> alloc::string::String {
    { let _x_1 = 0; { let _x_2 = 0; { let _x_3 = 0; { let _x_4 = alloc::format!("{}", value); _x_4 } } } }
}

pub fn parseInt64(value: alloc::string::String) -> Option<i64> {
    { let _x_1 = 0; { let _x_2 = 0; { let _x_3 = 0; { let _x_4 = { let __text = value; __text.parse().ok().filter(|__value| alloc::string::ToString::to_string(__value) == __text) }; _x_4 } } } }
}

pub fn portableTrue() -> bool {
    { let _x_1 = true; _x_1 }
}

pub fn applicationSecurityEdition(__prod_self: crate::StandardsProfile) -> u64 {
    { let _x_1 = (__prod_self).applicationSecurityEdition; _x_1 }
}

pub fn architectureEdition(__prod_self: crate::StandardsProfile) -> u64 {
    { let _x_1 = (__prod_self).architectureEdition; _x_1 }
}

pub fn controlEdition(__prod_self: crate::StandardsProfile) -> u64 {
    { let _x_1 = (__prod_self).controlEdition; _x_1 }
}

pub fn qualityEdition(__prod_self: crate::StandardsProfile) -> u64 {
    { let _x_1 = (__prod_self).qualityEdition; _x_1 }
}

pub fn riskEdition(__prod_self: crate::StandardsProfile) -> u64 {
    { let _x_1 = (__prod_self).riskEdition; _x_1 }
}

pub fn allBelow(x_1: u64, x_2: &[u64]) -> bool {
    match x_2 {
        [] => { let _x_30 = true; _x_30 },
        [head_21, tail_22 @ ..] => { let head_21 = head_21.clone(); { let _x_31 = (head_21 < x_1); match _x_31 {
        false => _x_31,
        true => { let _x_34 = allBelow(x_1, &(tail_22)); _x_34 },
    } } },
    }
}

pub fn allConsecutive(x_1: u64, x_2: &[u64]) -> Result<bool, crate::ComputeError> {
    Ok(match x_2 {
        [] => { let _x_45 = true; _x_45 },
        [head_28, tail_29 @ ..] => { let head_28 = head_28.clone(); { let _x_50 = (x_1 == head_28); match _x_50 {
        false => _x_50,
        true => { let _x_54 = 1; { let _x_55 = ((x_1) as u64).checked_add(_x_54).ok_or(crate::ComputeError::AddOverflow)?; { let _x_56 = allConsecutive(_x_55, &(tail_29))?; _x_56 } } },
    } } },
    })
}

pub fn canonicalIndexes(x_1: u64, x_2: u64, output: &mut [u64]) -> Result<usize, crate::ComputeError> {
    match x_2 {
        0 => Ok::<usize, crate::ComputeError>(0),
        _ => { let n_18 = (x_2).saturating_sub(1); { let _x_32 = 1; { let _x_33 = ((x_1) as u64).checked_add(_x_32).ok_or(crate::ComputeError::AddOverflow)?; match (output).split_first_mut() { None => Err(crate::ComputeError::OutputTooSmall), Some((__head0, __rest0)) => { *__head0 = x_1; let __len0 = canonicalIndexes(_x_33, n_18, __rest0)?; Ok(__len0 + 1) } } } } },
    }
}

pub fn validateComponentIndexes(values: &[u64]) -> Result<bool, crate::ComputeError> {
    Ok({ let _x_1 = 0; { let _x_4 = allConsecutive(_x_1, &(values))?; _x_4 } })
}

pub fn validateControlLinks(riskCount: u64, links: &[u64]) -> bool {
    { let _x_1 = allBelow(riskCount, &(links)); _x_1 }
}

pub fn validateEdgeEndpoints(componentCount: u64, endpoints: &[u64]) -> bool {
    { let _x_1 = allBelow(componentCount, &(endpoints)); _x_1 }
}

pub fn validateExactStandardsProfile(profile: crate::StandardsProfile) -> bool {
    { let _x_50 = (profile).architectureEdition; { let _x_51 = 2022; { let _x_54 = (_x_50 == _x_51); match _x_54 {
        false => _x_54,
        true => { let _x_96 = (profile).applicationSecurityEdition; { let _x_97 = 2011; { let _x_98 = (_x_96 == _x_97); match _x_98 {
        false => _x_98,
        true => { let _x_113 = (profile).controlEdition; { let _x_114 = 2017; { let _x_115 = (_x_113 == _x_114); match _x_115 {
        false => _x_115,
        true => { let _x_123 = (profile).riskEdition; { let _x_124 = 2022; { let _x_125 = (_x_123 == _x_124); match _x_125 {
        false => _x_125,
        true => { let _x_129 = (profile).qualityEdition; { let _x_130 = 2023; { let _x_131 = (_x_129 == _x_130); _x_131 } } },
    } } } },
    } } } },
    } } } },
    } } } }
}

pub fn validateFlattenedBounds(bound: u64, indexes: &[u64]) -> bool {
    { let _x_1 = allBelow(bound, &(indexes)); _x_1 }
}

pub fn validateQualityLinks(targetCount: u64, links: &[u64]) -> bool {
    { let _x_1 = allBelow(targetCount, &(links)); _x_1 }
}

pub fn validateRiskLinks(assetOrThreatCount: u64, links: &[u64]) -> bool {
    { let _x_1 = allBelow(assetOrThreatCount, &(links)); _x_1 }
}

pub fn validateViewpointLinks(targetCount: u64, links: &[u64]) -> bool {
    { let _x_1 = allBelow(targetCount, &(links)); _x_1 }
}

pub fn checkedAddInt64(left: i64, right: i64) -> Option<i64> {
    { let _x_1 = (left).checked_add(right); _x_1 }
}

pub fn checkedDivideInt64(left: i64, right: i64) -> Option<i64> {
    { let _x_1 = (left).checked_div(right); _x_1 }
}

pub fn checkedMultiplyInt64(left: i64, right: i64) -> Option<i64> {
    { let _x_1 = (left).checked_mul(right); _x_1 }
}

pub fn checkedNegateInt64(value: i64) -> Option<i64> {
    { let _x_1 = (value).checked_neg(); _x_1 }
}

pub fn checkedSubtractInt64(left: i64, right: i64) -> Option<i64> {
    { let _x_1 = (left).checked_sub(right); _x_1 }
}

pub fn decode(value: alloc::vec::Vec<u8>) -> Option<alloc::string::String> {
    { let _x_1 = alloc::string::String::from_utf8(value).ok(); _x_1 }
}

pub fn encode(value: alloc::string::String) -> alloc::vec::Vec<u8> {
    { let _x_1 = (value).into_bytes(); _x_1 }
}
