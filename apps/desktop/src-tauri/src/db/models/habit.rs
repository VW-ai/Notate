use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum TriggerType {
    Link,
    FileType,
    Manual,
}

impl TriggerType {
    #[allow(dead_code)] // Reserved for M2 habit execution
    pub fn as_str(&self) -> &'static str {
        match self {
            TriggerType::Link => "link",
            TriggerType::FileType => "file_type",
            TriggerType::Manual => "manual",
        }
    }

    #[allow(dead_code)] // Reserved for M2 habit loading
    pub fn from_str(s: &str) -> Self {
        match s {
            "link" => TriggerType::Link,
            "file_type" => TriggerType::FileType,
            "manual" => TriggerType::Manual,
            _ => TriggerType::Manual,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Habit {
    pub id: String,
    pub name: String,
    pub description: String,
    pub trigger_type: TriggerType,
    pub trigger_pattern: Option<String>,
    pub action_prompt: String,
    pub is_active: bool,
    pub is_system: bool,
    pub trigger_count: i32,
    pub last_triggered_at: Option<String>,
    pub created_at: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_trigger_type_serialization() {
        let trigger = TriggerType::FileType;
        let json = serde_json::to_string(&trigger).unwrap();
        assert_eq!(json, "\"file_type\"");
    }

    #[test]
    fn test_trigger_type_from_str() {
        assert_eq!(TriggerType::from_str("link"), TriggerType::Link);
        assert_eq!(TriggerType::from_str("file_type"), TriggerType::FileType);
        assert_eq!(TriggerType::from_str("manual"), TriggerType::Manual);
        assert_eq!(TriggerType::from_str("unknown"), TriggerType::Manual);
    }
}
