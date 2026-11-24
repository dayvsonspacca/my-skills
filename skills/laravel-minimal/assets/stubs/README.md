# __APP_NAME__

Runs entirely in Docker (`serversideup/php:__PHP_VERSION__-__VARIATION__`). The host only needs Docker and [`just`](https://just.systems).

## Setup

```sh
just setup
just up      # http://localhost:8000 (change with APP_PORT in .env)
```

## Commands

Run `just` to list everything. The main ones:

| Command             | What it does                              |
| ------------------- | ----------------------------------------- |
| `just test`         | PHPUnit                                   |
| `just analyse`      | PHPStan (Larastan, level max)             |
| `just fmt`          | Apply Mago's auto-fixes, then format      |
| `just lint`         | Lint with Mago                            |
| `just check`        | Format check + lint + analyse + test (CI) |
| `just artisan ...`  | Run an artisan command                    |
| `just composer ...` | Run a composer command                    |
| `just shell`        | Shell inside the container                |

Extra PHP extensions: add them to the `base` stage in `Dockerfile` and run `just build`.
