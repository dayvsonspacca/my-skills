#!/usr/bin/env bash
# Creates a minimal Laravel project that runs entirely in Docker (serversideup/php),
# with PHPStan (Larastan), Mago and PHPUnit configured.
#
# Usage: new-project.sh <target-dir> --variation <fpm-nginx|fpm-apache|frankenphp|cli> [--namespace Vendor\App] [--php X.Y] [--name vendor/package]
#
#   <target-dir>  Must not exist, or be empty.
#   --variation   serversideup/php image variation the project is served with.
#   --namespace   Root namespace for app/ (e.g. 'Acme\Billing'). Default: App.
#   --php         PHP version (image tag, composer constraint, Mago). Default: newest stable
#                 version published by serversideup/php (the floating `cli` tag).
#   --name        Composer package name. Default: app/<dir-basename>.
#
# Host requirements: docker (with compose) and just. PHP/Composer on the host are not used.
# Does not touch git; the caller decides about `git init` and the first commit.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STUBS="$SKILL_DIR/assets/stubs"
SCRIPTS="$SKILL_DIR/scripts"

TARGET=""
VARIATION=""
NAMESPACE="App"
PHP_VERSION=""
PACKAGE_NAME=""

usage() {
    echo "Usage: $0 <target-dir> --variation <fpm-nginx|fpm-apache|frankenphp|cli> [--namespace Vendor\\App] [--php X.Y] [--name vendor/package]" >&2
    exit 2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --variation) VARIATION="$2"; shift 2 ;;
        --namespace) NAMESPACE="$2"; shift 2 ;;
        --php) PHP_VERSION="$2"; shift 2 ;;
        --name) PACKAGE_NAME="$2"; shift 2 ;;
        -*) echo "Unknown option: $1" >&2; usage ;;
        *) TARGET="$1"; shift ;;
    esac
done

[[ -n "$TARGET" && -n "$VARIATION" ]] || usage
case "$VARIATION" in
    fpm-nginx|fpm-apache|frankenphp|cli) ;;
    *) echo "Invalid --variation '$VARIATION'." >&2; usage ;;
esac
NAMESPACE_RE='^[A-Z][A-Za-z0-9]*(\\[A-Z][A-Za-z0-9]*)*$'
if [[ ! "$NAMESPACE" =~ $NAMESPACE_RE ]]; then
    echo "Invalid --namespace '$NAMESPACE': use StudlyCase segments separated by a single backslash, e.g. Acme\\Billing." >&2
    exit 2
fi

if [[ -e "$TARGET" && -n "$(ls -A "$TARGET" 2>/dev/null)" ]]; then
    echo "Target '$TARGET' exists and is not empty. Refusing to overwrite." >&2
    exit 1
fi

for bin in docker just; do
    command -v "$bin" >/dev/null || { echo "'$bin' not found in PATH." >&2; exit 1; }
done
docker compose version >/dev/null 2>&1 || { echo "'docker compose' is not available." >&2; exit 1; }

step() { printf '\n==> %s\n' "$*"; }

if [[ -z "$PHP_VERSION" ]]; then
    step "Resolving the newest PHP version published by serversideup/php"
    PHP_VERSION="$(docker run --rm --pull always -e SHOW_WELCOME_MESSAGE=false serversideup/php:cli \
        php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
fi
CLI_IMAGE="serversideup/php:$PHP_VERSION-cli"
APP_IMAGE="serversideup/php:$PHP_VERSION-$VARIATION"

for image in "$CLI_IMAGE" "$APP_IMAGE"; do
    docker manifest inspect "$image" >/dev/null 2>&1 || { echo "Image '$image' does not exist." >&2; exit 1; }
done
echo "PHP $PHP_VERSION, serving with $APP_IMAGE"

mkdir -p "$TARGET"
PROJECT="$(cd "$TARGET" && pwd)"
DIR_NAME="$(basename "$PROJECT")"
SLUG="$(echo "$DIR_NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
PACKAGE_NAME="${PACKAGE_NAME:-app/$SLUG}"
COMPOSER_CACHE="${COMPOSER_CACHE_DIR:-$HOME/.cache/composer}"
mkdir -p "$COMPOSER_CACHE"

# Runs a command in the CLI image as the host user, so generated files are not owned by root.
in_php() {
    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -e SHOW_WELCOME_MESSAGE=false \
        -e COMPOSER_HOME=/tmp/composer \
        -e COMPOSER_CACHE_DIR=/composer-cache \
        -v "$COMPOSER_CACHE:/composer-cache" \
        -v "$PROJECT:/app" \
        -v "$SCRIPTS:/skill:ro" \
        -w /app \
        "$CLI_IMAGE" "$@"
}

step "composer create-project laravel/laravel ($PROJECT)"
in_php composer create-project laravel/laravel . --no-interaction --prefer-dist --no-scripts
cd "$PROJECT"

step "Patching composer.json"
in_php php /skill/patch-composer.php composer.json "$PACKAGE_NAME" "$PHP_VERSION" "$NAMESPACE"

step "Removing boilerplate"
rm -rf \
    resources package.json vite.config.js .npmrc \
    app/Models app/Http \
    database/factories database/seeders database/database.sqlite \
    routes/console.php \
    config \
    tests/Unit/ExampleTest.php tests/Feature/ExampleTest.php \
    public/favicon.ico public/robots.txt \
    CLAUDE.md AGENTS.md README.md .env  # the agent docs and README are replaced by the stubs
rm -f database/migrations/*.php
mkdir -p database/migrations tests/Unit
touch database/migrations/.gitkeep tests/Unit/.gitkeep

step "Copying stubs"
cp -R "$STUBS/." .
if [[ "$VARIATION" == "cli" ]]; then
    # The cli image has no web server: drop the port mapping and the up/down recipes.
    sed -i '/# web-only:start/,/# web-only:end/d' compose.yaml justfile
    sed -i '/just up/d' README.md AGENTS.md
else
    sed -i '/# web-only:/d' compose.yaml justfile
fi
find . -path ./vendor -prune -o -type f \
    \( -name '*.md' -o -name '*.toml' -o -name '*.yaml' -o -name '*.yml' -o -name 'Dockerfile' -o -name '.env.example' \) -print0 \
    | xargs -0 sed -i "s|__PHP_VERSION__|$PHP_VERSION|g; s|__VARIATION__|$VARIATION|g; s|__APP_NAME__|$DIR_NAME|g"

if [[ "$NAMESPACE" != "App" ]]; then
    step "Root namespace: $NAMESPACE"
    in_php php /skill/rename-namespace.php "$NAMESPACE" app bootstrap config database routes tests
fi

step "Adjusting dependencies"
# Unused in a minimal setup (REPL, log tailing, agent output helpers). Pint is replaced by Mago.
# --no-scripts: the uninstall hooks need a booting app; `just setup` runs package:discover later.
in_php sh -c '
    composer remove --no-update laravel/tinker &&
    composer remove --dev --no-update laravel/pail laravel/pao laravel/pint &&
    composer require --dev --no-update larastan/larastan carthage-software/mago &&
    composer update --no-interaction --no-progress --no-scripts
'

step "declare(strict_types=1)"
in_php php /skill/add-strict-types.php app bootstrap config database routes tests public

step "Formatting with Mago"
in_php vendor/bin/mago format

step "Building the dev image (just setup)"
just setup

step "Publishing artisan stubs"
just artisan stub:publish
in_php php /skill/patch-stubs.php stubs vendor/laravel/framework/src
cp "$SKILL_DIR/assets/artisan-stubs/"*.stub stubs/

step "just check"
just check

step "Done: $PROJECT"
