<?php

declare(strict_types=1);

// Usage: php add-strict-types.php <dir> [<dir> ...]
// Adds `declare(strict_types=1);` right after the opening tag of every .php file missing it.

$changed = 0;

foreach (array_slice($argv, 1) as $dir) {
    if (!is_dir($dir)) {
        continue;
    }

    $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));

    foreach ($files as $file) {
        $path = $file->getPathname();

        if (!str_ends_with($path, '.php') || str_ends_with($path, '.blade.php')) {
            continue;
        }

        $code = (string) file_get_contents($path);

        if (preg_match('/declare\s*\(\s*strict_types\s*=\s*1\s*\)/', $code) === 1) {
            continue;
        }

        $patched = preg_replace('/^<\?php\s*/', "<?php\n\ndeclare(strict_types=1);\n\n", $code, 1, $count);

        if ($count === 1) {
            file_put_contents($path, $patched);
            $changed++;
        }
    }
}

echo "strict_types added to {$changed} file(s)\n";
