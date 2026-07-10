use async_trait::async_trait;
use tokio_tungstenite::tungstenite::protocol::Message;
use tokio_tungstenite::{connect_async, MaybeTlsStream, WebSocketStream};
use futures_util::{SinkExt, StreamExt};
use crate::transport::base::{Transport, TransportConfig, TransportState};

pub struct WebSocketTransport {
    config: TransportConfig,
    state: TransportState,
    stream: Option<WebSocketStream<MaybeTlsStream<tokio::net::TcpStream>>>,
}

impl WebSocketTransport {
    pub fn new(config: TransportConfig) -> Self {
        Self {
            config,
            state: TransportState::Disconnected,
            stream: None,
        }
    }
}

#[async_trait]
impl Transport for WebSocketTransport {
    fn state(&self) -> TransportState {
        self.state
    }

    async fn connect(&mut self) -> anyhow::Result<()> {
        self.state = TransportState::Connecting;
        let url = format!("ws://{}:{}", self.config.host, self.config.port);
        let (stream, _) = connect_async(url).await?;
        self.stream = Some(stream);
        self.state = TransportState::Connected;
        Ok(())
    }

    async fn disconnect(&mut self) -> anyhow::Result<()> {
        if let Some(mut stream) = self.stream.take() {
            stream.close(None).await?;
        }
        self.state = TransportState::Disconnected;
        Ok(())
    }

    async fn send(&mut self, _topic: &str, payload: serde_json::Value) -> anyhow::Result<()> {
        if let Some(ref mut stream) = self.stream {
            let msg = Message::Text(payload.to_string().into());
            stream.send(msg).await?;
            return Ok(());
        }
        Err(anyhow::anyhow!("Not connected"))
    }

    async fn receive(&mut self, _timeout: Option<std::time::Duration>) -> anyhow::Result<serde_json::Value> {
        if let Some(ref mut stream) = self.stream {
            while let Some(msg) = stream.next().await {
                let msg = msg?;
                if msg.is_text() {
                    let text = msg.to_text()?;
                    return Ok(serde_json::from_str(text)?);
                }
            }
        }
        Err(anyhow::anyhow!("Not connected or closed"))
    }
}
