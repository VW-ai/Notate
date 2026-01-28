use crate::config::AppConfig;
use tauri::State;

#[tauri::command]
pub fn get_config(config: State<'_, AppConfig>) -> AppConfig {
    tracing::debug!("IPC: get_config called");
    config.inner().clone()
}
