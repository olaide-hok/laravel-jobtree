<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/posts/{id}', function (string $id) {
    return 'Post ' . $id;
});

Route::get('/posts/{id}/comments/{commentId}', function (string $id, string $commentId) {
    return 'Post ' . $id . ' Comment ' . $commentId;
});
