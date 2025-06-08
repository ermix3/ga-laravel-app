<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\Auth\AuthController;

Route::get('/health', function () {
    return response()->json(['status' => 'healthy']);
});

Route::post("/register", [AuthController::class, "register"]);
Route::post("/login", [AuthController::class, "login"]);

Route::middleware("auth:sanctum")->group(function () {
    Route::get("/profile", [AuthController::class, "profile"]);
    Route::post("/logout", [AuthController::class, "logout"]);

    Route::get("/user", function (Request $request) {
        return $request->user();
    });
});

Route::get("/test", fn() => response()->json(["status" => "ok"]));

Route::apiResource("products", ProductController::class);
