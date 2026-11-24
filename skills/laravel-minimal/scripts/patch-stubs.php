<?php

declare(strict_types=1);

// Usage: php patch-stubs.php <stubs-dir> <laravel-framework-src>
// Adapts the stubs published by `artisan stub:publish` so `make:*` output follows the project conventions:
// strict_types, final classes, no base Controller, static closures, no unused imports or placeholder comments.
// Also adds the customizable PHP stubs that `stub:publish` skips. Pest stubs are removed.

[, $dir, $frameworkSrc] = $argv;

// Commands load `<project>/stubs/<name>` when it exists; copy the ones stub:publish leaves out.
$sources = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($frameworkSrc, FilesystemIterator::SKIP_DOTS));

foreach ($sources as $source) {
    if (!str_ends_with($source->getPathname(), 'Command.php')) {
        continue;
    }

    preg_match_all("/resolveStubPath\\('\\/stubs\\/([\\w.-]+\\.stub)'\\)/", (string) file_get_contents($source->getPathname()), $matches);

    foreach ($matches[1] as $name) {
        $from = $source->getPath() . '/stubs/' . $name;
        $to = $dir . '/' . $name;

        if (!file_exists($to) && is_file($from) && str_starts_with((string) file_get_contents($from), '<?php')) {
            copy($from, $to);
        }
    }
}

foreach (glob($dir . '/pest*.stub') ?: [] as $pest) {
    unlink($pest);
}

$patched = 0;

foreach (glob($dir . '/*.stub') ?: [] as $path) {
    $code = (string) file_get_contents($path);
    $original = $code;

    if (!str_contains($code, 'strict_types')) {
        $code = preg_replace('/^<\?php\s*/', "<?php\n\ndeclare(strict_types=1);\n\n", $code, 1);
    }

    // Top-level classes only: anonymous `new class` and abstract classes are left alone.
    $code = preg_replace('/^class /m', 'final class ', $code);

    // The skeleton's empty base Controller is removed.
    $code = preg_replace('/^use \{\{ ?rootNamespace ?\}\}Http\\\\Controllers\\\\Controller;\n/m', '', $code);
    $code = str_replace(' extends Controller', '', $code);

    $code = preg_replace('/([(,]\s*)function \(/', '$1static function (', $code);

    $code = preg_replace('/^[ \t]*\/\/[ \t]*\n/m', '', $code);

    // Unused top-level imports (placeholder imports such as `use {{ namespacedModel }};` are kept).
    $code = preg_replace_callback(
        '/^use ([^;{}\n]+?)(?: as (\w+))?;\n/m',
        static function (array $m) use (&$code): string {
            $short = ($m[2] ?? '') !== '' ? $m[2] : substr((string) strrchr('\\' . $m[1], '\\'), 1);
            $rest = preg_replace('/^use [^;]+;\n/m', '', $code);

            return preg_match('/\b' . preg_quote($short, '/') . '\b/', $rest) === 1 ? $m[0] : '';
        },
        $code,
    );

    if (!str_contains($code, '{{ user }}')) {
        $code = str_replace("use {{ namespacedUserModel }};\n", '', $code);
    }

    if ($code !== $original) {
        file_put_contents($path, $code);
        $patched++;
    }
}

echo "patched {$patched} stub(s)\n";
