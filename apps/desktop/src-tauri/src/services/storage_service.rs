use crate::config::StorageConfig;
use std::path::{Path, PathBuf};

#[derive(Debug, thiserror::Error)]
pub enum StorageError {
    #[error("Failed to create directory {path}: {source}")]
    DirectoryCreateFailed {
        path: PathBuf,
        source: std::io::Error,
    },
    #[error("App directory not available")]
    #[allow(dead_code)] // Reserved for future use
    NoAppDir,
}

/// Storage paths initialized for the application
#[derive(Debug, Clone)]
#[allow(dead_code)] // Fields reserved for future use (file uploads, etc.)
pub struct StoragePaths {
    pub app_dir: PathBuf,
    pub db_path: PathBuf,
    pub files_dir: PathBuf,
    pub images_dir: PathBuf,
    pub documents_dir: PathBuf,
    pub cache_dir: PathBuf,
    pub thumbnails_dir: PathBuf,
    pub vectors_dir: PathBuf,
}

impl StoragePaths {
    /// Create storage paths from app directory and config
    pub fn new(app_dir: &Path, config: &StorageConfig) -> Self {
        let files_dir = app_dir.join(&config.files_dir);
        let cache_dir = app_dir.join(&config.cache_dir);

        Self {
            app_dir: app_dir.to_path_buf(),
            db_path: app_dir.join(&config.db_name),
            files_dir: files_dir.clone(),
            images_dir: files_dir.join("images"),
            documents_dir: files_dir.join("documents"),
            cache_dir: cache_dir.clone(),
            thumbnails_dir: cache_dir.join("thumbnails"),
            vectors_dir: app_dir.join(&config.vectors_dir),
        }
    }
}

/// Initialize all storage directories based on config
///
/// Creates the following directory structure:
/// ```text
/// ~/Library/Application Support/com.notate.Notate/
/// ├── notate.db
/// ├── files/
/// │   ├── images/
/// │   └── documents/
/// ├── cache/
/// │   └── thumbnails/
/// └── vectors/
/// ```
pub fn init_directories(
    app_dir: &Path,
    config: &StorageConfig,
) -> Result<StoragePaths, StorageError> {
    let paths = StoragePaths::new(app_dir, config);

    // Create all required directories
    let dirs_to_create = [
        &paths.images_dir,
        &paths.documents_dir,
        &paths.thumbnails_dir,
        &paths.vectors_dir,
    ];

    for dir in dirs_to_create {
        create_dir_if_missing(dir)?;
    }

    tracing::info!("Storage directories initialized:");
    tracing::info!("  App dir: {:?}", paths.app_dir);
    tracing::info!("  Files: {:?}", paths.files_dir);
    tracing::info!("  Images: {:?}", paths.images_dir);
    tracing::info!("  Documents: {:?}", paths.documents_dir);
    tracing::info!("  Cache: {:?}", paths.cache_dir);
    tracing::info!("  Thumbnails: {:?}", paths.thumbnails_dir);
    tracing::info!("  Vectors: {:?}", paths.vectors_dir);

    Ok(paths)
}

fn create_dir_if_missing(path: &Path) -> Result<(), StorageError> {
    if !path.exists() {
        std::fs::create_dir_all(path).map_err(|e| StorageError::DirectoryCreateFailed {
            path: path.to_path_buf(),
            source: e,
        })?;
        tracing::debug!("Created directory: {:?}", path);
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    fn test_config() -> StorageConfig {
        StorageConfig {
            db_name: "test.db".to_string(),
            files_dir: "files".to_string(),
            cache_dir: "cache".to_string(),
            vectors_dir: "vectors".to_string(),
        }
    }

    #[test]
    fn test_storage_paths_new() {
        let temp_dir = TempDir::new().unwrap();
        let config = test_config();
        let paths = StoragePaths::new(temp_dir.path(), &config);

        assert_eq!(paths.app_dir, temp_dir.path());
        assert_eq!(paths.db_path, temp_dir.path().join("test.db"));
        assert_eq!(paths.files_dir, temp_dir.path().join("files"));
        assert_eq!(paths.images_dir, temp_dir.path().join("files/images"));
        assert_eq!(paths.documents_dir, temp_dir.path().join("files/documents"));
        assert_eq!(paths.cache_dir, temp_dir.path().join("cache"));
        assert_eq!(
            paths.thumbnails_dir,
            temp_dir.path().join("cache/thumbnails")
        );
        assert_eq!(paths.vectors_dir, temp_dir.path().join("vectors"));
    }

    #[test]
    fn test_init_directories_creates_all_dirs() {
        let temp_dir = TempDir::new().unwrap();
        let config = test_config();

        let paths = init_directories(temp_dir.path(), &config).unwrap();

        assert!(paths.images_dir.exists());
        assert!(paths.documents_dir.exists());
        assert!(paths.thumbnails_dir.exists());
        assert!(paths.vectors_dir.exists());
    }

    #[test]
    fn test_init_directories_idempotent() {
        let temp_dir = TempDir::new().unwrap();
        let config = test_config();

        // Run twice - should not fail
        init_directories(temp_dir.path(), &config).unwrap();
        let paths = init_directories(temp_dir.path(), &config).unwrap();

        assert!(paths.images_dir.exists());
    }
}
