use pirtm_engine::ffi::*;
use std::ffi::{CStr, CString};
use std::io::{Read, Write};
use std::net::TcpStream;
use std::thread;
use std::time::Duration;

#[test]
fn test_tcp_ffi_socket_lifecycle() {
    // 1. Start listener on port 19898
    let listener = tcp_listen(19898);
    assert!(!listener.is_null(), "Listener should successfully bind");

    // 2. Spawn a client thread to connect and send request
    let client_handle = thread::spawn(|| {
        thread::sleep(Duration::from_millis(50));
        let mut stream = TcpStream::connect("127.0.0.1:19898").expect("Client connect failed");
        stream.write_all(b"GET /status HTTP/1.1\r\n\r\n").expect("Client write failed");
        
        let mut response = Vec::new();
        stream.read_to_end(&mut response).expect("Client read failed");
        String::from_utf8_lossy(&response).to_string()
    });

    // 3. Accept connection on server side
    let conn = tcp_accept(listener);
    assert!(!conn.is_null(), "Connection should be accepted");

    // 4. Read request
    let req_ptr = tcp_read(conn);
    assert!(!req_ptr.is_null());
    let req_str = unsafe { &*req_ptr };
    assert!(req_str.contains("GET /status"));

    // 5. Write response
    let resp_cstr = CString::new("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"UP\"}").unwrap();
    let written = tcp_write(conn, resp_cstr.as_ptr());
    assert!(written > 0);

    // 6. Close connection and listener
    tcp_close(conn);
    tcp_listener_close(listener);

    // 7. Verify client received the response
    let client_resp = client_handle.join().expect("Client thread panicked");
    assert!(client_resp.contains("HTTP/1.1 200 OK"));
    assert!(client_resp.contains("{\"status\":\"UP\"}"));
}
