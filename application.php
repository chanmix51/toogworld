<?php

$app = require __DIR__.'/bootstrap.php';

/* ERROR HANDLING */
$app->error(function (\Exception $e, $code) use ($app) {
    if ($e instanceof UnauthorizedException)
    {
        return $app->redirect('/login');
    }

    if ($app['debug']) 
    {
        return;
    }
    // TODO: error & 404 page
});

$app['check_auth'] = $app->protect(function() use ($app) {
    if (($app['session']->isAuthenticated()))
    {
        return;
    }
    throw new UnauthorizedException();
});

$app->get('/login', function() use ($app) {
    return $app['twig']->render('show_login.html.twig');
})->bind('show_login');

$app->post('/login', function() use($app) {
    $email = $app['request']->get('email');
    $password = $app['request']->get('password');

    $user = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
        ->validateLogin($email, $password);

    if ($user === false) 
    {
        return $app['twig']->render('show_login.html.twig', array('email' => $email, 'error_msg' => 'Invalid login or password.'));
    }
    elseif (!$user->getIsActive())
    {
        return $app['twig']->render('show_login.html.twig', array('email' => $email, 'error_msg' => 'Your account is deactivated.'));
    }
    else
    {
        $app['session']->authenticate($user);

        return $app->redirect('/');
    }
})->bind('login');

$app->get('/logout', function() use ($app) {
    $app['session']->deauthenticate();
    throw new UnauthorizedException();
})->bind('logout');

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
    return 'HOMEPAGE';
})->bind('homepage');

return $app;