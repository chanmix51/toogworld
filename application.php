<?php

require 'bootstrap.php';

$app['check_auth']->protect(function() use ($app) {
    if (!($app['session']->has('authenticated') && $app['session']->get('authenticated')))
    {
        throw new UnauthorizedException();
    }
});

$app->get('/login', function() use ($app) {
})->bind('show_login');

$app->post('/login', function() use ($app) {
})->bind('login');

$app->get('/check_auth/{app_ref}/{back_uri}/{token}', function($app_ref, $back_uri, $token) use ($app) {
    try
    {
        $app['check_auth']();
    }
    catch(UnauthorizedException $e)
    {
        $app['session']->set('back_uri', $app['request']->get('back_uri'));
        $app['session']->set('token', $token);

        throw $e;
    }

})->bind('check_auth');

$app->get('/confirm_auth/{app_ref}/{token}', function($app_ref, $token) use ($app) {
})->bind('confirm_auth');

$app->get('/', function() use ($app) {
    $app['check_auth']();

})->bind('homepage');

