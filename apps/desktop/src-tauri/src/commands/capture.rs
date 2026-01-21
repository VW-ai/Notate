use crate::db::models::capture::{Capture, CreateCaptureInput};
use crate::services::capture_service;
use tauri::State;

use crate::db::DbPool;

#[tauri::command]
pub async fn create_capture(
    input: CreateCaptureInput,
    pool: State<'_, DbPool>,
) -> Result<Capture, String> {
    capture_service::create(&pool, input)
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_capture(id: String, pool: State<'_, DbPool>) -> Result<Capture, String> {
    capture_service::get_by_id(&pool, &id)
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_captures(
    limit: Option<i64>,
    offset: Option<i64>,
    pool: State<'_, DbPool>,
) -> Result<Vec<Capture>, String> {
    capture_service::list(&pool, limit.unwrap_or(20), offset.unwrap_or(0))
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn update_capture(
    id: String,
    content: String,
    pool: State<'_, DbPool>,
) -> Result<Capture, String> {
    capture_service::update(&pool, &id, &content)
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn delete_capture(id: String, pool: State<'_, DbPool>) -> Result<(), String> {
    capture_service::delete(&pool, &id)
        .await
        .map_err(|e| e.to_string())
}
