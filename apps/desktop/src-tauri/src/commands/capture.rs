use crate::config::AppConfig;
use crate::db::models::capture::{Capture, CreateCaptureInput};
use crate::db::DbPool;
use crate::services::capture_service;
use tauri::State;

#[tauri::command]
pub async fn create_capture(
    input: CreateCaptureInput,
    pool: State<'_, DbPool>,
    config: State<'_, AppConfig>,
) -> Result<Capture, String> {
    tracing::debug!(
        "IPC: create_capture called with type={:?}",
        input.capture_type
    );
    capture_service::create(&pool, input, &config.capture)
        .await
        .map_err(|e| e.into())
}

#[tauri::command]
pub async fn get_capture(id: String, pool: State<'_, DbPool>) -> Result<Capture, String> {
    tracing::debug!("IPC: get_capture called with id={}", id);
    capture_service::get_by_id(&pool, &id)
        .await
        .map_err(|e| e.into())
}

#[tauri::command]
pub async fn get_captures(
    limit: Option<i64>,
    offset: Option<i64>,
    pool: State<'_, DbPool>,
) -> Result<Vec<Capture>, String> {
    tracing::debug!(
        "IPC: get_captures called with limit={:?}, offset={:?}",
        limit,
        offset
    );
    capture_service::list(&pool, limit.unwrap_or(20), offset.unwrap_or(0))
        .await
        .map_err(|e| e.into())
}

#[tauri::command]
pub async fn update_capture(
    id: String,
    content: String,
    pool: State<'_, DbPool>,
    config: State<'_, AppConfig>,
) -> Result<Capture, String> {
    tracing::debug!("IPC: update_capture called with id={}", id);
    capture_service::update(&pool, &id, &content, &config.capture)
        .await
        .map_err(|e| e.into())
}

#[tauri::command]
pub async fn delete_capture(id: String, pool: State<'_, DbPool>) -> Result<(), String> {
    tracing::debug!("IPC: delete_capture called with id={}", id);
    capture_service::delete(&pool, &id)
        .await
        .map_err(|e| e.into())
}
