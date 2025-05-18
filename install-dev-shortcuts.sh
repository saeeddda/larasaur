#!/bin/bash

# Set install target
BIN_DIR="$HOME/.local/bin"
RC_FILE="$HOME/.bashrc"
[[ -n "$ZSH_VERSION" ]] && RC_FILE="$HOME/.zshrc"

# Default project root
DEFAULT_PROJECT_ROOT="$HOME/projects"
PROJECT_ROOT="${PROJECT_ROOT:-$DEFAULT_PROJECT_ROOT}"

mkdir -p "$BIN_DIR"

echo "📦 Installing dev shortcuts using project root: $PROJECT_ROOT"

# --------------------------------------
# Composer shortcut (c)
# --------------------------------------
cat <<EOF > "$BIN_DIR/c"
#!/bin/bash
project_path=\$(realpath --relative-to="$PROJECT_ROOT" "\$(pwd | grep -o "$PROJECT_ROOT.*")")
docker exec -w /var/www/html/\$project_path php-fpm composer "\$@"
EOF

# --------------------------------------
# NPM/Yarn shortcut (n)
# --------------------------------------
cat <<EOF > "$BIN_DIR/n"
#!/bin/bash
project_path=\$(realpath --relative-to="$PROJECT_ROOT" "\$(pwd | grep -o "$PROJECT_ROOT.*")")
docker exec -w /projects/\$project_path node npm "\$@"
EOF

# --------------------------------------
# Artisan shortcut (a)
# --------------------------------------
cat <<EOF > "$BIN_DIR/a"
#!/bin/bash
project_path=\$(realpath --relative-to="$PROJECT_ROOT" "\$(pwd | grep -o "$PROJECT_ROOT.*")")
docker exec -w /var/www/html/\$project_path php-fpm php artisan "\$@"
EOF

# --------------------------------------
# Addsite (addsite)
# --------------------------------------
cat <<'EOF' > "$BIN_DIR/addsite"
#!/bin/bash

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/projects/dev-env}"
CURRENT_PATH=$(pwd | grep -o "$PROJECT_ROOT.*")

if [[ -z "$CURRENT_PATH" ]]; then
    echo "❌ You must be inside a project within $PROJECT_ROOT"
    exit 1
fi

REL_PATH=${CURRENT_PATH#$PROJECT_ROOT/}
DOMAIN=${1:-$(basename "$CURRENT_PATH")}

NGINX_TEMPLATE="$PROJECT_ROOT/nginx/templates/project.conf.tpl"
NGINX_SITES="$PROJECT_ROOT/nginx/sites"
NGINX_OUTPUT="$NGINX_SITES/$DOMAIN.local.conf"

if [ ! -f "$CURRENT_PATH/public/index.php" ]; then
    echo "❌ $CURRENT_PATH/public/index.php not found"
    exit 1
fi

mkdir -p "$NGINX_SITES"

sed \
  -e "s|{{DOMAIN}}|$DOMAIN.local|g" \
  -e "s|{{PROJECT_RELATIVE}}|$REL_PATH|g" \
  "$NGINX_TEMPLATE" > "$NGINX_OUTPUT"

echo "✅ Created Nginx config for $DOMAIN.local"
echo "📄 $NGINX_OUTPUT"

if ! grep -q "127.0.0.1 $DOMAIN.local" /etc/hosts; then
    echo "127.0.0.1 $DOMAIN.local" | sudo tee -a /etc/hosts > /dev/null
    echo "✅ Added $DOMAIN.local to /etc/hosts"
fi

echo "🔁 Restart nginx container: docker restart nginx"
EOF

# --------------------------------------
# Docker Compose shortcuts
# --------------------------------------
cat <<EOF > "$BIN_DIR/up"
#!/bin/bash
cd "$PROJECT_ROOT" && docker compose up -d
EOF

cat <<EOF > "$BIN_DIR/down"
#!/bin/bash
cd "$PROJECT_ROOT" && docker compose down
EOF

cat <<EOF > "$BIN_DIR/restart"
#!/bin/bash
cd "$PROJECT_ROOT" && docker compose down && docker compose up -d
EOF

# --------------------------------------
# Permissions
# --------------------------------------
chmod +x "$BIN_DIR/"{c,n,a,addsite,up,down,restart}

# Add ~/.local/bin to PATH if needed
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$RC_FILE"
    echo "✅ Added $BIN_DIR to PATH in $RC_FILE"
    source "$RC_FILE"
fi

# --------------------------------------
# Done
# --------------------------------------
echo ""
echo "✅ Dev shortcuts installed!"
echo ""
echo "🧰 Usage examples:"
echo "   c install                  # composer install"
echo "   n run dev                  # npm run dev"
echo "   a migrate                  # artisan migrate"
echo "   addsite mysite             # generate config for mysite.local"
echo "   up / down / restart        # manage docker (runs from \$PROJECT_ROOT)"
echo ""
echo "ℹ️ You can override the default path like:"
echo "   export PROJECT_ROOT=~/my/laravel-env"
echo "   ./install-devshorts.sh"
echo ""

