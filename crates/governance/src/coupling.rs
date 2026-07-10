#![cfg(feature = "coupling")]
use redis::{AsyncCommands, Client, RedisResult};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::time::{SystemTime, UNIX_EPOCH};

pub const STREAM_PREFIX: &str = "pm:stream:";
pub const RATE_KEY_PREFIX: &str = "pm:rate:";

pub struct RedisCoupling {
    client: Client,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CouplingMessage {
    pub id: String,
    pub agent_id: String,
    pub payload: Value,
    pub ts: String,
}

impl RedisCoupling {
    pub fn new(redis_url: &str) -> RedisResult<Self> {
        let client = Client::open(redis_url)?;
        Ok(Self { client })
    }

    pub async fn ping(&self) -> bool {
        let mut conn = match self.client.get_multiplexed_async_connection().await {
            Ok(c) => c,
            Err(_) => return false,
        };
        let res: RedisResult<String> = redis::cmd("PING").query_async(&mut conn).await;
        res.is_ok()
    }

    pub async fn publish(
        &self,
        agent_id: &str,
        topic: &str,
        payload: &Value,
        maxlen: usize,
    ) -> RedisResult<String> {
        let mut conn = self.client.get_multiplexed_async_connection().await?;
        let stream_key = format!("{}{}", STREAM_PREFIX, topic);
        let ts = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64();
        
        let entry = [
            ("agent_id", agent_id.to_string()),
            ("payload", serde_json::to_string(payload).unwrap()),
            ("ts", ts.to_string()),
        ];

        let entry_id: String = redis::cmd("XADD")
            .arg(&stream_key)
            .arg("MAXLEN")
            .arg("~")
            .arg(maxlen)
            .arg("*")
            .arg(&entry)
            .query_async(&mut conn)
            .await?;

        Ok(entry_id)
    }

    pub async fn check_rate(
        &self,
        agent_id: &str,
        topic: &str,
        window_seconds: u64,
        max_count: usize,
    ) -> RedisResult<(bool, usize)> {
        let mut conn = self.client.get_multiplexed_async_connection().await?;
        let rate_key = format!("{}{}:{}", RATE_KEY_PREFIX, agent_id, topic);
        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64();
        let window_start = now - window_seconds as f64;

        // Use a pipeline for performance
        let _: () = redis::pipe()
            .atomic()
            .cmd("ZREMRANGEBYSCORE").arg(&rate_key).arg("-inf").arg(window_start)
            .cmd("ZADD").arg(&rate_key).arg(now).arg(now.to_string())
            .cmd("ZCARD").arg(&rate_key)
            .cmd("EXPIRE").arg(&rate_key).arg(window_seconds * 2)
            .query_async(&mut conn)
            .await?;

        let current_count: usize = conn.zcard(&rate_key).await?;
        let allowed = current_count <= max_count;

        Ok((allowed, current_count))
    }
}
