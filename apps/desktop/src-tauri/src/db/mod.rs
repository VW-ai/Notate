pub mod models;

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
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

fn get_db_path() -> Result<PathBuf, DbError> {
    let proj_dirs = ProjectDirs::from("com", "notate", "Notate").ok_or(DbError::NoDataDir)?;

    let data_dir = proj_dirs.data_dir();
    std::fs::create_dir_all(data_dir)?;

    Ok(data_dir.join("notate.db"))
}

pub async fn init(app: &AppHandle) -> Result<(), DbError> {
    let db_path = get_db_path()?;
    tracing::info!("Database path: {:?}", db_path);

    let db_url = format!("sqlite:{}?mode=rwc", db_path.display());

    let options = SqliteConnectOptions::from_str(&db_url)?
        .create_if_missing(true)
        .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal)
        .synchronous(sqlx::sqlite::SqliteSynchronous::Normal);

    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect_with(options)
        .await?;

    // Run migrations
    run_migrations(&pool).await?;

    // Store pool in app state
    app.manage(Arc::new(pool) as DbPool);

    Ok(())
}

async fn run_migrations(pool: &SqlitePool) -> Result<(), DbError> {
    let migration = include_str!("migrations/001_initial.sql");

    // Check if migrations table exists and if migration was applied
    let applied: Option<(i32,)> =
        sqlx::query_as("SELECT version FROM migrations WHERE version = 1")
            .fetch_optional(pool)
            .await
            .unwrap_or(None);

    if applied.is_none() {
        tracing::info!("Running initial migration...");
        sqlx::raw_sql(migration).execute(pool).await?;
        tracing::info!("Migration completed");
    } else {
        tracing::info!("Migration already applied");
    }

    Ok(())
}
