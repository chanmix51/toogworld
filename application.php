<?php

use Symfony\Component\HttpFoundation\Response;

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
        return $app->redirect($app['session']->authenticate($user));
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
        $app['session']->set('app_ref', $app_ref);

        throw $e;
    }

    $back_uri = $app['session']->addToken($app_ref, $token);

    return $app->redirect($back_uri);

})->bind('check_auth');

$app->get('/confirm_auth/{app_ref}/{token}', function($app_ref, $token) use ($app) {
    $app_auth = $app['db']
        ->getMapFor('Model\Pomm\Entity\Toogworld\AppAuth')
        ->findByPkJoinUser(array('app_ref' => $app_ref, 'token' => $token));
    if (!$app_auth)
    {
        $response = new Response(null, 404);
    }
    else
    {
        $response = new Response(json_encode($app_auth->get('MyUser')->extract()), 200, array('content-type' => 'text/json'));
    }

    return $response;
})->bind('confirm_auth');

$app->get('/', function() use ($app) {
    $app['check_auth']();
    return 'HOMEPAGE';
})->bind('homepage');

return $app;
