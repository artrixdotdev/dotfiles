use handlebars::{Handlebars, handlebars_helper};
use serde_json::Value;
use std::{collections::HashMap, fs, path::PathBuf};
use walkdir::WalkDir;

use crate::config::DISCLAIMER;

pub struct TemplateRenderer {
    handlebars: Handlebars<'static>,
}

impl TemplateRenderer {
    pub fn new() -> Self {
        let mut hb = Handlebars::new();
        hb.register_escape_fn(handlebars::no_escape);

        // Math helpers
        handlebars_helper!(mul: |a: f32, b: f32| a * b);
        handlebars_helper!(add: |a: f32, b: f32| a + b);
        handlebars_helper!(sub: |a: f32, b: f32| a - b);
        handlebars_helper!(div: |a: f32, b: f32| a / b);

        hb.register_helper("mul", Box::new(mul));
        hb.register_helper("add", Box::new(add));
        hb.register_helper("sub", Box::new(sub));
        hb.register_helper("div", Box::new(div));

        hb.set_prevent_indent(true);

        Self { handlebars: hb }
    }

    pub fn render_niri_config(
        &self,
        root_dir: &PathBuf,
        settings_file: &PathBuf,
        niri_dir: &PathBuf,
        main_template: &PathBuf,
        output_file: &PathBuf,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let settings_path = root_dir.join(settings_file);
        let niri_dir_full = root_dir.join(niri_dir);
        let niri_cfg_dir = niri_dir_full.join("config");
        let main_tpl_path = niri_dir_full.join(main_template);
        let output_path = niri_dir_full.join(output_file);

        println!("Reading settings from: {}", settings_path.display());
        let settings_content = fs::read_to_string(&settings_path)?;
        let settings: Value = serde_json::from_str(&settings_content)?;

        let mut configs: Vec<Value> = Vec::new();

        if !niri_cfg_dir.exists() || !niri_cfg_dir.is_dir() {
            return Err(format!(
                "Niri config directory not found or not a directory: {}",
                niri_cfg_dir.display()
            )
            .into());
        }

        println!("Processing templates in: {}", niri_cfg_dir.display());

        for entry in WalkDir::new(&niri_cfg_dir)
            .min_depth(1)
            .max_depth(1)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            if path.is_file() && path.extension().map_or(false, |ext| ext == "kdl") {
                println!("Rendering template: {}", path.display());
                let mut data = HashMap::new();
                data.insert("settings", &settings);
                let tpl_content = fs::read_to_string(path)?;
                let rendered = self.handlebars.render_template(&tpl_content, &data)?;

                let cfg_obj = serde_json::json!({
                    "path": path.strip_prefix(&niri_cfg_dir)
                                .unwrap_or(path)
                                .display()
                                .to_string(),
                    "text": rendered,
                });
                configs.push(cfg_obj);
            }
        }

        println!("Rendering main template: {}", main_tpl_path.display());
        let main_tpl_content = fs::read_to_string(&main_tpl_path)?;

        let mut main_data = HashMap::new();
        main_data.insert("configs", serde_json::to_value(&configs)?);
        main_data.insert("settings", settings);
        let mut final_config = DISCLAIMER.to_string();
        final_config.push_str(
            &self
                .handlebars
                .render_template(&main_tpl_content, &main_data)?,
        );

        println!("Writing final config to: {}", output_path.display());
        fs::write(&output_path, final_config)?;

        println!(
            "config.kdl generated successfully at {}",
            output_path.display()
        );

        Ok(())
    }
}
