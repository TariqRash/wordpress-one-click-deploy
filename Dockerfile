# Use the official WordPress image so cloud hosts can build easily
FROM wordpress:6.4-php8.1-apache


# (Optional) You can copy any preinstalled theme or plugin into wp-content here
# COPY wp-content/themes/my-theme /var/www/html/wp-content/themes/my-theme


# Ensure proper permissions (container runtime will handle user)
RUN chown -R www-data:www-data /var/www/html/wp-content || true


EXPOSE 80
CMD ["apache2-foreground"]
