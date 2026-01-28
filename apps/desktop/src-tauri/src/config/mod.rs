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

// ============================================================================
// AI Prompts Configuration (M2+)
// ============================================================================

/// AI prompt templates for various operations
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct PromptsConfig {
    pub prompts: PromptTemplates,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct PromptTemplates {
    pub tagging: TaggingPrompt,
    pub summary: SummaryPrompt,
    pub evolution_hint: EvolutionHintPrompt,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaggingPrompt {
    pub system: String,
    pub max_tags: u32,
}

impl Default for TaggingPrompt {
    fn default() -> Self {
        Self {
            system: "You are a tagging assistant.".to_string(),
            max_tags: 5,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SummaryPrompt {
    pub system: String,
    pub max_length: u32,
}

impl Default for SummaryPrompt {
    fn default() -> Self {
        Self {
            system: "You are a summarization assistant.".to_string(),
            max_length: 200,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvolutionHintPrompt {
    pub system: String,
    pub max_related_captures: u32,
}

impl Default for EvolutionHintPrompt {
    fn default() -> Self {
        Self {
            system: "You are an evolution tracking assistant.".to_string(),
            max_related_captures: 5,
        }
    }
}

impl PromptsConfig {
    /// Load prompts from embedded YAML, falling back to defaults if parsing fails
    #[allow(dead_code)] // Reserved for M2 AI integration
    pub fn load() -> Self {
        let yaml = include_str!("prompts.yaml");
        serde_yaml::from_str(yaml).unwrap_or_else(|e| {
            tracing::warn!("Failed to parse prompts.yaml, using defaults: {}", e);
            Self::default()
        })
    }
}

// ============================================================================
// Habits Configuration (M2+)
// ============================================================================

/// Default habits loaded from config
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct HabitsConfig {
    pub habits: Vec<HabitDef>,
}

/// Habit definition from config file
#[allow(dead_code)] // Reserved for M2 habit management
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HabitDef {
    pub id: String,
    pub name: String,
    pub description: String,
    pub trigger_type: String,
    pub trigger_pattern: Option<String>,
    pub action_prompt: String,
    pub is_active: bool,
    pub is_system: bool,
}

impl HabitsConfig {
    /// Load habits from embedded YAML, falling back to empty if parsing fails
    #[allow(dead_code)] // Reserved for M2 habit management
    pub fn load() -> Self {
        let yaml = include_str!("habits.yaml");
        serde_yaml::from_str(yaml).unwrap_or_else(|e| {
            tracing::warn!("Failed to parse habits.yaml, using defaults: {}", e);
            Self::default()
        })
    }
}

// ============================================================================
// Main Application Config
// ============================================================================

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
