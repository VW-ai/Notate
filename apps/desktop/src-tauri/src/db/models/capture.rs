use serde::{Deserialize, Serialize};

use super::tag::Tag;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum CaptureType {
    Thought,
    Link,
    File,
    Image,
}

impl CaptureType {
    pub fn as_str(&self) -> &'static str {
        match self {
            CaptureType::Thought => "thought",
            CaptureType::Link => "link",
            CaptureType::File => "file",
            CaptureType::Image => "image",
        }
    }

    pub fn from_str(s: &str) -> Self {
        match s {
            "thought" => CaptureType::Thought,
            "link" => CaptureType::Link,
            "file" => CaptureType::File,
            "image" => CaptureType::Image,
            _ => CaptureType::Thought,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Capture {
    pub id: String,
    #[serde(rename = "type")]
    pub capture_type: CaptureType,
    pub content: String,
    pub source_url: Option<String>,
    pub file_path: Option<String>,
    pub thumbnail_path: Option<String>,
    pub summary: Option<String>,
    pub tags: Vec<Tag>,
    pub primary_tag_id: Option<String>,
    pub created_at: String,
    pub updated_at: String,
    pub is_deleted: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateCaptureInput {
    #[serde(rename = "type")]
    pub capture_type: CaptureType,
    pub content: String,
    pub source_url: Option<String>,
    pub habit_id: Option<String>,
}

#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CapturePreview {
    pub id: String,
    #[serde(rename = "type")]
    pub capture_type: CaptureType,
    pub content: String,
    pub created_at: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_capture_type_as_str() {
        assert_eq!(CaptureType::Thought.as_str(), "thought");
        assert_eq!(CaptureType::Link.as_str(), "link");
        assert_eq!(CaptureType::File.as_str(), "file");
        assert_eq!(CaptureType::Image.as_str(), "image");
    }

    #[test]
    fn test_capture_type_from_str() {
        assert_eq!(CaptureType::from_str("thought"), CaptureType::Thought);
        assert_eq!(CaptureType::from_str("link"), CaptureType::Link);
        assert_eq!(CaptureType::from_str("file"), CaptureType::File);
        assert_eq!(CaptureType::from_str("image"), CaptureType::Image);
        // Unknown defaults to Thought
        assert_eq!(CaptureType::from_str("unknown"), CaptureType::Thought);
    }

    #[test]
    fn test_capture_type_serialization() {
        let thought = CaptureType::Thought;
        let json = serde_json::to_string(&thought).unwrap();
        assert_eq!(json, "\"thought\"");

        let link = CaptureType::Link;
        let json = serde_json::to_string(&link).unwrap();
        assert_eq!(json, "\"link\"");
    }

    #[test]
    fn test_create_capture_input_serialization() {
        let input = CreateCaptureInput {
            capture_type: CaptureType::Link,
            content: "Test content".to_string(),
            source_url: Some("https://example.com".to_string()),
            habit_id: None,
        };

        let json = serde_json::to_string(&input).unwrap();
        assert!(json.contains("\"type\":\"link\""));
        assert!(json.contains("\"content\":\"Test content\""));
        assert!(json.contains("\"sourceUrl\":\"https://example.com\""));
    }
}
