use crate::config::CaptureConfig;
use crate::db::models::capture::{Capture, CaptureType, CreateCaptureInput};
use crate::db::DbPool;
use crate::errors::AppError;
use chrono::Utc;
use sqlx::Row;
use url::Url;
use uuid::Uuid;

#[derive(Debug, thiserror::Error)]
pub enum CaptureError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    #[error("Capture not found: {0}")]
    NotFound(String),
    #[error("Validation error: {0}")]
    Validation(AppError),
}

impl From<CaptureError> for String {
    fn from(err: CaptureError) -> String {
        match err {
            CaptureError::Validation(app_err) => app_err.into(),
            CaptureError::NotFound(id) => AppError::capture_not_found(&id).into(),
            CaptureError::Database(e) => AppError::database_error(e.to_string()).into(),
        }
    }
}

/// Validate capture input before creation
pub fn validate_input(input: &CreateCaptureInput, config: &CaptureConfig) -> Result<(), AppError> {
    // Validate content length
    if input.content.len() > config.max_content_length {
        return Err(AppError::content_too_long(
            config.max_content_length,
            input.content.len(),
        ));
    }

    // Content must not be empty for thought/link types
    if input.content.is_empty()
        && (input.capture_type == CaptureType::Thought || input.capture_type == CaptureType::Link)
    {
        return Err(AppError::with_field(
            crate::errors::ErrorCode::ValidationError,
            "Content cannot be empty",
            "content",
        ));
    }

    // Validate source_url format if provided
    if let Some(ref url_str) = input.source_url {
        if !url_str.is_empty() && Url::parse(url_str).is_err() {
            return Err(AppError::invalid_source_url(url_str));
        }
    }

    // Link type requires source_url
    if input.capture_type == CaptureType::Link {
        match &input.source_url {
            None => {
                return Err(AppError::with_field(
                    crate::errors::ErrorCode::ValidationError,
                    "Link captures require a source URL",
                    "sourceUrl",
                ));
            }
            Some(url) if url.is_empty() => {
                return Err(AppError::with_field(
                    crate::errors::ErrorCode::ValidationError,
                    "Link captures require a source URL",
                    "sourceUrl",
                ));
            }
            _ => {}
        }
    }

    Ok(())
}

pub async fn create(
    pool: &DbPool,
    input: CreateCaptureInput,
    config: &CaptureConfig,
) -> Result<Capture, CaptureError> {
    // Validate input
    validate_input(&input, config).map_err(CaptureError::Validation)?;

    let id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();

    tracing::debug!(
        "Creating capture: id={}, type={:?}, content_len={}",
        id,
        input.capture_type,
        input.content.len()
    );

    sqlx::query(
        r#"
        INSERT INTO captures (id, type, content, source_url, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(&id)
    .bind(input.capture_type.as_str())
    .bind(&input.content)
    .bind(&input.source_url)
    .bind(&now)
    .bind(&now)
    .execute(pool.as_ref())
    .await?;

    tracing::debug!("Capture created successfully: id={}", id);
    get_by_id(pool, &id).await
}

pub async fn get_by_id(pool: &DbPool, id: &str) -> Result<Capture, CaptureError> {
    let row = sqlx::query(
        r#"
        SELECT id, type, content, source_url, file_path, thumbnail_path,
               summary, primary_tag_id, is_deleted, created_at, updated_at
        FROM captures
        WHERE id = ? AND is_deleted = 0
        "#,
    )
    .bind(id)
    .fetch_optional(pool.as_ref())
    .await?
    .ok_or_else(|| CaptureError::NotFound(id.to_string()))?;

    Ok(Capture {
        id: row.get("id"),
        capture_type: CaptureType::from_str(row.get("type")),
        content: row.get("content"),
        source_url: row.get("source_url"),
        file_path: row.get("file_path"),
        thumbnail_path: row.get("thumbnail_path"),
        summary: row.get("summary"),
        primary_tag_id: row.get("primary_tag_id"),
        is_deleted: row.get::<i32, _>("is_deleted") != 0,
        created_at: row.get("created_at"),
        updated_at: row.get("updated_at"),
        tags: vec![], // TODO: Phase 4 - load tags via JOIN
    })
}

pub async fn list(pool: &DbPool, limit: i64, offset: i64) -> Result<Vec<Capture>, CaptureError> {
    let rows = sqlx::query(
        r#"
        SELECT id, type, content, source_url, file_path, thumbnail_path,
               summary, primary_tag_id, is_deleted, created_at, updated_at
        FROM captures
        WHERE is_deleted = 0
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
        "#,
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.as_ref())
    .await?;

    Ok(rows
        .into_iter()
        .map(|row| Capture {
            id: row.get("id"),
            capture_type: CaptureType::from_str(row.get("type")),
            content: row.get("content"),
            source_url: row.get("source_url"),
            file_path: row.get("file_path"),
            thumbnail_path: row.get("thumbnail_path"),
            summary: row.get("summary"),
            primary_tag_id: row.get("primary_tag_id"),
            is_deleted: row.get::<i32, _>("is_deleted") != 0,
            created_at: row.get("created_at"),
            updated_at: row.get("updated_at"),
            tags: vec![], // TODO: Phase 4 - load tags via JOIN
        })
        .collect())
}

pub async fn update(
    pool: &DbPool,
    id: &str,
    content: &str,
    config: &CaptureConfig,
) -> Result<Capture, CaptureError> {
    // Validate content length
    if content.len() > config.max_content_length {
        return Err(CaptureError::Validation(AppError::content_too_long(
            config.max_content_length,
            content.len(),
        )));
    }

    let now = Utc::now().to_rfc3339();

    tracing::debug!("Updating capture: id={}, content_len={}", id, content.len());

    let result = sqlx::query(
        r#"
        UPDATE captures
        SET content = ?, updated_at = ?
        WHERE id = ? AND is_deleted = 0
        "#,
    )
    .bind(content)
    .bind(&now)
    .bind(id)
    .execute(pool.as_ref())
    .await?;

    if result.rows_affected() == 0 {
        return Err(CaptureError::NotFound(id.to_string()));
    }

    tracing::debug!("Capture updated successfully: id={}", id);
    get_by_id(pool, id).await
}

pub async fn delete(pool: &DbPool, id: &str) -> Result<(), CaptureError> {
    let now = Utc::now().to_rfc3339();

    tracing::debug!("Deleting capture: id={}", id);

    let result = sqlx::query(
        r#"
        UPDATE captures
        SET is_deleted = 1, updated_at = ?
        WHERE id = ? AND is_deleted = 0
        "#,
    )
    .bind(&now)
    .bind(id)
    .execute(pool.as_ref())
    .await?;

    if result.rows_affected() == 0 {
        return Err(CaptureError::NotFound(id.to_string()));
    }

    tracing::debug!("Capture deleted successfully: id={}", id);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::FileSizeConfig;

    fn test_config() -> CaptureConfig {
        CaptureConfig {
            max_content_length: 100,
            max_file_size: FileSizeConfig {
                image: 10485760,
                document: 52428800,
            },
        }
    }

    #[test]
    fn test_validate_content_too_long() {
        let config = test_config();
        let input = CreateCaptureInput {
            capture_type: CaptureType::Thought,
            content: "x".repeat(101),
            source_url: None,
            habit_id: None,
        };

        let result = validate_input(&input, &config);
        assert!(result.is_err());

        let err = result.unwrap_err();
        assert_eq!(err.code, crate::errors::ErrorCode::ContentTooLong);
    }

    #[test]
    fn test_validate_empty_content() {
        let config = test_config();
        let input = CreateCaptureInput {
            capture_type: CaptureType::Thought,
            content: String::new(),
            source_url: None,
            habit_id: None,
        };

        let result = validate_input(&input, &config);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_invalid_url() {
        let config = test_config();
        let input = CreateCaptureInput {
            capture_type: CaptureType::Thought,
            content: "test".to_string(),
            source_url: Some("not-a-valid-url".to_string()),
            habit_id: None,
        };

        let result = validate_input(&input, &config);
        assert!(result.is_err());

        let err = result.unwrap_err();
        assert_eq!(err.code, crate::errors::ErrorCode::InvalidSourceUrl);
    }

    #[test]
    fn test_validate_link_requires_url() {
        let config = test_config();
        let input = CreateCaptureInput {
            capture_type: CaptureType::Link,
            content: "test".to_string(),
            source_url: None,
            habit_id: None,
        };

        let result = validate_input(&input, &config);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_valid_thought() {
        let config = test_config();
        let input = CreateCaptureInput {
            capture_type: CaptureType::Thought,
            content: "This is a valid thought".to_string(),
            source_url: None,
            habit_id: None,
        };

        let result = validate_input(&input, &config);
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_valid_link() {
        let config = test_config();
        let input = CreateCaptureInput {
            capture_type: CaptureType::Link,
            content: "Interesting article".to_string(),
            source_url: Some("https://example.com".to_string()),
            habit_id: None,
        };

        let result = validate_input(&input, &config);
        assert!(result.is_ok());
    }
}
