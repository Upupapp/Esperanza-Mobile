<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Laravel's default guest redirect targets a route named "login", which
        // this app doesn't have (auth routes are named citizen.login/admin.login).
        // API requests must never attempt that redirect.
        $middleware->redirectGuestsTo(fn (Request $request) => $request->is('api/*') ? null : route('citizen.login'));
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Force JSON error responses for every /api/* request, regardless of
        // the client's Accept header, so mobile API responses stay consistent.
        $exceptions->shouldRenderJsonWhen(fn (Request $request, Throwable $e) => $request->is('api/*') || $request->expectsJson());
    })->create();
