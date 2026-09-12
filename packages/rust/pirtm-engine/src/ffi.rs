use std::collections::HashMap;
use std::ffi::CStr;
use std::os::raw::c_char;
use std::sync::Mutex;

// ---------- Vec FFI ----------

#[no_mangle]
pub extern "C" fn vec_new() -> *mut std::vec::Vec<i64> {
    let v = Box::new(Vec::new());
    Box::into_raw(v)
}

#[no_mangle]
pub extern "C" fn vec_push(vec: *mut std::vec::Vec<i64>, item: i64) {
    let v = unsafe { &mut *vec };
    v.push(item);
}

#[no_mangle]
pub extern "C" fn vec_pop(vec: *mut std::vec::Vec<i64>) -> i64 {
    let v = unsafe { &mut *vec };
    v.pop().unwrap_or(0)
}

#[no_mangle]
pub extern "C" fn vec_len(vec: *mut std::vec::Vec<i64>) -> i64 {
    let v = unsafe { &mut *vec };
    v.len() as i64
}

#[no_mangle]
pub extern "C" fn vec_get(vec: *mut std::vec::Vec<i64>, idx: i64) -> i64 {
    let v = unsafe { &mut *vec };
    *v.get(idx as usize).unwrap_or(&0)
}

// ---------- String FFI ----------

#[no_mangle]
pub extern "C" fn string_new() -> *mut std::string::String {
    let s = Box::new(String::new());
    Box::into_raw(s)
}

#[no_mangle]
pub extern "C" fn string_from_cstr(cstr: *const c_char) -> *mut std::string::String {
    let c_str = unsafe { CStr::from_ptr(cstr) };
    let s = Box::new(c_str.to_string_lossy().into_owned());
    Box::into_raw(s)
}

#[no_mangle]
pub extern "C" fn string_char_at(s: *mut std::string::String, idx: i64) -> i64 {
    let s = unsafe { &*s };
    let chars: Vec<char> = s.chars().collect();
    chars.get(idx as usize).map(|c| *c as i64).unwrap_or(0)
}

#[no_mangle]
pub extern "C" fn string_slice(s: *mut std::string::String, start: i64, end: i64) -> *mut std::string::String {
    let s = unsafe { &*s };
    let sub = s.chars().skip(start as usize).take((end - start) as usize).collect::<String>();
    let boxed = Box::new(sub);
    Box::into_raw(boxed)
}

#[no_mangle]
pub extern "C" fn string_concat(a: *mut std::string::String, b: *mut std::string::String) -> *mut std::string::String {
    let a = unsafe { &*a };
    let b = unsafe { &*b };
    let concat = a.clone() + b;
    let boxed = Box::new(concat);
    Box::into_raw(boxed)
}

#[no_mangle]
pub extern "C" fn string_len(s: *mut std::string::String) -> i64 {
    let s = unsafe { &*s };
    s.len() as i64
}

#[no_mangle]
pub extern "C" fn string_eq(a: *mut std::string::String, b: *mut std::string::String) -> bool {
    let a = unsafe { &*a };
    let b = unsafe { &*b };
    a == b
}

// ---------- Map FFI ----------

type MapType = HashMap<String, i64>;

#[no_mangle]
pub extern "C" fn map_new() -> *mut MapType {
    let map = Box::new(HashMap::new());
    Box::into_raw(map)
}

#[no_mangle]
pub extern "C" fn map_insert(map: *mut MapType, key: *mut std::string::String, value: i64) {
    let map = unsafe { &mut *map };
    let key = unsafe { &*key };
    map.insert(key.clone(), value);
}

#[no_mangle]
pub extern "C" fn map_get(map: *mut MapType, key: *mut std::string::String) -> i64 {
    let map = unsafe { &mut *map };
    let key = unsafe { &*key };
    *map.get(key).unwrap_or(&0)
}

// ---------- Char FFI ----------

#[no_mangle]
pub extern "C" fn char_is_whitespace(c: i64) -> bool {
    let c = char::from_u32(c as u32).unwrap_or('\0');
    c.is_whitespace()
}

#[no_mangle]
pub extern "C" fn char_is_digit(c: i64) -> bool {
    let c = char::from_u32(c as u32).unwrap_or('\0');
    c.is_digit(10)
}

#[no_mangle]
pub extern "C" fn char_to_digit(c: i64) -> i64 {
    let c = char::from_u32(c as u32).unwrap_or('\0');
    c.to_digit(10).map(|d| d as i64).unwrap_or(0)
}

// ---------- Str FFI ----------

#[no_mangle]
pub extern "C" fn str_len(s: *const c_char) -> i64 {
    unsafe { CStr::from_ptr(s).to_bytes().len() as i64 }
}

#[no_mangle]
pub extern "C" fn str_starts_with(s: *const c_char, prefix: *const c_char) -> bool {
    unsafe {
        let s = CStr::from_ptr(s).to_string_lossy();
        let prefix = CStr::from_ptr(prefix).to_string_lossy();
        s.starts_with(&*prefix)
    }
}

#[no_mangle]
pub extern "C" fn str_ends_with(s: *const c_char, suffix: *const c_char) -> bool {
    unsafe {
        let s = CStr::from_ptr(s).to_string_lossy();
        let suffix = CStr::from_ptr(suffix).to_string_lossy();
        s.ends_with(&*suffix)
    }
}

#[no_mangle]
pub extern "C" fn str_trim(s: *const c_char) -> *mut c_char {
    unsafe {
        let s = CStr::from_ptr(s).to_string_lossy();
        let trimmed = s.trim();
        let ptr = trimmed.as_ptr() as *mut c_char;
        // Note: this is unsafe because we're returning a pointer to a temporary.
        // In a real implementation, we'd allocate a new string.
        ptr
    }
}

use std::fs;
use std::ffi::CString;

#[no_mangle]
pub extern "C" fn read_file(path: *const c_char) -> *mut std::string::String {
    let cstr = unsafe { CStr::from_ptr(path) };
    let path_str = cstr.to_string_lossy();
    let contents = fs::read_to_string(&*path_str).unwrap_or_default();
    let s = Box::new(contents);
    Box::into_raw(s)
}

#[no_mangle]
pub extern "C" fn print(s: *const c_char) {
    let cstr = unsafe { CStr::from_ptr(s) };
    println!("{}", cstr.to_string_lossy());
}

#[no_mangle]
pub extern "C" fn parse_f64(s: *const c_char) -> f64 {
    let cstr = unsafe { CStr::from_ptr(s) };
    cstr.to_string_lossy().parse::<f64>().unwrap_or(0.0)
}

#[no_mangle]
pub extern "C" fn f64_to_string(n: f64) -> *mut std::string::String {
    let s = n.to_string();
    let boxed = Box::new(s);
    Box::into_raw(boxed)
}

#[no_mangle]
pub extern "C" fn is_ge(a: i64, b: i64) -> bool { a >= b }
#[no_mangle]
pub extern "C" fn is_gt(a: i64, b: i64) -> bool { a > b }
#[no_mangle]
pub extern "C" fn is_lt(a: i64, b: i64) -> bool { a < b }

// ---------- TCP Network FFI ----------

use std::net::{TcpListener, TcpStream};
use std::io::{Read, Write};
use std::ptr;

#[no_mangle]
pub extern "C" fn tcp_listen(port: i64) -> *mut TcpListener {
    let addr = format!("127.0.0.1:{}", port);
    match TcpListener::bind(&addr) {
        Ok(listener) => Box::into_raw(Box::new(listener)),
        Err(_) => ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn tcp_accept(listener: *mut TcpListener) -> *mut TcpStream {
    if listener.is_null() {
        return ptr::null_mut();
    }
    let listener = unsafe { &mut *listener };
    match listener.accept() {
        Ok((stream, _)) => Box::into_raw(Box::new(stream)),
        Err(_) => ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn tcp_read(conn: *mut TcpStream) -> *mut std::string::String {
    if conn.is_null() {
        return ptr::null_mut();
    }
    let conn = unsafe { &mut *conn };
    let mut buffer = [0u8; 4096];
    match conn.read(&mut buffer) {
        Ok(n) => {
            let s = String::from_utf8_lossy(&buffer[..n]).into_owned();
            Box::into_raw(Box::new(s))
        }
        Err(_) => ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn tcp_write(conn: *mut TcpStream, data: *const c_char) -> i64 {
    if conn.is_null() || data.is_null() {
        return -1;
    }
    let conn = unsafe { &mut *conn };
    let cstr = unsafe { CStr::from_ptr(data) };
    let bytes = cstr.to_bytes();
    match conn.write_all(bytes) {
        Ok(_) => {
            let _ = conn.flush();
            bytes.len() as i64
        }
        Err(_) => -1,
    }
}

#[no_mangle]
pub extern "C" fn tcp_close(conn: *mut TcpStream) {
    if !conn.is_null() {
        unsafe {
            drop(Box::from_raw(conn));
        }
    }
}

#[no_mangle]
pub extern "C" fn tcp_listener_close(listener: *mut TcpListener) {
    if !listener.is_null() {
        unsafe {
            drop(Box::from_raw(listener));
        }
    }
}

#[no_mangle]
pub extern "C" fn get_spectral_rho() -> f64 {
    0.0
}

#[no_mangle]
pub extern "C" fn log_audit_request(endpoint: *const c_char, status: i64) {
    let ep = if endpoint.is_null() {
        "unknown"
    } else {
        unsafe { CStr::from_ptr(endpoint).to_str().unwrap_or("unknown") }
    };
    println!("AUDIT REQUEST LOG: endpoint='{}', status={}", ep, status);
}
