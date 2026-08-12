<?php

/**
 * Esperanza Web Platform — Static HTML Exporter
 *
 * Boots Laravel internally, renders every known route to a static HTML file
 * under dist/, then copies compiled assets from public/build and public/images.
 * Run after `npm run build` so the Vite manifest is available.
 *
 * Usage: php export.php
 */

define('LARAVEL_START', microtime(true));

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';

/** @var \Illuminate\Contracts\Http\Kernel $kernel */
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

// ── Route map: URI → dist-relative output path ───────────────────────────────
$routes = [
    '/'                                => 'index.html',
    '/citizen/login'                   => 'citizen/login/index.html',
    '/citizen/register'                => 'citizen/register/index.html',
    '/admin/login'                     => 'admin/login/index.html',
    '/logout'                          => 'logout/index.html',
    '/citizen/dashboard'               => 'citizen/dashboard/index.html',
    '/citizen/profile'                 => 'citizen/profile/index.html',
    '/citizen/document-requests'       => 'citizen/document-requests/index.html',
    '/citizen/assistance-requests'     => 'citizen/assistance-requests/index.html',
    '/citizen/notifications'           => 'citizen/notifications/index.html',
    '/citizen/directory'               => 'citizen/directory/index.html',
    '/citizen/announcements'           => 'citizen/announcements/index.html',
    '/citizen/events'                  => 'citizen/events/index.html',
    '/citizen/settings'                => 'citizen/settings/index.html',
    '/citizen/help'                    => 'citizen/help/index.html',
    '/citizen/help/tutorials'          => 'citizen/help/tutorials/index.html',
    '/citizen/help/support'            => 'citizen/help/support/index.html',
    '/admin/dashboard'                 => 'admin/dashboard/index.html',
    '/admin/document-requests'         => 'admin/document-requests/index.html',
    '/admin/assistance-requests'       => 'admin/assistance-requests/index.html',
    '/admin/payments'                  => 'admin/payments/index.html',
    '/admin/constituents'              => 'admin/constituents/index.html',
    '/admin/constituents/families'     => 'admin/constituents/families/index.html',
    '/admin/constituents/households'   => 'admin/constituents/households/index.html',
    '/admin/constituents/profiling'    => 'admin/constituents/profiling/index.html',
    '/admin/constituents/data-quality' => 'admin/constituents/data-quality/index.html',
    '/admin/communications'            => 'admin/communications/index.html',
    '/admin/communications/offices'    => 'admin/communications/offices/index.html',
    '/admin/announcements'             => 'admin/announcements/index.html',
    '/admin/reports'                   => 'admin/reports/index.html',
    '/admin/reports/analytics'         => 'admin/reports/analytics/index.html',
    '/admin/users'                     => 'admin/users/index.html',
    '/admin/users/roles'               => 'admin/users/roles/index.html',
    '/admin/settings'                  => 'admin/settings/index.html',
    '/admin/settings/branding'         => 'admin/settings/branding/index.html',
    '/admin/settings/audit-logs'       => 'admin/settings/audit-logs/index.html',
    // Sakuna module
    '/admin/sakuna'                    => 'admin/sakuna/index.html',
    '/admin/sakuna/vulnerability'      => 'admin/sakuna/vulnerability/index.html',
    '/admin/sakuna/incidents'          => 'admin/sakuna/incidents/index.html',
    '/admin/sakuna/evacuation-centers' => 'admin/sakuna/evacuation-centers/index.html',
    '/admin/sakuna/evacuees'           => 'admin/sakuna/evacuees/index.html',
    '/admin/sakuna/resources'          => 'admin/sakuna/resources/index.html',
    '/admin/sakuna/relief'             => 'admin/sakuna/relief/index.html',
    '/admin/sakuna/damage-assessment'  => 'admin/sakuna/damage-assessment/index.html',
    '/admin/sakuna/alerts'             => 'admin/sakuna/alerts/index.html',
    '/admin/sakuna/reports'            => 'admin/sakuna/reports/index.html',
];

// ── Helpers ───────────────────────────────────────────────────────────────────
function copyDir(string $src, string $dst): int
{
    if (!is_dir($src)) {
        return 0;
    }
    @mkdir($dst, 0777, true);
    $count = 0;
    foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($src, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::SELF_FIRST) as $item) {
        $dest = $dst . '/' . substr($item->getPathname(), strlen($src) + 1);
        if ($item->isDir()) {
            @mkdir($dest, 0777, true);
        } else {
            copy($item->getPathname(), $dest);
            $count++;
        }
    }
    return $count;
}

// ── Detect host from APP_URL ──────────────────────────────────────────────────
$appUrl  = env('APP_URL', 'http://localhost');
$parsed  = parse_url($appUrl);
$host    = $parsed['host'] ?? 'localhost';
$isHttps = ($parsed['scheme'] ?? 'http') === 'https';

$distDir = __DIR__ . '/dist';
@mkdir($distDir, 0777, true);

echo "\n── Esperanza Static Exporter ──────────────────────────────\n";
echo "APP_URL : {$appUrl}\n";
echo "Dist    : {$distDir}\n\n";

// ── Render routes ─────────────────────────────────────────────────────────────
$ok = 0;
$fail = 0;

foreach ($routes as $uri => $outputPath) {
    try {
        $server = [
            'HTTP_HOST'   => $host,
            'SERVER_NAME' => $host,
            'SERVER_PORT' => $isHttps ? '443' : '80',
            'HTTPS'       => $isHttps ? 'on' : 'off',
        ];

        $request  = Illuminate\Http\Request::create($uri, 'GET', [], [], [], $server);
        $response = $kernel->handle($request);
        $html     = $response->getContent();

        if ($response->getStatusCode() >= 400) {
            throw new RuntimeException("HTTP {$response->getStatusCode()}");
        }

        $fullPath = $distDir . '/' . $outputPath;
        @mkdir(dirname($fullPath), 0777, true);
        file_put_contents($fullPath, $html);

        echo "  ✓  {$uri}\n";
        $ok++;

        $kernel->terminate($request, $response);
    } catch (Throwable $e) {
        echo "  ✗  {$uri}  ({$e->getMessage()})\n";
        $fail++;
    }
}

// ── Copy public assets ────────────────────────────────────────────────────────
echo "\n── Assets ─────────────────────────────────────────────────\n";

$assets = [
    'public/build'   => 'dist/build',
    'public/images'  => 'dist/images',
    'public/fonts'   => 'dist/fonts',
];

foreach ($assets as $src => $dst) {
    $srcPath = __DIR__ . '/' . $src;
    $dstPath = __DIR__ . '/' . $dst;
    if (is_dir($srcPath)) {
        $n = copyDir($srcPath, $dstPath);
        echo "  ✓  {$src}/ → {$dst}/  ({$n} files)\n";
    }
}

foreach (['favicon.ico', 'robots.txt'] as $file) {
    $src = __DIR__ . '/public/' . $file;
    if (file_exists($src)) {
        copy($src, $distDir . '/' . $file);
        echo "  ✓  public/{$file}\n";
    }
}

// ── Summary ───────────────────────────────────────────────────────────────────
echo "\n── Done ────────────────────────────────────────────────────\n";
echo "  Pages : {$ok} rendered, {$fail} failed\n\n";

if ($fail > 0) {
    exit(1);
}
