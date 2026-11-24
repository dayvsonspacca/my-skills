# AGENTS.md

Laravel application on PHP __PHP_VERSION__, served by `serversideup/php:__PHP_VERSION__-__VARIATION__`.

## Running things

Everything runs in Docker through [`just`](https://just.systems). Don't use the host's `php` or `composer`: the host PHP may be a different version than the project's.

- `just` lists every recipe
- `just artisan <args>`, `just composer <args>`, `just test [--filter=...]`, `just shell`
- `just up` / `just down` serve the app at http://localhost:8000 (`APP_PORT` in `.env`)

## Before finishing a task

Run `just check`. It runs Mago format check, Mago lint, PHPStan and PHPUnit, the same as CI, and it must pass. `just fmt` applies Mago's auto-fixes and formats.

## Conventions

- Every PHP file starts with `declare(strict_types=1);`.
- Don't hand-format; run `just fmt`.
- Classes are `final` unless they're designed for extension.
- PHPStan runs at level max (Larastan). Fix the types instead of lowering the level or adding ignores and baseline entries; ask first if there's truly no way around it.
- Tests are PHPUnit classes with `#[Test]` attributes, in `tests/Unit` and `tests/Feature`.
- Generate classes with `just artisan make:*`. `stubs/` customizes its output to follow these conventions; keep it that way when editing a stub.
- `config/` holds only the keys that differ from the framework defaults (Laravel merges them over `vendor/laravel/framework/config/`). To change config, add a file with just those keys rather than publishing the full file.
- There is no frontend build (no Vite or npm). Don't add one unless asked.
- Sessions and cache use the `file` driver and the queue is `sync`. Database drivers need their tables first (`just artisan make:session-table`, `make:cache-table`, `make:queue-table`).
- Extra PHP extensions go in the `base` stage of `Dockerfile` (`install-php-extensions`), followed by `just build`.
