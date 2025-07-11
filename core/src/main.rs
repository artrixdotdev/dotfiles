use clap::{Parser, Subcommand};
use std::path::PathBuf;

mod commands;
mod config;
mod renderer;

use commands::{daemon::DaemonCommand, render::RenderCommand};

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
struct Args {
    /// Root directory for all relative paths. Defaults to $HOME/dotfiles.
    #[arg(short, long, global = true)]
    root_dir: Option<PathBuf>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// Render Handlebars templates once
    Render(RenderCommand),
    /// Watch for changes and automatically re-render
    Daemon(DaemonCommand),
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    match args.command {
        Commands::Render(cmd) => cmd.execute(args.root_dir).await,
        Commands::Daemon(cmd) => cmd.execute(args.root_dir).await,
    }
}
