use crate::db::models::capture::{Capture, CaptureType, CreateCaptureInput};
use crate::db::DbPool;
use chrono::Utc;
use sqlx::Row;
use uuid::Uuid;

#[derive(Debug, thiserror::Error)]
pub enum CaptureError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    #[error("Capture not found: {0}")]
    NotFound(String),
    #[allow(dead_code)]
    #[error("Invalid input: {0}")]
    InvalidInput(String),
}

pub async fn create(pool: &DbPool, input: CreateCaptureInput) -> Result<Capture, CaptureError> {
    let id = Uuid::new_v4().to_string();
    let now = Utc::now().to_rfc3339();

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
        tags: vec![], // Tags loaded separately
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
            tags: vec![],
        })
        .collect())
}

pub async fn update(pool: &DbPool, id: &str, content: &str) -> Result<Capture, CaptureError> {
    let now = Utc::now().to_rfc3339();

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

    get_by_id(pool, id).await
}

pub async fn delete(pool: &DbPool, id: &str) -> Result<(), CaptureError> {
    let now = Utc::now().to_rfc3339();

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

    Ok(())
}
