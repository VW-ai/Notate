use crate::config::CaptureConfig;
use crate::db::models::capture::{Capture, CaptureType, CreateCaptureInput};
use crate::db::models::tag::Tag;
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

/// Parse tags from GROUP_CONCAT string format: "id:name:color|id:name:color|..."
fn parse_tags_from_concat(tags_str: Option<String>) -> Vec<Tag> {
    match tags_str {
        Some(s) if !s.is_empty() => s
            .split('|')
            .filter_map(|tag_part| {
                let parts: Vec<&str> = tag_part.splitn(3, ':').collect();
                if parts.len() >= 2 {
                    Some(Tag {
                        id: parts[0].to_string(),
                        name: parts[1].to_string(),
                        color: parts.get(2).and_then(|c| {
                            if c.is_empty() {
                                None
                            } else {
                                Some(c.to_string())
                            }
                        }),
                        count: 0, // Not computed in this context
                    })
                } else {
                    None
                }
            })
            .collect(),
        _ => vec![],
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
        SELECT c.id, c.type, c.content, c.source_url, c.file_path, c.thumbnail_path,
               c.summary, c.primary_tag_id, c.is_deleted, c.created_at, c.updated_at,
               GROUP_CONCAT(t.id || ':' || t.name || ':' || COALESCE(t.color, ''), '|') as tags_str
        FROM captures c
        LEFT JOIN capture_tags ct ON c.id = ct.capture_id
        LEFT JOIN tags t ON ct.tag_id = t.id
        WHERE c.id = ? AND c.is_deleted = 0
        GROUP BY c.id
        "#,
    )
    .bind(id)
    .fetch_optional(pool.as_ref())
    .await?
    .ok_or_else(|| CaptureError::NotFound(id.to_string()))?;

    let tags_str: Option<String> = row.get("tags_str");

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
        tags: parse_tags_from_concat(tags_str),
    })
}

pub async fn list(pool: &DbPool, limit: i64, offset: i64) -> Result<Vec<Capture>, CaptureError> {
    let rows = sqlx::query(
        r#"
        SELECT c.id, c.type, c.content, c.source_url, c.file_path, c.thumbnail_path,
               c.summary, c.primary_tag_id, c.is_deleted, c.created_at, c.updated_at,
               GROUP_CONCAT(t.id || ':' || t.name || ':' || COALESCE(t.color, ''), '|') as tags_str
        FROM captures c
        LEFT JOIN capture_tags ct ON c.id = ct.capture_id
        LEFT JOIN tags t ON ct.tag_id = t.id
        WHERE c.is_deleted = 0
        GROUP BY c.id
        ORDER BY c.created_at DESC
        LIMIT ? OFFSET ?
        "#,
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(pool.as_ref())
    .await?;

    Ok(rows
        .into_iter()
        .map(|row| {
            let tags_str: Option<String> = row.get("tags_str");
            Capture {
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
                tags: parse_tags_from_concat(tags_str),
            }
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

    #[test]
    fn test_parse_tags_empty() {
        let result = parse_tags_from_concat(None);
        assert!(result.is_empty());

        let result = parse_tags_from_concat(Some(String::new()));
        assert!(result.is_empty());
    }

    #[test]
    fn test_parse_tags_single() {
        let tags_str = Some("tag1:Work:#ff0000".to_string());
        let result = parse_tags_from_concat(tags_str);

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].id, "tag1");
        assert_eq!(result[0].name, "Work");
        assert_eq!(result[0].color, Some("#ff0000".to_string()));
    }

    #[test]
    fn test_parse_tags_multiple() {
        let tags_str = Some("tag1:Work:#ff0000|tag2:Personal:#00ff00".to_string());
        let result = parse_tags_from_concat(tags_str);

        assert_eq!(result.len(), 2);
        assert_eq!(result[0].id, "tag1");
        assert_eq!(result[0].name, "Work");
        assert_eq!(result[1].id, "tag2");
        assert_eq!(result[1].name, "Personal");
    }

    #[test]
    fn test_parse_tags_no_color() {
        let tags_str = Some("tag1:Work:".to_string());
        let result = parse_tags_from_concat(tags_str);

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].id, "tag1");
        assert_eq!(result[0].name, "Work");
        assert_eq!(result[0].color, None);
    }
}
