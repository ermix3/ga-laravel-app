<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    public function index()
    {
        return Product::all();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            "name" => "required|string",
            "price" => "required|numeric",
            "image" => "nullable|image|max:2048",
        ]);

        if ($request->hasFile("image")) {
            $path = $request->file("image")->store("products", "public");
            $validated["image"] = asset("storage/{$path}");
        }

        return Product::create($validated);
    }

    public function show(Product $product)
    {
        return $product;
    }

    public function update(Request $request, Product $product)
    {
        $validated = $request->validate([
            "name" => "sometimes|required|string",
            "price" => "sometimes|required|numeric",
            "image" => "nullable|image|max:2048",
        ]);

        if ($request->hasFile("image")) {
            $path = $request->file("image")->store("products", "public");
            $validated["image"] = asset("storage/{$path}");
        }

        $product->update($validated);
        return $product;
    }

    public function destroy(Product $product)
    {
        $product->delete();
        return response()->noContent();
    }
}
