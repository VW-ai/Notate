use crate::db::models::trace::Trace;
use crate::db::DbPool;

#[derive(Debug, thiserror::Error)]
pub enum TraceError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    #[error("Trace not found: {0}")]
    NotFound(String),
}

/// List all traces
/// TODO: M2 - Implement actual business logic
pub async fn list(_pool: &DbPool) -> Result<Vec<Trace>, TraceError> {
    tracing::debug!("trace_service::list called (stub)");
    Ok(vec![])
}

/// Get trace by ID
/// TODO: M2 - Implement actual business logic
#[allow(dead_code)]
pub async fn get_by_id(_pool: &DbPool, id: &str) -> Result<Trace, TraceError> {
    tracing::debug!("trace_service::get_by_id called (stub) id={}", id);
    Err(TraceError::NotFound(id.to_string()))
}
