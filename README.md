# macOS Development Environment Bootstrap

A comprehensive, modular system for automating macOS development environment setup and configuration management.

## Overview

This repository provides a fully automated solution for setting up a macOS development environment from scratch. It handles everything from system preferences to development tools, using a modular architecture that makes it easy to customize and maintain.

## Key Features

- **🚀 One-Command Setup**: Bootstrap your entire development environment with a single command
- **📦 Modular Architecture**: Enable/disable components based on your needs
- **🔄 Idempotent**: Safe to run multiple times without side effects
- **🔗 Symlink-Based**: Configurations stay version-controlled while being accessible system-wide
- **🎯 Organized Structure**: Clear separation between different configuration types
- **🛠️ Extensive Tool Support**: Pre-configured for modern development workflows

## Quick Start

```bash
# Download and run the installer
curl https://raw.githubusercontent.com/jshreynolds/localetc/main/install.sh > install.sh
chmod 755 install.sh && ./install.sh YOUR_MACHINE_NAME

# Follow the interactive prompts
```

## Project Structure

```
etc/
├── install.sh          # Main bootstrap script
├── install/            # Installation scripts
│   ├── enabled/        # Active installation modules (numbered for order)
│   └── disabled/       # Available but inactive modules
├── dotfiles/           # Configuration files to be symlinked
│   ├── brew/           # Homebrew package lists (core, personal, work)
│   ├── config/         # Application configurations
│   ├── docker/         # Docker settings
│   ├── mise            # Development runtime manager config
│   └── zshrc           # Shell configuration
├── env/                # Environment setup scripts
│   ├── enabled/        # Active environment configurations
│   └── disabled/       # Available but inactive configurations
├── bin/                # Custom utility scripts
└── setenv              # Environment loader script
```

## Installation Process

### 1. Bootstrap Phase (`install.sh`)
- Validates prerequisites and sets up SSH keys
- Installs Xcode Command Line Tools
- Clones this repository to `~/etc`
- Executes all scripts in `install/enabled/`

### 2. Installation Modules (`install/enabled/`)
Scripts are numbered to control execution order:

- **00-rosetta.sh**: Apple Silicon compatibility layer
- **01-brew.sh**: Homebrew and packages (core + optional personal/work)
- **60-dotfiles.sh**: Symlinks all configuration files
- **90-92-macos-*.sh**: System preferences and UI customization
- **93-xcode.sh**: Additional Xcode tools
- **96-mise.sh**: Development environment manager
- **97-zsh.sh**: Shell setup and configuration
- **98-manual.sh**: Instructions for manual steps
- **99-welcome.sh**: Post-installation summary

### 3. Configuration Deployment
- Creates symlinks from `~/etc/dotfiles/*` to appropriate system locations
- Sets up development tools via mise (Node.js, Python, Go, etc.)
- Configures shell environment with modular scripts

## Key Components

### Package Management
- **Homebrew**: System packages, GUI applications, and fonts
- **mise**: Language runtimes and development tools
- Modular Brewfiles for different use cases (core/personal/work)

### Development Tools
Automatically installs and manages:
- Languages: Node.js, Python, Go, Rust, Java, Ruby, etc.
- Tools: Docker, Kubernetes tools, Terraform, AWS CLI
- Databases: PostgreSQL, Redis, Kafka
- And many more via mise configuration

### Shell Environment
- Minimal `.zshrc` that sources modular environment scripts
- Organized environment configurations in `env/enabled/`
- Custom PATH management and useful aliases
- Integration with modern CLI tools (starship, zoxide, fzf)

### Application Configurations
Pre-configured settings for:
- Alacritty (terminal emulator)
- Zellij (terminal multiplexer)
- GitHub CLI
- Docker
- Cheat (command cheatsheets)

## Customization

### Enabling/Disabling Components
Move scripts between `enabled/` and `disabled/` directories:
```bash
# Disable a component
mv install/enabled/93-xcode.sh install/disabled/

# Enable an environment configuration
mv env/disabled/10_python.sh env/enabled/
```

### Adding New Tools
1. For Homebrew packages: Edit `dotfiles/brew/Brewfile.*`
2. For development runtimes: Add to `dotfiles/mise`
3. For custom scripts: Add to `bin/`
4. For environment configs: Create numbered scripts in `env/enabled/`

## Manual Steps Required

Some configurations cannot be automated and require _some_ manual intervention:
- App Store applications
- System security settings requiring user approval
- Application-specific login/authentication

These are documented in the installation output.

## General Maintenance

```bash
# Update all Homebrew packages
brew update && brew upgrade

# Update development tools
mise upgrade

# Pull latest configuration changes
cd ~/etc && git pull
```

## Contributing

Feel free to fork and customize for your own use. The modular structure makes it easy to add or remove components based on your needs.
