FROM wordpress:latest

# Install additional tools
RUN apt-get update && apt-get install -y \
    vim \
    nano \
    curl \
    wget \
    git \
    unzip \
    ssl-cert \
    && rm -rf /var/lib/apt/lists/*

# Arabic language support
RUN apt-get update && apt-get install -y locales \
    && echo "ar_SA.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen ar_SA.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ar_SA.UTF-8
ENV LANGUAGE=ar_SA:ar
ENV LC_ALL=ar_SA.UTF-8

# Enable Apache SSL module and required modules
RUN a2enmod ssl \
    && a2enmod rewrite \
    && a2enmod headers \
    && a2enmod socache_shmcb

# Create self-signed SSL certificate (for development/fallback)
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/apache-selfsigned.key \
    -out /etc/ssl/certs/apache-selfsigned.crt \
    -subj "/C=SA/ST=Riyadh/L=Riyadh/O=Holberton/OU=IT/CN=localhost"

# Configure Apache for both HTTP and HTTPS
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf && \
    echo '    ServerAdmin webmaster@localhost' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    DocumentRoot /var/www/html' >> /etc/apache2/sites-available/000-default.conf && \
    echo '' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    # Redirect to HTTPS if X-Forwarded-Proto is not set (for Railway/Render)' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    RewriteEngine On' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    RewriteCond %{HTTP:X-Forwarded-Proto} !https' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    RewriteCond %{HTTPS} off' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]' >> /etc/apache2/sites-available/000-default.conf && \
    echo '' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

# Configure HTTPS VirtualHost
RUN echo '<VirtualHost *:443>' > /etc/apache2/sites-available/default-ssl.conf && \
    echo '    ServerAdmin webmaster@localhost' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    DocumentRoot /var/www/html' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    SSLEngine on' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    # Security headers' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    Header always set X-Frame-Options "SAMEORIGIN"' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    Header always set X-Content-Type-Options "nosniff"' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    Header always set X-XSS-Protection "1; mode=block"' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    <Directory /var/www/html>' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '        Options Indexes FollowSymLinks' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/default-ssl.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/default-ssl.conf

# Enable SSL site
RUN a2ensite default-ssl

# Update ports.conf to listen on both 80 and 443
RUN echo 'Listen 80' > /etc/apache2/ports.conf && \
    echo '<IfModule ssl_module>' >> /etc/apache2/ports.conf && \
    echo '    Listen 443' >> /etc/apache2/ports.conf && \
    echo '</IfModule>' >> /etc/apache2/ports.conf && \
    echo '<IfModule mod_gnutls.c>' >> /etc/apache2/ports.conf && \
    echo '    Listen 443' >> /etc/apache2/ports.conf && \
    echo '</IfModule>' >> /etc/apache2/ports.conf

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

# Expose both HTTP and HTTPS ports
EXPOSE 80 443

# Start Apache
CMD ["apache2-foreground"]
