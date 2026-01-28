use crate::db::models::trace::Trace;
use crate::db::DbPool;
use crate::services::trace_service;
use tauri::State;

#[tauri::command]
pub async fn get_traces(pool: State<'_, DbPool>) -> Result<Vec<Trace>, String> {
    tracing::debug!("IPC: get_traces called");
    trace_service::list(&pool).await.map_err(|e| {
        let err_str = e.to_string();
        tracing::warn!("IPC: get_traces failed: {}", err_str);
        err_str
    })
}
