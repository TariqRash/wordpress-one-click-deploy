FROM wordpress:apache

# Install necessary tools
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    vim \
    nano \
    curl \
    wget \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Arabic language support
RUN apt-get update && apt-get install -y locales \
    && echo "ar_SA.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen ar_SA.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ar_SA.UTF-8
ENV LANGUAGE=ar_SA:ar
ENV LC_ALL=ar_SA.UTF-8

# Enable Apache modules for rewrite and headers
RUN a2enmod rewrite headers remoteip

# Create custom Apache configuration for dynamic PORT
RUN echo '<VirtualHost *:${PORT}>' > /etc/apache2/sites-available/000-default.conf && \
    echo '    ServerAdmin webmaster@localhost' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    DocumentRoot /var/www/html' >> /etc/apache2/sites-available/000-default.conf && \
    echo '' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    # Trust X-Forwarded-Proto from Render proxy' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    SetEnvIf X-Forwarded-Proto "https" HTTPS=on' >> /etc/apache2/sites-available/000-default.conf && \
    echo '' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    <Directory /var/www/html>' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        Options Indexes FollowSymLinks' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/000-default.conf && \
    echo '' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

# Create custom ports.conf that uses PORT env variable
RUN echo 'Listen ${PORT}' > /etc/apache2/ports.conf

# Create entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Use PORT from Render or default to 80' >> /entrypoint.sh && \
    echo 'export PORT=${PORT:-80}' >> /entrypoint.sh && \
    echo 'echo "Starting Apache on port $PORT"' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Wait for database' >> /entrypoint.sh && \
    echo 'if [ -n "$WORDPRESS_DB_HOST" ]; then' >> /entrypoint.sh && \
    echo '    echo "Waiting for database..."' >> /entrypoint.sh && \
    echo '    until mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent 2>/dev/null; do' >> /entrypoint.sh && \
    echo '        echo "Database not ready, waiting..."' >> /entrypoint.sh && \
    echo '        sleep 2' >> /entrypoint.sh && \
    echo '    done' >> /entrypoint.sh && \
    echo '    echo "Database is ready!"' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Create wp-config.php with HTTPS support if it does not exist' >> /entrypoint.sh && \
    echo 'if [ ! -f /var/www/html/wp-config.php ] && [ -f /var/www/html/wp-config-sample.php ]; then' >> /entrypoint.sh && \
    echo '    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php' >> /entrypoint.sh && \
    echo '    ' >> /entrypoint.sh && \
    echo '    # Add HTTPS detection before the stop editing line' >> /entrypoint.sh && \
    echo '    sed -i "/stop editing/i\\\\" /var/www/html/wp-config.php' >> /entrypoint.sh && \
    echo '    sed -i "/stop editing/i// Force HTTPS when behind Render proxy" /var/www/html/wp-config.php' >> /entrypoint.sh && \
    echo '    sed -i "/stop editing/i if (isset(\$_SERVER['"'"'HTTP_X_FORWARDED_PROTO'"'"']) && \$_SERVER['"'"'HTTP_X_FORWARDED_PROTO'"'"'] === '"'"'https'"'"') {" /var/www/html/wp-config.php' >> /entrypoint.sh && \
    echo '    sed -i "/stop editing/i\    \$_SERVER['"'"'HTTPS'"'"'] = '"'"'on'"'"';" /var/www/html/wp-config.php' >> /entrypoint.sh && \
    echo '    sed -i "/stop editing/i }" /var/www/html/wp-config.php' >> /entrypoint.sh && \
    echo '    sed -i "/stop editing/i\\\\" /var/www/html/wp-config.php' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Execute WordPress entrypoint' >> /entrypoint.sh && \
    echo 'exec docker-entrypoint.sh apache2-foreground' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

# Expose PORT (Render will inject the actual port number)
EXPOSE ${PORT:-80}

ENTRYPOINT ["/entrypoint.sh"]
