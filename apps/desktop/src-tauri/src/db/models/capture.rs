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
