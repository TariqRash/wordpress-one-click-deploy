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

# Enable Apache modules
RUN a2enmod rewrite headers

# Configure Apache for Railway (port 80, Railway handles HTTPS at proxy level)
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf

# WordPress HTTPS configuration for Railway proxy
RUN echo "<?php" > /var/www/html/wp-railway-config.php && \
    echo "// Railway HTTPS configuration" >> /var/www/html/wp-railway-config.php && \
    echo "if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {" >> /var/www/html/wp-railway-config.php && \
    echo "    \$_SERVER['HTTPS'] = 'on';" >> /var/www/html/wp-railway-config.php && \
    echo "}" >> /var/www/html/wp-railway-config.php && \
    echo "if (isset(\$_SERVER['HTTP_X_FORWARDED_HOST'])) {" >> /var/www/html/wp-railway-config.php && \
    echo "    \$_SERVER['HTTP_HOST'] = \$_SERVER['HTTP_X_FORWARDED_HOST'];" >> /var/www/html/wp-railway-config.php && \
    echo "}" >> /var/www/html/wp-railway-config.php

# Create volume mount point for persistent WordPress files
RUN mkdir -p /var/www/html/wp-content/uploads && \
    chown -R www-data:www-data /var/www/html

# Expose port 80 (Railway will handle SSL/TLS termination)
EXPOSE 80

CMD ["apache2-foreground"]
