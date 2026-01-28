use serde::{Deserialize, Serialize};

use super::capture::Capture;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Trace {
    pub id: String,
    pub title: String,
    pub is_auto: bool,
    pub captures: Vec<Capture>,
    pub created_at: String,
    pub updated_at: String,
}

/// Capture-Trace relationship for positioning captures within a trace
#[allow(dead_code)] // Reserved for M2 trace management
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CaptureTrace {
    pub capture_id: String,
    pub trace_id: String,
    pub position: i32,
    pub created_at: String,
}
