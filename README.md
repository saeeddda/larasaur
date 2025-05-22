# Unified Docker Development Environment for Laravel Projects

![Larasaur](art/cover/low-quality.png)

A flexible, efficient Docker-based development environment that allows you to run multiple Laravel projects from different directories under a single environment setup.

## ✨ Key Benefits Compared to Laravel Sail, Longhorn, Herd

- **One environment for all projects**: Unlike Sail which requires setup per project, this solution serves all your Laravel projects from a single Docker environment
- **Directory structure flexibility**: Works with projects in any location under your project root
- **Resource efficiency**: Runs a single set of containers for all projects instead of duplicating services per project
- **Easy project switching**: No need to restart containers when switching between projects
- **CLI shortcuts**: Simple commands (`a`, `c`, `n`) for artisan, composer, and npm across any project
- **Configurable Nginx**: Easy virtual host management with automatic site configuration
- **Complete stack**: PHP-FPM, Nginx, MySQL, Redis, Mailhog and Node.js in one setup

## 🚀 Getting Started

### Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/mohaphez/larasaur.git ~/projects/larasaur
   cd ~/projects/larasaur
   ```

2. Start the environment:

   ```bash
   docker compose up -d
   ```

3. Install the CLI shortcuts:
   - if you are on mac, make sure to run `brew install coreutils`

   ```bash
   chmod +x install-dev-shortcuts.sh
   ./install-dev-shortcuts.sh # rerun this when you move 'larasaur' to a different directory
   ```

### Directory Structure Example

```
~/projects/
  ├── larasaur/            # This repository
  ├── x/
  │   ├── a-laravel/       # Laravel project 1
  │   └── b-laravel/       # Laravel project 2
  ├── y/
  │   ├── c-laravel/       # Laravel project 3
  │   └── v-laravel/       # Laravel project 4
  └── z/
      ├── h-old-laravel/   # Legacy Laravel project
      └── b-new-laravel/   # New Laravel project
```

## 🛠️ Usage

### Adding a New Site

Navigate to your Laravel project and run:

```bash
# Basic usage - uses current folder name
addsite

# Specify a custom domain name
addsite projectname

# Specify a custom port (will add to nginx configuration)
addsite --port=8000 projectname

# Port can be specified before or after the domain name
addsite projectname --port=8000
```

This will:
1. Create an Nginx config for `projectname.local`
2. Add entry to your hosts file
3. If a custom port is specified:
   - Configure Nginx to listen on that port
   - Add the port to the nginx service in docker-compose.yml
   - Prompt you to restart the containers to apply changes

> **Note**: When using a custom port, access your site at `http://projectname.local:8000` (replace 8000 with your specified port)

### Command Shortcuts

Use these shortcuts from any project directory:

```bash
a migrate                  # Run artisan commands
c require package/name     # Run composer commands
n run dev                  # Run npm commands
```

### Container Management

```bash
up                         # Start all containers
down                       # Stop all containers
restart                    # Restart all containers
```

## 📦 Included Services

- **PHP-FPM 8.3** with essential extensions
- **Nginx** with per-project virtual hosts
- **MySQL 8.0**
- **Redis**
- **Mailhog** for email testing
- **Node.js 18** for frontend development
- **Composer** for PHP package management

## 🔧 Configuration

You can customize the environment by editing:

- `docker-compose.yml` - Service configuration
- `Dockerfile` - PHP extensions and dependencies
- `nginx/templates/project.conf.tpl` - Nginx site template

## ⚠️ How to Uninstall

- stop docker `stop`
- remove larasaur from your shellrc file `~/.bashrc, ~/.zshrc`
- remove the bin files `rm -rf ~/.local/bin/larasaur`
- cleanup your hosts file `/etc/hosts`
- remove larasaur directory `rm -rf path/to/larasaur`

## 🎨 Branding & Assets

<p align="center">
  <img src="art/logo/colored/framed.svg" width="250" alt="Larasaur Logo">
</p>

This project uses a comprehensive branding system with various logo types and assets:

- **Logos**: Available in colored, type, and solid versions with both framed and frameless options
- **Typography**: Uses Google Font "Poppins" throughout the UI for a clean, modern look
- **Cover Images**: High-quality artwork for documentation and marketing materials

Find all visual assets in the [`art/`](art/) directory, with [detailed documentation](art/readme.md) on usage guidelines.

## 📄 License

This project is open-sourced software licensed under the MIT license.
