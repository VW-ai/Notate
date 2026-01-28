use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use crate::db::repositories::capture_repo::RepoError;
use crate::services::habit_service::HabitError;
use crate::services::trace_service::TraceError;

// ============================================================================
// Error Configuration (Data-Driven)
// ============================================================================

/// Error template from errors.yaml
#[allow(dead_code)]
#[derive(Debug, Clone, Deserialize)]
pub struct ErrorTemplate {
    pub message: String,
    #[serde(default)]
    pub field: Option<String>,
}

/// Error configuration loaded from errors.yaml
#[allow(dead_code)]
#[derive(Debug, Clone, Deserialize, Default)]
pub struct ErrorsConfig {
    pub errors: HashMap<String, ErrorTemplate>,
}

#[allow(dead_code)]
impl ErrorsConfig {
    /// Load once at app startup via include_str!
    pub fn load() -> Self {
        let yaml = include_str!("config/errors.yaml");
        serde_yaml::from_str(yaml).unwrap_or_else(|e| {
            tracing::warn!("Failed to parse errors.yaml, using defaults: {}", e);
            Self::default()
        })
    }

    /// Format an error message using template placeholders
    pub fn format(&self, code: &ErrorCode, params: &[(&str, &str)]) -> String {
        let key = error_code_to_key(code);

        match self.errors.get(&key) {
            Some(template) => {
                let mut msg = template.message.clone();
                for (k, v) in params {
                    msg = msg.replace(&format!("{{{}}}", k), v);
                }
                msg
            }
            None => format!("{:?}", code),
        }
    }

    /// Get field name for an error code from config
    pub fn get_field(&self, code: &ErrorCode) -> Option<String> {
        let key = error_code_to_key(code);
        self.errors.get(&key).and_then(|t| t.field.clone())
    }
}

/// Convert ErrorCode to SCREAMING_SNAKE_CASE key for lookup
#[allow(dead_code)]
fn error_code_to_key(code: &ErrorCode) -> String {
    let debug_str = format!("{:?}", code);
    let mut result = String::new();
    for (i, c) in debug_str.chars().enumerate() {
        if c.is_uppercase() && i > 0 {
            result.push('_');
        }
        result.push(c.to_ascii_uppercase());
    }
    result
}

// ============================================================================
// Error Code Enum
// ============================================================================

/// Unified error code enum for all application errors
#[derive(Debug, Clone, Serialize, PartialEq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
#[allow(dead_code)]
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

// ============================================================================
// AppError Structure
// ============================================================================

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

    /// Create error using ErrorsConfig for message formatting
    #[allow(dead_code)]
    pub fn from_config(config: &ErrorsConfig, code: ErrorCode, params: &[(&str, &str)]) -> Self {
        let msg = config.format(&code, params);
        let field = config.get_field(&code);
        Self {
            code,
            message: msg,
            field,
        }
    }

    // Convenience factory methods (use hardcoded messages for simplicity)
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

    #[allow(dead_code)]
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

    #[allow(dead_code)]
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

    #[allow(dead_code)]
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

// ============================================================================
// From Trait Implementations
// ============================================================================

impl From<RepoError> for AppError {
    fn from(err: RepoError) -> Self {
        match err {
            RepoError::Database(e) => AppError::database_error(e.to_string()),
            RepoError::NotFound(id) => AppError::capture_not_found(&id),
        }
    }
}

impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        AppError::database_error(err.to_string())
    }
}

impl From<TraceError> for AppError {
    fn from(err: TraceError) -> Self {
        match err {
            TraceError::Database(e) => AppError::database_error(e.to_string()),
            TraceError::NotFound(id) => AppError::new(
                ErrorCode::CaptureNotFound, // Reuse for now, add TraceNotFound in M2
                format!("Trace not found: {}", id),
            ),
        }
    }
}

impl From<HabitError> for AppError {
    fn from(err: HabitError) -> Self {
        match err {
            HabitError::Database(e) => AppError::database_error(e.to_string()),
            HabitError::NotFound(id) => AppError::new(
                ErrorCode::CaptureNotFound, // Reuse for now, add HabitNotFound in M2
                format!("Habit not found: {}", id),
            ),
        }
    }
}

// ============================================================================
// Tests
// ============================================================================

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
    fn test_error_code_to_key() {
        assert_eq!(
            error_code_to_key(&ErrorCode::ContentTooLong),
            "CONTENT_TOO_LONG"
        );
        assert_eq!(
            error_code_to_key(&ErrorCode::DatabaseError),
            "DATABASE_ERROR"
        );
        assert_eq!(
            error_code_to_key(&ErrorCode::InvalidSourceUrl),
            "INVALID_SOURCE_URL"
        );
    }

    #[test]
    fn test_errors_config_load() {
        let config = ErrorsConfig::load();
        assert!(config.errors.contains_key("CONTENT_TOO_LONG"));
        assert!(config.errors.contains_key("DATABASE_ERROR"));
    }

    #[test]
    fn test_errors_config_format() {
        let config = ErrorsConfig::load();
        let msg = config.format(
            &ErrorCode::ContentTooLong,
            &[("max", "50000"), ("actual", "60000")],
        );
        assert!(msg.contains("50000"));
        assert!(msg.contains("60000"));
    }

    #[test]
    fn test_from_repo_error_not_found() {
        let repo_err = RepoError::NotFound("test-123".to_string());
        let app_err: AppError = repo_err.into();
        assert_eq!(app_err.code, ErrorCode::CaptureNotFound);
        assert!(app_err.message.contains("test-123"));
    }

    #[test]
    fn test_from_repo_error_database() {
        let sqlx_err = sqlx::Error::RowNotFound;
        let repo_err = RepoError::Database(sqlx_err);
        let app_err: AppError = repo_err.into();
        assert_eq!(app_err.code, ErrorCode::DatabaseError);
    }
}
