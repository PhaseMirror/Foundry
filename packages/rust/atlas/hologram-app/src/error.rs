use thiserror::Error;

#[derive(Error, Debug, Clone)]
pub enum Error {
    #[error("Model not found: {0}")]
    ModelNotFound(String),

    #[error("Model already exists: {0}")]
    ModelExists(String),

    #[error("Model not running: {0}")]
    ModelNotRunning(String),

    #[error("Failed to download model: {0}")]
    Download(String),

    #[error("Failed to compile model: {0}")]
    Compilation(String),

    #[error("Inference error: {0}")]
    Inference(String),

    #[error("Invalid request: {0}")]
    InvalidRequest(String),

    #[error("Configuration error: {0}")]
    Config(String),

    #[error("IO error: {0}")]
    Io(String),

    #[error("Serialization error: {0}")]
    Json(String),

    #[error("HTTP error: {0}")]
    Http(String),

    #[error("ONNX runtime error: {0}")]
    Onnx(String),
}

pub type Result<T> = std::result::Result<T, Error>;

// Conversion from std::io::Error
impl From<std::io::Error> for Error {
    fn from(err: std::io::Error) -> Self {
        Error::Io(err.to_string())
    }
}

// Conversion from serde_json::Error
impl From<serde_json::Error> for Error {
    fn from(err: serde_json::Error) -> Self {
        Error::Json(err.to_string())
    }
}

// Conversion from reqwest::Error
impl From<reqwest::Error> for Error {
    fn from(err: reqwest::Error) -> Self {
        Error::Http(err.to_string())
    }
}

// Convert to HTTP status codes for API responses
#[cfg(feature = "server")]
impl From<Error> for axum::http::StatusCode {
    fn from(err: Error) -> Self {
        use axum::http::StatusCode;
        match err {
            Error::ModelNotFound(_) => StatusCode::NOT_FOUND,
            Error::ModelExists(_) => StatusCode::CONFLICT,
            Error::ModelNotRunning(_) => StatusCode::BAD_REQUEST,
            Error::InvalidRequest(_) => StatusCode::BAD_REQUEST,
            Error::Config(_) => StatusCode::INTERNAL_SERVER_ERROR,
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }
}

#[cfg(feature = "server")]
impl From<&Error> for axum::http::StatusCode {
    fn from(err: &Error) -> Self {
        use axum::http::StatusCode;
        match err {
            Error::ModelNotFound(_) => StatusCode::NOT_FOUND,
            Error::ModelExists(_) => StatusCode::CONFLICT,
            Error::ModelNotRunning(_) => StatusCode::BAD_REQUEST,
            Error::InvalidRequest(_) => StatusCode::BAD_REQUEST,
            Error::Config(_) => StatusCode::INTERNAL_SERVER_ERROR,
            _ => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }
}
