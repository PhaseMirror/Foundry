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
#[repr(u8)]
pub enum CalculatorError {
    DivisionByZero = 0,
    Overflow = 1,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Request {
    pub operation: crate::Operation,
    pub left: i64,
    pub right: i64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum ProtocolError {
    MalformedRequest = 0,
    UnsupportedVersion = 1,
    UnknownOperation = 2,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum Operation {
    Add = 0,
    Subtract = 1,
    Multiply = 2,
    Divide = 3,
}

pub fn left(__prod_self: crate::Request) -> i64 {
    { let _x_1 = (__prod_self).left; _x_1 }
}

pub fn operation(__prod_self: crate::Request) -> crate::Operation {
    { let _x_1 = (__prod_self).operation; _x_1 }
}

pub fn right(__prod_self: crate::Request) -> i64 {
    { let _x_1 = (__prod_self).right; _x_1 }
}

pub fn calculate(operation: crate::Operation, left: i64, right: i64) -> Result<i64, crate::CalculatorError> {
    match operation {
        crate::Operation::Add => { let _x_121 = (left).checked_add(right); match _x_121 {
        None => { let _x_126 = crate::CalculatorError::Overflow; { let _x_127 = Err(_x_126); _x_127 } },
        Some(val_124) => { let _x_125 = Ok(val_124); _x_125 },
    } },
        crate::Operation::Subtract => { let _x_131 = (left).checked_sub(right); match _x_131 {
        None => { let _x_136 = crate::CalculatorError::Overflow; { let _x_137 = Err(_x_136); _x_137 } },
        Some(val_134) => { let _x_135 = Ok(val_134); _x_135 },
    } },
        crate::Operation::Multiply => { let _x_141 = (left).checked_mul(right); match _x_141 {
        None => { let _x_146 = crate::CalculatorError::Overflow; { let _x_147 = Err(_x_146); _x_147 } },
        Some(val_144) => { let _x_145 = Ok(val_144); _x_145 },
    } },
        crate::Operation::Divide => { let _x_148 = 0; { let _x_149 = 0; { let _x_150 = 0; { let _x_151 = _x_150; { let _x_152 = (right == _x_151); match _x_152 {
        false => { let _x_173 = (left).checked_div(right); match _x_173 {
        None => { let _x_174 = crate::CalculatorError::Overflow; { let _x_175 = Err(_x_174); _x_175 } },
        Some(val_176) => { let _x_177 = Ok(val_176); _x_177 },
    } },
        true => { let _x_178 = crate::CalculatorError::DivisionByZero; { let _x_179 = Err(_x_178); _x_179 } },
    } } } } } },
    }
}

pub fn decodeComplete(version: alloc::string::String, operationText: alloc::string::String, leftText: alloc::string::String, rightText: alloc::string::String) -> Result<crate::Request, crate::ProtocolError> {
    { let _x_1 = 0; { let _x_2 = 0; { let _x_3 = alloc::string::String::from("1"); { let _x_4 = (version == _x_3); match _x_4 {
        false => { let _x_44 = crate::ProtocolError::UnsupportedVersion; { let _x_45 = Err(_x_44); _x_45 } },
        true => { let _x_46 = parseOperation(operationText); match _x_46 {
        Err(a_47) => { let _x_48 = Err(a_47); _x_48 },
        Ok(a_49) => { let _x_50 = decodeLeft(a_49, leftText, rightText); _x_50 },
    } },
    } } } } }
}

pub fn decodeFields(values: &[alloc::string::String]) -> Result<crate::Request, crate::ProtocolError> {
    match values {
        [] => { let _x_17 = crate::ProtocolError::MalformedRequest; { let _x_18 = Err(_x_17); _x_18 } },
        [head_10, tail_11 @ ..] => { let head_10 = head_10.clone(); { let _x_16 = decodeTail1(head_10, &(tail_11)); _x_16 } },
    }
}

pub fn decodeLeft(operation: crate::Operation, leftText: alloc::string::String, rightText: alloc::string::String) -> Result<crate::Request, crate::ProtocolError> {
    { let _x_8 = 0; { let _x_9 = 0; { let _x_10 = 0; { let _x_11 = { let __text = leftText; __text.parse().ok().filter(|__value| alloc::string::ToString::to_string(__value) == __text) }; match _x_11 {
        None => { let _x_20 = crate::ProtocolError::MalformedRequest; { let _x_21 = Err(_x_20); _x_21 } },
        Some(val_14) => { let _x_19 = decodeRight(operation, val_14, rightText); _x_19 },
    } } } } }
}

pub fn decodeRequest(value: alloc::string::String) -> Result<crate::Request, crate::ProtocolError> {
    { let _x_8 = alloc::string::String::from("\t"); { let _x_19 = 4; { let _x_12 = { let __value = value; let __delimiter = _x_8; let __maximum = usize::try_from(_x_19).ok(); if __delimiter.is_empty() { None } else { let __fields: alloc::vec::Vec<alloc::string::String> = __value.split(&__delimiter).map(alloc::string::String::from).collect(); __maximum.filter(|__maximum| __fields.len() <= *__maximum).map(|_| __fields) } }; match _x_12 {
        None => { let _x_23 = crate::ProtocolError::MalformedRequest; { let _x_24 = Err(_x_23); _x_24 } },
        Some(val_15) => { let _x_22 = decodeFields(&(val_15)); _x_22 },
    } } } }
}

pub fn decodeRight(operation: crate::Operation, left: i64, rightText: alloc::string::String) -> Result<crate::Request, crate::ProtocolError> {
    { let _x_9 = 0; { let _x_10 = 0; { let _x_11 = 0; { let _x_12 = { let __text = rightText; __text.parse().ok().filter(|__value| alloc::string::ToString::to_string(__value) == __text) }; match _x_12 {
        None => { let _x_20 = crate::ProtocolError::MalformedRequest; { let _x_21 = Err(_x_20); _x_21 } },
        Some(val_15) => { let _x_22 = crate::Request { operation: operation, left: left, right: val_15 }; { let _x_23 = Ok(_x_22); _x_23 } },
    } } } } }
}

pub fn decodeTail1(version: alloc::string::String, values: &[alloc::string::String]) -> Result<crate::Request, crate::ProtocolError> {
    match values {
        [] => { let _x_17 = crate::ProtocolError::MalformedRequest; { let _x_18 = Err(_x_17); _x_18 } },
        [head_10, tail_11 @ ..] => { let head_10 = head_10.clone(); { let _x_16 = decodeTail2(version, head_10, &(tail_11)); _x_16 } },
    }
}

pub fn decodeTail2(version: alloc::string::String, operationText: alloc::string::String, values: &[alloc::string::String]) -> Result<crate::Request, crate::ProtocolError> {
    match values {
        [] => { let _x_17 = crate::ProtocolError::MalformedRequest; { let _x_18 = Err(_x_17); _x_18 } },
        [head_10, tail_11 @ ..] => { let head_10 = head_10.clone(); { let _x_16 = decodeTail3(version, operationText, head_10, &(tail_11)); _x_16 } },
    }
}

pub fn decodeTail3(version: alloc::string::String, operationText: alloc::string::String, leftText: alloc::string::String, values: &[alloc::string::String]) -> Result<crate::Request, crate::ProtocolError> {
    match values {
        [] => { let _x_17 = crate::ProtocolError::MalformedRequest; { let _x_18 = Err(_x_17); _x_18 } },
        [head_10, tail_11 @ ..] => { let head_10 = head_10.clone(); { let _x_16 = decodeTail4(version, operationText, leftText, head_10, &(tail_11)); _x_16 } },
    }
}

pub fn decodeTail4(version: alloc::string::String, operationText: alloc::string::String, leftText: alloc::string::String, rightText: alloc::string::String, values: &[alloc::string::String]) -> Result<crate::Request, crate::ProtocolError> {
    match values {
        [] => { let _x_18 = decodeComplete(version, operationText, leftText, rightText); _x_18 },
        [head_12, tail_13 @ ..] => { let head_12 = head_12.clone(); { let _x_19 = crate::ProtocolError::MalformedRequest; { let _x_20 = Err(_x_19); _x_20 } } },
    }
}

pub fn dispatchBytes(value: alloc::vec::Vec<u8>) -> alloc::vec::Vec<u8> {
    { let _x_9 = alloc::string::String::from_utf8(value).ok(); match _x_9 {
        None => { let _x_17 = alloc::string::String::from("1\terror\tmalformed-request"); { let _x_18 = (_x_17).into_bytes(); _x_18 } },
        Some(val_12) => { let _x_19 = dispatchString(val_12); { let _x_20 = (_x_19).into_bytes(); _x_20 } },
    } }
}

pub fn dispatchString(value: alloc::string::String) -> alloc::string::String {
    { let _x_11 = decodeRequest(value); match _x_11 {
        Err(a_12) => { let _x_18 = encodeProtocolError(a_12); _x_18 },
        Ok(a_14) => { let _x_19 = (a_14).operation; { let _x_20 = (a_14).left; { let _x_21 = (a_14).right; { let _x_22 = calculate(_x_19, _x_20, _x_21); { let _x_23 = encodeCalculationResult(_x_22); _x_23 } } } } },
    } }
}

pub fn encodeCalculationResult(value: Result<i64, crate::CalculatorError>) -> alloc::string::String {
    match value {
        Err(a_26) => match a_26 {
        crate::CalculatorError::DivisionByZero => { let _x_37 = alloc::string::String::from("1\terror\tdivision-by-zero"); _x_37 },
        crate::CalculatorError::Overflow => { let _x_39 = alloc::string::String::from("1\terror\toverflow"); _x_39 },
    },
        Ok(a_28) => { let _x_40 = alloc::string::String::from("1\tok\t"); { let _x_41 = 0; { let _x_42 = 0; { let _x_43 = 0; { let _x_44 = alloc::format!("{}", a_28); { let _x_45 = alloc::vec::Vec::new(); { let _x_46 = { let mut __list = alloc::vec![_x_44]; __list.extend(_x_45); __list }; { let _x_47 = { let mut __list = alloc::vec![_x_40]; __list.extend(_x_46); __list }; { let _x_48 = alloc::string::String::from(""); { let _x_49 = (_x_47).join(&_x_48); _x_49 } } } } } } } } } },
    }
}

pub fn encodeProtocolError(error: crate::ProtocolError) -> alloc::string::String {
    match error {
        crate::ProtocolError::MalformedRequest => { let _x_19 = alloc::string::String::from("1\terror\tmalformed-request"); _x_19 },
        crate::ProtocolError::UnsupportedVersion => { let _x_21 = alloc::string::String::from("1\terror\tunsupported-version"); _x_21 },
        crate::ProtocolError::UnknownOperation => { let _x_23 = alloc::string::String::from("1\terror\tunknown-operation"); _x_23 },
    }
}

pub fn parseOperation(value: alloc::string::String) -> Result<crate::Operation, crate::ProtocolError> {
    { let _x_1 = 0; { let _x_2 = 0; { let _x_3 = alloc::string::String::from("add"); { let _x_4 = (value == _x_3); match _x_4 {
        false => { let _x_179 = alloc::string::String::from("subtract"); { let _x_180 = (value == _x_179); match _x_180 {
        false => { let _x_199 = alloc::string::String::from("multiply"); { let _x_200 = (value == _x_199); match _x_200 {
        false => { let _x_213 = alloc::string::String::from("divide"); { let _x_214 = (value == _x_213); match _x_214 {
        false => { let _x_221 = crate::ProtocolError::UnknownOperation; { let _x_222 = Err(_x_221); _x_222 } },
        true => { let _x_223 = crate::Operation::Divide; { let _x_224 = Ok(_x_223); _x_224 } },
    } } },
        true => { let _x_225 = crate::Operation::Multiply; { let _x_226 = Ok(_x_225); _x_226 } },
    } } },
        true => { let _x_227 = crate::Operation::Subtract; { let _x_228 = Ok(_x_227); _x_228 } },
    } } },
        true => { let _x_229 = crate::Operation::Add; { let _x_230 = Ok(_x_229); _x_230 } },
    } } } } }
}

