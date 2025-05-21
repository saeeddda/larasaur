#!/bin/bash

# Set install target
BIN_DIR="$HOME/.local/bin/larasaur"
# Detect current shell and set RC_FILE accordingly
case "$SHELL" in
    */zsh) RC_FILE="$HOME/.zshrc" ;;
    */bash) RC_FILE="$HOME/.bashrc" ;;
    *) RC_FILE="$HOME/.profile" ;;
esac

# Default project root
LARASAUR_DIR="$(pwd)"

mkdir -p "$BIN_DIR"

echo "📦 Installing dev shortcuts"

# --------------------------------------
# Composer shortcut (c)
# --------------------------------------
cat <<EOF > "$BIN_DIR/c"
#!/bin/bash

CURRENT_PATH=\$(pwd)
FINAL_PATH=\$(realpath --relative-to="$(dirname "$LARASAUR_DIR")" "\$CURRENT_PATH")

docker exec -w /var/www/html/\$FINAL_PATH php-fpm composer "\$@"
EOF

# --------------------------------------
# NPM/Yarn shortcut (n)
# --------------------------------------
cat <<EOF > "$BIN_DIR/n"
#!/bin/bash

CURRENT_PATH=\$(pwd)
FINAL_PATH=\$(realpath --relative-to="$(dirname "$LARASAUR_DIR")" "\$CURRENT_PATH")

docker exec -w /projects/\$FINAL_PATH node npm "\$@"
EOF

# --------------------------------------
# Artisan shortcut (a)
# --------------------------------------
cat <<EOF > "$BIN_DIR/a"
#!/bin/bash

CURRENT_PATH=\$(pwd)
FINAL_PATH=\$(realpath --relative-to="$(dirname "$LARASAUR_DIR")" "\$CURRENT_PATH")

docker exec -w /var/www/html/\$FINAL_PATH php-fpm php artisan "\$@"
EOF

# --------------------------------------
# Addsite (addsite)
# --------------------------------------
cat <<EOF > "$BIN_DIR/addsite"
#!/bin/bash

CURRENT_PATH=\$(pwd)
FINAL_PATH=\$(realpath --relative-to="$(dirname "$LARASAUR_DIR")" "\$CURRENT_PATH")

CURRENT_FOLDER=\$(basename "\$CURRENT_PATH")
DOMAIN_NAME=\${1:-\$CURRENT_FOLDER}
DOMAIN=\$DOMAIN_NAME.local

NGINX_TEMPLATE="$LARASAUR_DIR/nginx/templates/project.conf.tpl"
NGINX_SITES="$LARASAUR_DIR/nginx/sites"
NGINX_OUTPUT="\$NGINX_SITES/\$DOMAIN.conf"

if [ ! -f "\$CURRENT_PATH/public/index.php" ]; then
    echo "❌ \$CURRENT_PATH/public/index.php not found"
    exit 1
fi

mkdir -p "\$NGINX_SITES"

sed \\
  -e "s|{{DOMAIN}}|\$DOMAIN|g" \\
  -e "s|{{PROJECT_RELATIVE}}|\$FINAL_PATH|g" \\
  "\$NGINX_TEMPLATE" > "\$NGINX_OUTPUT"

echo "✅ Created Nginx config for \$DOMAIN"
echo "📄 \$NGINX_OUTPUT"

if ! grep -q "127.0.0.1 \$DOMAIN" /etc/hosts; then
    echo "127.0.0.1 \$DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    echo "✅ Added \$DOMAIN to /etc/hosts"
fi

echo "🔁 Restarting nginx container"
docker restart nginx
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
echo "   c install               # composer install"
echo "   n run dev               # npm run dev"
echo "   a migrate               # artisan migrate"
echo "   addsite                 # generate config for mysite.local"
echo "   up / down / restart     # manage docker (runs from anywhere)"
echo ""
