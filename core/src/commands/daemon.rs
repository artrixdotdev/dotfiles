use clap::Args;
use notify::{Config, Event, RecommendedWatcher, RecursiveMode, Watcher};
use std::{
    path::PathBuf,
    sync::mpsc,
    time::{Duration, Instant},
};
use tokio::time::sleep;

use crate::{config::get_root_dir, renderer::TemplateRenderer};

/// Watch for changes and automatically re-render
#[derive(Args, Debug)]
pub struct DaemonCommand {
    /// Path to the settings.json file, relative to root_dir.
    #[arg(short, long, default_value = "settings.json")]
    settings_file: PathBuf,

    /// Path to the directory containing Niri config Handlebars templates, relative to root_dir.
    #[arg(short, long, default_value = ".config/niri")]
    niri_dir: PathBuf,

    /// Path to the main config.kdl.hbs template, relative to root_dir.
    #[arg(short, long, default_value = "config.kdl.hbs")]
    main_template: PathBuf,

    /// Path where the final config.kdl should be written, relative to root_dir.
    #[arg(short, long, default_value = "config.kdl")]
    output_file: PathBuf,

    /// Debounce delay in milliseconds to avoid excessive re-renders
    #[arg(long, default_value = "500")]
    debounce_ms: u64,
}

impl DaemonCommand {
    pub async fn execute(
        &self,
        root_dir: Option<PathBuf>,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let root = get_root_dir(root_dir);
        println!("Root directory: {}", root.display());

        let renderer = TemplateRenderer::new();

        // Initial render
        println!("Performing initial render...");
        if let Err(e) = renderer.render_niri_config(
            &root,
            &self.settings_file,
            &self.niri_dir,
            &self.main_template,
            &self.output_file,
        ) {
            eprintln!("Initial render failed: {}", e);
        }

        // Set up file watcher
        let (tx, rx) = mpsc::channel();
        let mut watcher = RecommendedWatcher::new(tx, Config::default())?;

        // Watch directories and files
        let settings_path = root.join(&self.settings_file);
        let niri_path = root.join(&self.niri_dir);
        let services_path = root.join("services");

        println!("Watching for changes in:");
        println!("  - {}", settings_path.display());
        println!("  - {}", niri_path.display());
        println!("  - {}", services_path.display());

        watcher.watch(&settings_path, RecursiveMode::NonRecursive)?;
        watcher.watch(&niri_path, RecursiveMode::Recursive)?;
        if services_path.exists() {
            watcher.watch(&services_path, RecursiveMode::Recursive)?;
        }

        let mut last_render = Instant::now();
        let debounce_duration = Duration::from_millis(self.debounce_ms);

        println!("Daemon started. Press Ctrl+C to stop.");

        loop {
            match rx.try_recv() {
                Ok(Ok(event)) => {
                    if self.should_trigger_render(&event) {
                        let now = Instant::now();
                        if now.duration_since(last_render) >= debounce_duration {
                            println!("File change detected, re-rendering...");
                            if let Err(e) = renderer.render_niri_config(
                                &root,
                                &self.settings_file,
                                &self.niri_dir,
                                &self.main_template,
                                &self.output_file,
                            ) {
                                eprintln!("Render failed: {}", e);
                            }
                            last_render = now;
                        }
                    }
                }
                Ok(Err(e)) => eprintln!("Watch error: {}", e),
                Err(mpsc::TryRecvError::Empty) => {
                    // No events, sleep briefly
                    sleep(Duration::from_millis(100)).await;
                }
                Err(mpsc::TryRecvError::Disconnected) => {
                    eprintln!("Watcher disconnected");
                    break;
                }
            }
        }

        Ok(())
    }

    fn should_trigger_render(&self, event: &Event) -> bool {
        use notify::EventKind;

        match event.kind {
            EventKind::Create(_) | EventKind::Modify(_) | EventKind::Remove(_) => {
                // Check if any of the paths are relevant
                event.paths.iter().any(|path| {
                    // Skip temporary files and hidden files
                    if let Some(name) = path.file_name() {
                        let name_str = name.to_string_lossy();
                        if name_str.starts_with('.') && !name_str.ends_with(".json") {
                            return false;
                        }
                        if name_str.contains("~") || name_str.contains(".tmp") {
                            return false;
                        }
                    }

                    // Check file extensions we care about
                    if let Some(ext) = path.extension() {
                        let ext_str = ext.to_string_lossy();
                        matches!(ext_str.as_ref(), "json" | "kdl" | "hbs" | "service")
                    } else {
                        false
                    }
                })
            }
            _ => false,
        }
    }
}
