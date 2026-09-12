pub mod multiframe;

pub use multiframe::*;

#[cfg(test)]
mod tests {
    use super::*;
    use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine};

    #[test]
    fn test_aggregator() {
        let mut agg = Aggregator::new();
        
        let bundle = "bundle123".to_string();
        let payload = b"hello world".to_vec();
        let payload_crc = format!("{:08x}", super::multiframe::crc32(&payload));
        
        let frame1 = Frame {
            ver: "LP2".to_string(),
            kind: "share".to_string(),
            bundle: bundle.clone(),
            seq: 0,
            total: 2,
            data_b64: URL_SAFE_NO_PAD.encode(&payload[0..5]),
            chunk_crc32: format!("{:08x}", super::multiframe::crc32(&payload[0..5])),
            payload_crc32: payload_crc.clone(),
        };

        let frame2 = Frame {
            ver: "LP2".to_string(),
            kind: "share".to_string(),
            bundle: bundle.clone(),
            seq: 1,
            total: 2,
            data_b64: URL_SAFE_NO_PAD.encode(&payload[5..]),
            chunk_crc32: format!("{:08x}", super::multiframe::crc32(&payload[5..])),
            payload_crc32: payload_crc.clone(),
        };

        agg.add(frame1).unwrap();
        assert!(!agg.complete(&bundle, &payload_crc));
        
        agg.add(frame2).unwrap();
        assert!(agg.complete(&bundle, &payload_crc));
        
        let assembled = agg.assemble(&bundle, &payload_crc).unwrap();
        assert_eq!(assembled, payload);
    }
}
