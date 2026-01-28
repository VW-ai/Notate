use crate::db::models::trace::Trace;
use crate::db::DbPool;
use crate::errors::AppError;
use crate::services::trace_service;
use tauri::State;

#[tauri::command]
pub async fn get_traces(pool: State<'_, DbPool>) -> Result<Vec<Trace>, AppError> {
    tracing::debug!("IPC: get_traces called (stub - M2)");
    trace_service::list(&pool).await.map_err(AppError::from)
}
