# serversideup/php: https://serversideup.net/open-source/docker-php/docs
FROM serversideup/php:__PHP_VERSION__-__VARIATION__ AS base

# Extra PHP extensions go here (must run as root):
# USER root
# RUN install-php-extensions intl bcmath
# USER www-data

# Development: www-data takes the host UID/GID so files written through the bind mount
# belong to the host user.
FROM base AS development
ARG USER_ID=1000
ARG GROUP_ID=1000
USER root
RUN docker-php-serversideup-set-id www-data ${USER_ID}:${GROUP_ID} && \
    docker-php-serversideup-set-file-permissions --owner ${USER_ID}:${GROUP_ID}
USER www-data

# Production: code baked into the image, no dev dependencies, OPcache on.
FROM base AS production
ENV PHP_OPCACHE_ENABLE=1
COPY --chown=www-data:www-data . /var/www/html
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader
