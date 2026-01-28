use crate::db::models::habit::Habit;
use crate::db::DbPool;
use crate::services::habit_service;
use tauri::State;

#[tauri::command]
pub async fn get_habits(pool: State<'_, DbPool>) -> Result<Vec<Habit>, String> {
    tracing::debug!("IPC: get_habits called");
    habit_service::list(&pool).await.map_err(|e| {
        let err_str = e.to_string();
        tracing::warn!("IPC: get_habits failed: {}", err_str);
        err_str
    })
}
