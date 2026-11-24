---
name: laravel-minimal
description: Scaffolds a new, lean Laravel project that runs entirely in Docker (serversideup/php on the latest PHP), stripped of skeleton boilerplate (Vite/npm frontend, User/auth, default migrations, config files, examples) and preconfigured with PHPStan (Larastan, level max), Mago (format + lint), PHPUnit, strict_types, a justfile, GitHub Actions and an initial commit. Use it whenever the user wants to start, create, scaffold or bootstrap a Laravel project, app or API, even if they don't name any of these tools, and whenever they ask for a "clean", "minimal" or "no-boilerplate" Laravel, or one dockerized or with phpstan/mago/phpunit set up from day one. Do not use it to add tooling to an existing Laravel project.
metadata:
  version: "1.0.0"
---

# Laravel minimal

Scaffold a minimal Laravel project with `scripts/new-project.sh`.

## 1. Gather parameters

**Image variation: always ask the user.** The right choice depends on the project, so don't assume. Use your question tool and offer these options, with the trade-offs:

| Variation    | When it fits |
| ------------ | ------------ |
| `fpm-nginx`  | Default choice for a Laravel web app or API: PHP-FPM behind NGINX, the most common setup and the one serversideup recommends for Laravel. |
| `frankenphp` | Performance-sensitive apps, Laravel Octane (worker mode), HTTP/3. Single Caddy-based process. |
| `fpm-apache` | Needs Apache features such as `.htaccess` rules or Apache modules. |
| `cli`        | No HTTP at all: queue workers, scheduled jobs, CLI tools. No ports, no `just up`. |

If the user already said what they want (e.g. "with FrankenPHP", "it's just a worker"), use that and skip the question.

**Root namespace: always ask the user**, in the same round as the variation. Suggest `App` (Laravel's default). Any StudlyCase namespace works, including nested ones like `Acme\Billing`. Only `app/` uses it; `Tests\`, `Database\Factories\` and `Database\Seeders\` keep Laravel's names. Skip the question if the user already gave one.

Other parameters:

- **Directory**: the name the user gave. If none was given, ask. If they say "here" and the current directory is empty, use `.`. The script refuses non-empty directories so it can never clobber work. If the directory holds only a `.git` or a README, ask before touching it.
- **PHP version** (`--php X.Y`): omit it unless the user asks for a specific version.
- **Package name** (`--name vendor/package`): defaults to `app/<dir-name>`. Pass it if the user mentions a vendor (GitHub user, company).

## 2. Run the script

```bash
<skill-dir>/scripts/new-project.sh <dir> --variation <variation> --namespace '<Namespace>' [--php X.Y] [--name vendor/package]
```

It takes 1 to 2 minutes.

## 3. When something fails

The script stops at the first error (`set -euo pipefail`). The usual cause is a new release of Laravel, Larastan, Mago or the serversideup images that changed something. Read the output and fix it in the spirit of the skill: the project stays minimal, and the check stays green.

- **New files in the skeleton** that the removal list doesn't cover: decide whether they are boilerplate by the same criteria (examples, frontend, unused code) and remove them.
- **PHPStan or Mago errors in generated code**: fix the code. Don't lower the level or disable rules. If there's no way around it, explain to the user before relaxing anything.
- **Docker isn't running, the user can't access the daemon, or `just` is missing**: stop and tell the user. Don't install or start anything yourself.

After fixing, re-run `just check` until it's green.

### When the user wants to keep something

If the request deviates from the default ("but keep Vite", "I want the User model"), don't run the script blindly. Use it as a recipe: read `scripts/new-project.sh` and run its steps by hand, skipping or adapting whatever the user wants to keep. For example, to keep User, keep `app/Models/User.php`, its factory and the users migration, and leave the session driver alone. `just check` still has to pass at the end.

## 4. Git

With the check green, inside the project directory:

```bash
git init -b main
git add -A
git status --short   # verify: .env must NOT be listed (it is git-ignored)
git commit -m "chore: bootstrap minimal Laravel project"
```

If the directory is already a git repository, skip `git init`. Commit only if no unrelated user changes would be mixed in; otherwise ask first.

## 5. Report to the user

Report the project path, the PHP version and image used, the root namespace, how to start (`just up`, except for `cli`, and `just check`), and anything that deviated from the default flow.
