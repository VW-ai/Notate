mod commands;
mod config;
mod db;
mod errors;
mod services;

use tauri::Manager;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // Initialize logging
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "notate=debug,info".into()),
        )
        .init();

    tauri::Builder::default()
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .setup(|app| {
            tracing::info!("Notate starting, version: {}", env!("CARGO_PKG_VERSION"));

            // Load configuration first (needed for storage init)
            let cfg = match config::AppConfig::load_defaults() {
                Ok(cfg) => {
                    tracing::info!("Config loaded from embedded defaults.yaml");
                    cfg
                }
                Err(e) => {
                    tracing::error!("Failed to load config: {}", e);
                    return Err(Box::new(e) as Box<dyn std::error::Error>);
                }
            };

            // Initialize database
            let app_handle = app.handle().clone();
            tauri::async_runtime::block_on(async {
                if let Err(e) = db::init(&app_handle).await {
                    tracing::error!("Failed to initialize database: {}", e);
                }
            });

            // Initialize storage directories
            match db::get_app_dir() {
                Ok(app_dir) => {
                    if let Err(e) =
                        services::storage_service::init_directories(&app_dir, &cfg.storage)
                    {
                        tracing::error!("Failed to initialize storage directories: {}", e);
                    }
                }
                Err(e) => {
                    tracing::error!("Failed to get app directory: {}", e);
                }
            }

            // Store config in app state
            app.manage(cfg);

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::capture::create_capture,
            commands::capture::get_capture,
            commands::capture::get_captures,
            commands::capture::update_capture,
            commands::capture::delete_capture,
            commands::config::get_config,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
