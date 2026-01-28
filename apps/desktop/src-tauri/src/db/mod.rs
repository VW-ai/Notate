pub mod models;
pub mod repositories;

use directories::ProjectDirs;
use sqlx::sqlite::{SqliteConnectOptions, SqlitePool, SqlitePoolOptions};
use std::path::PathBuf;
use std::str::FromStr;
use std::sync::Arc;
use tauri::{AppHandle, Manager};

pub type DbPool = Arc<SqlitePool>;

#[derive(Debug, thiserror::Error)]
pub enum DbError {
    #[error("Failed to get app data directory")]
    NoDataDir,
    #[error("Database error: {0}")]
    Sqlx(#[from] sqlx::Error),
    #[error("Migration error: {0}")]
    Migration(#[from] sqlx::migrate::MigrateError),
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

/// Returns the application data directory path
pub fn get_app_dir() -> Result<PathBuf, DbError> {
    let proj_dirs = ProjectDirs::from("com", "notate", "Notate").ok_or(DbError::NoDataDir)?;
    Ok(proj_dirs.data_dir().to_path_buf())
}

fn get_db_path() -> Result<PathBuf, DbError> {
    let data_dir = get_app_dir()?;
    std::fs::create_dir_all(&data_dir)?;
    Ok(data_dir.join("notate.db"))
}

pub async fn init(app: &AppHandle) -> Result<(), DbError> {
    let db_path = get_db_path()?;
    tracing::info!("Notate starting - Database path: {:?}", db_path);

    let db_url = format!("sqlite:{}?mode=rwc", db_path.display());

    let options = SqliteConnectOptions::from_str(&db_url)?
        .create_if_missing(true)
        .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal)
        .synchronous(sqlx::sqlite::SqliteSynchronous::Normal)
        .foreign_keys(true);

    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect_with(options)
        .await?;

    // Verify WAL mode is active
    let wal_mode: (String,) = sqlx::query_as("PRAGMA journal_mode")
        .fetch_one(&pool)
        .await?;
    tracing::info!("SQLite journal mode: {}", wal_mode.0);

    // Run migrations using sqlx::migrate!()
    run_migrations(&pool).await?;

    // Store pool in app state
    app.manage(Arc::new(pool) as DbPool);

    Ok(())
}

async fn run_migrations(pool: &SqlitePool) -> Result<(), DbError> {
    tracing::info!("Running database migrations...");

    sqlx::migrate!("./migrations").run(pool).await?;

    tracing::info!("Migrations applied successfully");
    Ok(())
}

#[cfg(test)]
pub mod test_utils {
    use super::*;

    /// Create an in-memory SQLite database for testing
    /// Note: WAL mode is not supported for in-memory databases
    /// Foreign keys are disabled during migration, then enabled after
    #[allow(dead_code)]
    pub async fn setup_test_db() -> Result<SqlitePool, DbError> {
        let options = SqliteConnectOptions::from_str("sqlite::memory:")?
            .journal_mode(sqlx::sqlite::SqliteJournalMode::Delete)
            .foreign_keys(false); // Disable during migration

        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect_with(options)
            .await?;

        // Run migrations
        sqlx::migrate!("./migrations").run(&pool).await?;

        // Enable foreign keys after migration
        sqlx::query("PRAGMA foreign_keys = ON")
            .execute(&pool)
            .await?;

        Ok(pool)
    }
}
