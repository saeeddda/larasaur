#!/bin/bash

# Set install target
BIN_DIR="$HOME/.local/bin/larasaur"
mkdir -p "$BIN_DIR"

# Detect current shell and set RC_FILE accordingly
case "$SHELL" in
    */zsh) RC_FILE="$HOME/.zshrc" ;;
    */bash) RC_FILE="$HOME/.bashrc" ;;
    *) RC_FILE="$HOME/.profile" ;;
esac

# Check if running on macOS (Darwin) or Linux
if [[ "$(uname)" == "Darwin" ]]; then
    REALPATH_CMD="grealpath"
else
    REALPATH_CMD="realpath"
fi

if ! command -v $REALPATH_CMD &> /dev/null; then
    echo "Error: $REALPATH_CMD is not installed"
    exit 1
fi

# Default project root
LARASAUR_DIR="$(pwd)"

echo "📦 Installing dev shortcuts"

# --------------------------------------
# Composer shortcut (c)
# --------------------------------------
cat <<EOF > "$BIN_DIR/c"
#!/bin/bash

CURRENT_PATH=\$(pwd)
FINAL_PATH=\$($REALPATH_CMD --relative-to="$(dirname "$LARASAUR_DIR")" "\$CURRENT_PATH")

docker exec -w /var/www/html/\$FINAL_PATH php-fpm composer "\$@"
EOF

# --------------------------------------
# NPM/Yarn shortcut (n)
# --------------------------------------
cat <<EOF > "$BIN_DIR/n"
#!/bin/bash

CURRENT_PATH=\$(pwd)
FINAL_PATH=\$($REALPATH_CMD --relative-to="$(dirname "$LARASAUR_DIR")" "\$CURRENT_PATH")

docker exec -w /projects/\$FINAL_PATH node npm "\$@"
EOF

# --------------------------------------
# Artisan shortcut (a)
# --------------------------------------
cat <<EOF > "$BIN_DIR/a"
#!/bin/bash

CURRENT_PATH=\$(pwd)
FINAL_PATH=\$($REALPATH_CMD --relative-to="$(dirname "$LARASAUR_DIR")" "\$CURRENT_PATH")

docker exec -w /var/www/html/\$FINAL_PATH php-fpm php artisan "\$@"
EOF

# --------------------------------------
# Addsite (addsite)
# --------------------------------------
cat <<EOF > "$BIN_DIR/addsite"
#!/bin/bash

CURRENT_PATH=\$(pwd)
FINAL_PATH=\$($REALPATH_CMD --relative-to="$(dirname "$LARASAUR_DIR")" "\$CURRENT_PATH")

# Parse command line arguments
DOMAIN_NAME=""
PORT="80"

while [[ \$# -gt 0 ]]; do
    case \$1 in
        --port=*)
            PORT="\${1#*=}"
            shift
            ;;
        *)
            if [ -z "\$DOMAIN_NAME" ]; then
                DOMAIN_NAME="\$1"
            fi
            shift
            ;;
    esac
done

# If no domain name provided, use current folder name
if [ -z "\$DOMAIN_NAME" ]; then
    DOMAIN_NAME=\$(basename "\$CURRENT_PATH")
fi

DOMAIN=\$DOMAIN_NAME.local

NGINX_TEMPLATE="$LARASAUR_DIR/nginx/templates/project.conf.tpl"
NGINX_SITES="$LARASAUR_DIR/nginx/sites"
NGINX_OUTPUT="\$NGINX_SITES/\$DOMAIN.conf"

if [ ! -f "\$CURRENT_PATH/public/index.php" ]; then
    echo "❌ \$CURRENT_PATH/public/index.php not found"
    exit 1
fi

mkdir -p "\$NGINX_SITES"

# Create nginx config with custom port
if [ "\$PORT" != "80" ]; then
    EXTRA_PORT="listen \$PORT;"
else
    EXTRA_PORT=""
fi

sed \\
  -e "s|{{DOMAIN}}|\$DOMAIN|g" \\
  -e "s|{{PROJECT_RELATIVE}}|\$FINAL_PATH|g" \\
  -e "s|{{EXTRA_PORT}}|\$EXTRA_PORT|g" \\
  "\$NGINX_TEMPLATE" > "\$NGINX_OUTPUT"

if [ "\$PORT" = "80" ]; then
    echo "✅ Created Nginx config for \$DOMAIN"
else
    echo "✅ Created Nginx config for \$DOMAIN (accessible on both port 80 and port \$PORT)"
fi
echo "📄 \$NGINX_OUTPUT"

if ! grep -q "127.0.0.1 \$DOMAIN" /etc/hosts; then
    echo "127.0.0.1 \$DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    echo "✅ Added \$DOMAIN to /etc/hosts"
fi

# Update docker-compose.yml to include the new port
if [ "\$PORT" != "80" ]; then
    COMPOSE_FILE="$LARASAUR_DIR/docker-compose.yml"
    if ! grep -q "\\- \"\$PORT:\$PORT\"" "\$COMPOSE_FILE"; then
        # Use awk to add the port only to the nginx service
        awk -v port="\$PORT" -v domain="\$DOMAIN" '
        /^  nginx:/ { in_nginx=1 }
        /^  [a-z]/ && !/^  nginx:/ { in_nginx=0 }
        /ports:/ && in_nginx {
            print \$0
            print "      - \"" port ":" port "\"   # Added by addsite for " domain
            next
        }
        { print }
        ' "\$COMPOSE_FILE" > "\$COMPOSE_FILE.tmp" && mv "\$COMPOSE_FILE.tmp" "\$COMPOSE_FILE"

        echo "✅ Added port \$PORT to nginx service in docker-compose.yml"
        echo "🔄 Please run 'restart' to apply the changes"
    fi
else
    echo "🔁 Restarting nginx container"
    docker restart nginx
fi
EOF

# --------------------------------------
# Docker Compose shortcuts
# --------------------------------------
cat <<EOF > "$BIN_DIR/up"
#!/bin/bash

# Always change to the dev-env directory no matter where we are
cd "$LARASAUR_DIR" && docker compose up -d
EOF

cat <<EOF > "$BIN_DIR/down"
#!/bin/bash

# Always change to the dev-env directory no matter where we are
cd "$LARASAUR_DIR" && docker compose down
EOF

cat <<EOF > "$BIN_DIR/restart"
#!/bin/bash

# Always change to the dev-env directory no matter where we are
cd "$LARASAUR_DIR" && docker compose down && docker compose up -d
EOF

# --------------------------------------
# Permissions
# --------------------------------------
chmod +x "$BIN_DIR/"{c,n,a,addsite,up,down,restart}

# Add ~/.local/bin/larasaur to PATH if needed
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo -e "\n# added by larasaur\nexport PATH=\"$BIN_DIR:\$PATH\"" | tee -a "$RC_FILE"
    echo "✅ Added $BIN_DIR to PATH in $RC_FILE"
fi

# --------------------------------------
# Done
# --------------------------------------
echo ""
echo "✅ Dev shortcuts installed!"
echo ""
echo "🧰 Usage examples:"
echo "   c install                       # composer install"
echo "   n run dev                       # npm run dev"
echo "   a migrate                       # artisan migrate"
echo "   addsite                         # generate config for mysite.local"
echo "   addsite mysite                  # generate config for mysite.local"
echo "   addsite --port=8000 mysite      # generate config with custom port"
echo "   up / down / restart             # manage docker (runs from anywhere)"
echo ""
