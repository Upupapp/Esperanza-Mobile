<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Support\Facades\Route;

// Mobile app authentication (Sanctum personal access tokens).
// Kept separate from routes/web.php: nothing web-admin-only is exposed here.
Route::post('/login', [AuthController::class, 'login'])->name('api.login');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'me'])->name('api.user');
    Route::post('/logout', [AuthController::class, 'logout'])->name('api.logout');
    Route::get('/tokens', [AuthController::class, 'tokens'])->name('api.tokens.index');
    Route::delete('/tokens/{tokenId}', [AuthController::class, 'revokeToken'])->name('api.tokens.destroy');
});