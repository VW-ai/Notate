use crate::db::models::habit::Habit;
use crate::db::DbPool;
use crate::errors::AppError;
use crate::services::habit_service;
use tauri::State;

#[tauri::command]
pub async fn get_habits(pool: State<'_, DbPool>) -> Result<Vec<Habit>, AppError> {
    tracing::debug!("IPC: get_habits called (stub - M2)");
    habit_service::list(&pool).await.map_err(AppError::from)
}
