<?php

declare(strict_types=1);

// Usage: php rename-namespace.php <namespace> <dir> [<dir> ...]
// Replaces the root `App\` namespace with <namespace> in every .php file (namespace, use, FQCN).

$namespace = $argv[1];
$changed = 0;

foreach (array_slice($argv, 2) as $dir) {
    if (!is_dir($dir)) {
        continue;
    }

    $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));

    foreach ($files as $file) {
        $path = $file->getPathname();

        if (!str_ends_with($path, '.php')) {
            continue;
        }

        $code = (string) file_get_contents($path);
        // `App\` at the start of a name, optionally fully qualified (`\App\`), never `Foo\App\`.
        $patched = preg_replace('/(?<![\w\\\\])(\\\\?)App\\\\/', '$1' . addcslashes($namespace, '\\$') . '\\\\', $code);

        if ($patched !== $code) {
            file_put_contents($path, $patched);
            $changed++;
        }
    }
}

echo "namespace App\\ -> {$namespace}\\ in {$changed} file(s)\n";
