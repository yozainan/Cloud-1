#!/bin/bash
set -e
set -x

if ! command -v wp &>/dev/null; then
  echo "[wordpress] Installing WP-CLI..."
  curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  mv wp-cli.phar /usr/local/bin/wp
fi

# Configure PHP-FPM to listen on TCP instead of socket
sed -i "s#listen = /run/php/php8.2-fpm.sock#listen = 0.0.0.0:${WORDPRESS_PORT}#" /etc/php/8.2/fpm/pool.d/www.conf

# Bootstrapping logic
if [ ! -f /var/www/html/wp-config.php ]; then
  echo "[wordpress] First run detected — bootstrapping..."

  # 1. Download WordPress via WP-CLI
  wp core download --path="/var/www/html" --allow-root

  # 2. Create wp-config.php with correct DB credentials BEFORE installing
  echo "[wordpress] Creating wp-config.php..."
  wp config create \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --path="/var/www/html" \
    --allow-root

  # 3. Inject Redis variables into wp-config.php safely
  wp config set WP_REDIS_HOST "redis" --path="/var/www/html" --allow-root
  wp config set WP_REDIS_PORT ${REDIS_PORT} --raw --path="/var/www/html" --allow-root
  wp config set WP_CACHE true --raw --path="/var/www/html" --allow-root

  # 4. Wait for MariaDB to be ready
  echo "[wordpress] Waiting for MariaDB..."
  until mysqladmin ping -h "${WORDPRESS_DB_HOST}" -u "${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" --silent; do
    sleep 2
  done
  echo "[wordpress] MariaDB is ready."

  # 5. Run the core installation
  echo "[wordpress] Running wp core install..."
  wp core install \
    --path="/var/www/html" \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root

  # 6. Install and enable Redis Object Cache
  echo "[wordpress] Installing Redis Object Cache plugin..."
  wp plugin install redis-cache --activate --path="/var/www/html" --allow-root 
  wp redis enable --path="/var/www/html" --allow-root

fi

# Fix permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "[wordpress] Starting PHP-FPM ${PHP_VERSION:-8.2}..."
exec php-fpm${PHP_VERSION:-8.2} -F
