<?php

declare(strict_types=1);

// Usage: php patch-composer.php <composer.json> <package-name> <php-version> <namespace>
// Rewrites the skeleton's composer.json: project identity, PHP constraint, app namespace and scripts.

[, $path, $name, $phpVersion, $namespace] = $argv;

$json = json_decode((string) file_get_contents($path), true, flags: JSON_THROW_ON_ERROR);

$json['name'] = $name;
$json['description'] = '';
unset($json['keywords']);
$json['require']['php'] = '^' . $phpVersion;

$psr4 = $json['autoload']['psr-4'];
unset($psr4['App\\']);
$json['autoload']['psr-4'] = [$namespace . '\\' => 'app/'] + $psr4;

$json['scripts'] = [
    'setup' => [
        'composer install',
        "@php -r \"file_exists('.env') || copy('.env.example', '.env');\"",
        '@php artisan key:generate',
    ],
    'test' => [
        '@php artisan config:clear --ansi @no_additional_args',
        '@php artisan test',
    ],
    'analyse' => 'phpstan analyse --memory-limit=1G',
    'fmt' => [
        'mago lint --fix --potentially-unsafe',
        'mago format',
    ],
    'lint' => 'mago lint',
    'check' => [
        'mago format --check',
        '@lint',
        '@analyse',
        '@test',
    ],
    'post-autoload-dump' => [
        'Illuminate\\Foundation\\ComposerScripts::postAutoloadDump',
        '@php artisan package:discover --ansi',
    ],
    'pre-package-uninstall' => [
        'Illuminate\\Foundation\\ComposerScripts::prePackageUninstall',
    ],
];

unset($json['config']['allow-plugins']['pestphp/pest-plugin']);

file_put_contents(
    $path,
    json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . "\n",
);
