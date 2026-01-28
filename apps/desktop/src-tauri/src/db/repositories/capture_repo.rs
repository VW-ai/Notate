use crate::db::models::capture::{Capture, CaptureType};
use crate::db::models::tag::Tag;
use crate::db::DbPool;
use sqlx::Row;

#[derive(Debug, thiserror::Error)]
pub enum RepoError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    #[error("Not found: {0}")]
    NotFound(String),
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
                        count: 0,
                    })
                } else {
                    None
                }
            })
            .collect(),
        _ => vec![],
    }
}

/// Insert a new capture
pub async fn insert(
    pool: &DbPool,
    id: &str,
    capture_type: &CaptureType,
    content: &str,
    source_url: Option<&str>,
    now: &str,
) -> Result<(), RepoError> {
    sqlx::query(
        r#"
        INSERT INTO captures (id, type, content, source_url, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(id)
    .bind(capture_type.as_str())
    .bind(content)
    .bind(source_url)
    .bind(now)
    .bind(now)
    .execute(pool.as_ref())
    .await?;

    Ok(())
}

/// Find capture by ID, returns NotFound if not exists or soft-deleted
pub async fn find_by_id(pool: &DbPool, id: &str) -> Result<Capture, RepoError> {
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
    .ok_or_else(|| RepoError::NotFound(id.to_string()))?;

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

/// List captures with pagination
pub async fn find_all(pool: &DbPool, limit: i64, offset: i64) -> Result<Vec<Capture>, RepoError> {
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

/// Update content, returns rows affected (0 = not found)
pub async fn update_content(
    pool: &DbPool,
    id: &str,
    content: &str,
    now: &str,
) -> Result<u64, RepoError> {
    let result = sqlx::query(
        r#"
        UPDATE captures
        SET content = ?, updated_at = ?
        WHERE id = ? AND is_deleted = 0
        "#,
    )
    .bind(content)
    .bind(now)
    .bind(id)
    .execute(pool.as_ref())
    .await?;

    Ok(result.rows_affected())
}

/// Soft delete, returns rows affected (0 = not found)
pub async fn soft_delete(pool: &DbPool, id: &str, now: &str) -> Result<u64, RepoError> {
    let result = sqlx::query(
        r#"
        UPDATE captures
        SET is_deleted = 1, updated_at = ?
        WHERE id = ? AND is_deleted = 0
        "#,
    )
    .bind(now)
    .bind(id)
    .execute(pool.as_ref())
    .await?;

    Ok(result.rows_affected())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::test_utils::setup_test_db;
    use std::sync::Arc;

    #[tokio::test]
    async fn test_insert_and_find_by_id() {
        let pool = Arc::new(setup_test_db().await.unwrap());
        let now = "2026-01-28T00:00:00Z";

        insert(
            &pool,
            "test-1",
            &CaptureType::Thought,
            "Hello world",
            None,
            now,
        )
        .await
        .unwrap();

        let capture = find_by_id(&pool, "test-1").await.unwrap();
        assert_eq!(capture.id, "test-1");
        assert_eq!(capture.content, "Hello world");
        assert_eq!(capture.capture_type, CaptureType::Thought);
        assert!(capture.tags.is_empty());
    }

    #[tokio::test]
    async fn test_find_by_id_not_found() {
        let pool = Arc::new(setup_test_db().await.unwrap());
        let result = find_by_id(&pool, "nonexistent").await;
        assert!(matches!(result, Err(RepoError::NotFound(_))));
    }

    #[tokio::test]
    async fn test_find_all_pagination() {
        let pool = Arc::new(setup_test_db().await.unwrap());
        let now = "2026-01-28T00:00:00Z";

        // Insert 3 captures
        for i in 1..=3 {
            insert(
                &pool,
                &format!("test-{}", i),
                &CaptureType::Thought,
                &format!("Content {}", i),
                None,
                now,
            )
            .await
            .unwrap();
        }

        // Get first 2
        let captures = find_all(&pool, 2, 0).await.unwrap();
        assert_eq!(captures.len(), 2);

        // Get remaining 1
        let captures = find_all(&pool, 2, 2).await.unwrap();
        assert_eq!(captures.len(), 1);
    }

    #[tokio::test]
    async fn test_update_content() {
        let pool = Arc::new(setup_test_db().await.unwrap());
        let now = "2026-01-28T00:00:00Z";

        insert(
            &pool,
            "test-1",
            &CaptureType::Thought,
            "Original",
            None,
            now,
        )
        .await
        .unwrap();

        let rows = update_content(&pool, "test-1", "Updated", now)
            .await
            .unwrap();
        assert_eq!(rows, 1);

        let capture = find_by_id(&pool, "test-1").await.unwrap();
        assert_eq!(capture.content, "Updated");
    }

    #[tokio::test]
    async fn test_update_nonexistent_returns_zero() {
        let pool = Arc::new(setup_test_db().await.unwrap());
        let now = "2026-01-28T00:00:00Z";

        let rows = update_content(&pool, "nonexistent", "Content", now)
            .await
            .unwrap();
        assert_eq!(rows, 0);
    }

    #[tokio::test]
    async fn test_soft_delete_makes_invisible() {
        let pool = Arc::new(setup_test_db().await.unwrap());
        let now = "2026-01-28T00:00:00Z";

        insert(
            &pool,
            "test-delete",
            &CaptureType::Thought,
            "Delete me",
            None,
            now,
        )
        .await
        .unwrap();

        let rows = soft_delete(&pool, "test-delete", now).await.unwrap();
        assert_eq!(rows, 1);

        // Should not be found after soft delete
        let result = find_by_id(&pool, "test-delete").await;
        assert!(matches!(result, Err(RepoError::NotFound(_))));

        // Should not appear in list
        let captures = find_all(&pool, 100, 0).await.unwrap();
        assert!(captures.iter().all(|c| c.id != "test-delete"));
    }

    #[tokio::test]
    async fn test_soft_delete_nonexistent_returns_zero() {
        let pool = Arc::new(setup_test_db().await.unwrap());
        let now = "2026-01-28T00:00:00Z";

        let rows = soft_delete(&pool, "nonexistent", now).await.unwrap();
        assert_eq!(rows, 0);
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
