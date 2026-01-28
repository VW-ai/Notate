use serde::Serialize;

/// Unified error code enum for all application errors
#[derive(Debug, Clone, Serialize, PartialEq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ErrorCode {
    // Capture errors
    ContentTooLong,
    InvalidCaptureType,
    InvalidSourceUrl,
    CaptureNotFound,

    // Database errors
    DatabaseError,
    MigrationFailed,

    // Storage errors
    DirectoryCreateFailed,
    FileNotFound,
    FileTooLarge,

    // Config errors
    ConfigLoadFailed,
    ConfigValidationFailed,

    // General errors
    InternalError,
    ValidationError,
}

/// Unified application error structure for IPC responses
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AppError {
    pub code: ErrorCode,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub field: Option<String>,
}

impl AppError {
    pub fn new(code: ErrorCode, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
            field: None,
        }
    }

    pub fn with_field(
        code: ErrorCode,
        message: impl Into<String>,
        field: impl Into<String>,
    ) -> Self {
        Self {
            code,
            message: message.into(),
            field: Some(field.into()),
        }
    }

    // Capture validation errors
    pub fn content_too_long(max_length: usize, actual_length: usize) -> Self {
        Self::with_field(
            ErrorCode::ContentTooLong,
            format!(
                "Content exceeds maximum length of {} characters (got {})",
                max_length, actual_length
            ),
            "content",
        )
    }

    pub fn invalid_capture_type(type_value: &str) -> Self {
        Self::with_field(
            ErrorCode::InvalidCaptureType,
            format!(
                "Invalid capture type: '{}'. Must be one of: thought, link, file, image",
                type_value
            ),
            "type",
        )
    }

    pub fn invalid_source_url(url: &str) -> Self {
        Self::with_field(
            ErrorCode::InvalidSourceUrl,
            format!("Invalid URL format: '{}'", url),
            "sourceUrl",
        )
    }

    pub fn capture_not_found(id: &str) -> Self {
        Self::new(
            ErrorCode::CaptureNotFound,
            format!("Capture not found: {}", id),
        )
    }

    pub fn file_too_large(max_size: usize, actual_size: usize) -> Self {
        Self::with_field(
            ErrorCode::FileTooLarge,
            format!(
                "File exceeds maximum size of {} bytes (got {})",
                max_size, actual_size
            ),
            "file",
        )
    }

    pub fn database_error(msg: impl Into<String>) -> Self {
        Self::new(ErrorCode::DatabaseError, msg)
    }

    pub fn internal_error(msg: impl Into<String>) -> Self {
        Self::new(ErrorCode::InternalError, msg)
    }
}

impl std::fmt::Display for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "[{:?}] {}", self.code, self.message)
    }
}

impl std::error::Error for AppError {}

/// Convert AppError to a JSON string for IPC error responses
impl From<AppError> for String {
    fn from(err: AppError) -> String {
        serde_json::to_string(&err).unwrap_or(err.message)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_code_serialization() {
        let code = ErrorCode::ContentTooLong;
        let json = serde_json::to_string(&code).unwrap();
        assert_eq!(json, "\"CONTENT_TOO_LONG\"");
    }

    #[test]
    fn test_app_error_serialization() {
        let err = AppError::content_too_long(50000, 60000);
        let json = serde_json::to_string(&err).unwrap();
        assert!(json.contains("\"code\":\"CONTENT_TOO_LONG\""));
        assert!(json.contains("\"field\":\"content\""));
    }

    #[test]
    fn test_app_error_without_field() {
        let err = AppError::new(ErrorCode::DatabaseError, "Connection failed");
        let json = serde_json::to_string(&err).unwrap();
        assert!(!json.contains("field"));
    }

    #[test]
    fn test_app_error_to_string() {
        let err = AppError::capture_not_found("123");
        let s: String = err.into();
        assert!(s.contains("CAPTURE_NOT_FOUND"));
        assert!(s.contains("123"));
    }
}
