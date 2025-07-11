use clap::Args;
use std::path::PathBuf;

use crate::{config::get_root_dir, renderer::TemplateRenderer};

/// Render Handlebars templates once
#[derive(Args, Debug)]
pub struct RenderCommand {
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
}

impl RenderCommand {
    pub async fn execute(
        &self,
        root_dir: Option<PathBuf>,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let root = get_root_dir(root_dir);
        println!("Root directory: {}", root.display());

        let renderer = TemplateRenderer::new();
        renderer.render_niri_config(
            &root,
            &self.settings_file,
            &self.niri_dir,
            &self.main_template,
            &self.output_file,
        )?;

        Ok(())
    }
}
