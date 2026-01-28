use crate::db::models::habit::Habit;
use crate::db::DbPool;

#[derive(Debug, thiserror::Error)]
pub enum HabitError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    #[error("Habit not found: {0}")]
    NotFound(String),
}

/// List all active habits
/// TODO: M2 - Implement actual business logic
pub async fn list(_pool: &DbPool) -> Result<Vec<Habit>, HabitError> {
    tracing::debug!("habit_service::list called (stub)");
    Ok(vec![])
}

/// Get habit by ID
/// TODO: M2 - Implement actual business logic
#[allow(dead_code)]
pub async fn get_by_id(_pool: &DbPool, id: &str) -> Result<Habit, HabitError> {
    tracing::debug!("habit_service::get_by_id called (stub) id={}", id);
    Err(HabitError::NotFound(id.to_string()))
}
