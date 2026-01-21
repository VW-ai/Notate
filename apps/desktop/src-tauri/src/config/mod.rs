use serde::{Deserialize, Serialize};

#[derive(Debug, thiserror::Error)]
#[allow(clippy::enum_variant_names)]
pub enum ConfigError {
    #[error("Failed to read config file: {0}")]
    ReadError(#[from] std::io::Error),
    #[error("Failed to parse YAML: {0}")]
    ParseError(#[from] serde_yaml::Error),
    #[error("Config validation failed: {0}")]
    ValidationError(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub app: AppInfo,
    pub capture: CaptureConfig,
    pub evolution: EvolutionConfig,
    pub ai: AiConfig,
    pub ui: UiConfig,
    pub storage: StorageConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppInfo {
    pub name: String,
    pub version: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CaptureConfig {
    pub max_content_length: usize,
    pub max_file_size: FileSizeConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileSizeConfig {
    pub image: usize,
    pub document: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvolutionConfig {
    pub similarity_threshold: SimilarityThreshold,
    pub min_captures_for_trace: i32,
    pub hint_cooldown_hours: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimilarityThreshold {
    pub hint: f64,
    pub trace: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiConfig {
    pub timeout_ms: AiTimeouts,
    pub retry: AiRetry,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiTimeouts {
    pub embedding: u64,
    pub tagging: u64,
    pub summary: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiRetry {
    pub embedding: u32,
    pub tagging: u32,
    pub summary: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UiConfig {
    pub overlay: OverlayConfig,
    pub animation: AnimationConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OverlayConfig {
    pub width: u32,
    pub height: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnimationConfig {
    pub duration_ms: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StorageConfig {
    pub db_name: String,
    pub vectors_dir: String,
    pub files_dir: String,
    pub cache_dir: String,
}

impl AppConfig {
    /// Load config from embedded defaults
    pub fn load_defaults() -> Result<Self, ConfigError> {
        let yaml = include_str!("defaults.yaml");
        let config: AppConfig = serde_yaml::from_str(yaml)?;
        config.validate()?;
        Ok(config)
    }

    fn validate(&self) -> Result<(), ConfigError> {
        if self.capture.max_content_length == 0 {
            return Err(ConfigError::ValidationError(
                "max_content_length must be > 0".into(),
            ));
        }
        if self.evolution.similarity_threshold.hint < 0.0
            || self.evolution.similarity_threshold.hint > 1.0
        {
            return Err(ConfigError::ValidationError(
                "similarity_threshold.hint must be between 0 and 1".into(),
            ));
        }
        Ok(())
    }
}
