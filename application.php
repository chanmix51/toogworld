<?php

use Symfony\Component\HttpFoundation\Response;

$app = require __DIR__.'/bootstrap.php';

$app['windows_content'] = $app->protect(function($all_tools) use ($app) {
    $tools = array();
    foreach($all_tools as $tool)
    {
        $zone = $tool->get('zone', '/');

        if (!array_key_exists($zone, $tools)) 
        {
            $tools[$zone] = array();
        }

        $tools[$zone][$tool->getRankInZone()] = $tool;
    }

    $windows = array();
    foreach ($tools as $zone => $z_tools)
    {
        $windows[$zone] = $app['twig']->render('window.html.twig', array('tools' => $z_tools));
    }

    return $windows;
});

/* ERROR HANDLING */
$app->error(function (\Exception $e, $code) use ($app) {
    if ($e instanceof UnauthorizedException)
    {
        switch($code)
        {
            case "1":
                return $app->redirect('/');
                break;
            default:
                return $app->redirect('/login');
        }
    }

    if ($app['debug']) 
    {
        return;
    }
    // TODO: error & 404 page
});

/* ACCESS RIGHT */
$app['check_auth'] = $app->protect(function() use ($app) {
    if (($app['session']->isAuthenticated()))
    {
        return;
    }
    throw new UnauthorizedException();
});

$app['check_superuser'] = $app->protect(function() use ($app) {
    $app['check_auth']();
    if (!$app['session']->getUser()->getSuperUser())
    {
        throw new UnauthorizedException('Must have administrator privileges to access this resource.', 1);
    }
});

/* CONTROLLERS */
$app->get('/login', function() use ($app) {
    try
    {
        $app['check_auth']();

        return $app->redirect('/');
    }
    catch(UnauthorizedException $e) 
    {
        return $app['twig']->render('show_login.html.twig');
    }
})->bind('show_login');

$app->post('/login', function() use ($app) {
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

    return $app->redirect('/login');
})->bind ('logout');

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

    $app['session']->addToken($app_ref, $token);

    return $app->redirect(sprintf("http://%s%s", $app_ref, $back_uri));

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

    $tools = array();
    $all_tools = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\Tool')
        ->getForUser($app['session']->getUser());



    return $app['twig']->render('homepage.html.twig', array('tools' => $app['windows_content']($all_tools)));
})->bind('homepage');

$app->get('/users', function() use($app) {
    $app['check_superuser']();

    $users = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
        ->findAll();

    $tools = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\Tool')
        ->findAll();


    return $app['twig']->render('users_main.html.twig', array('users' => $users, 'tools' => $tools));
})->bind('users');

$app->get('/users/user/{user_id}', function($user_id) use ($app) {
    $app['check_superuser']();
    $user = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
        ->findByPk(array('id' => $user_id));

    $tools = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\Tool')
        ->findAllWithUserInfo($user);

    return $app['twig']->render('users_user.html.twig', array('user' => $user, 'tools' => $tools));
});

$app->get('/users/tool/{tool_id}', function($tool_id) use ($app) {
    $app['check_superuser']();
    $tool = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\Tool')
        ->findByPk(array('id' => $tool_id));

    $users = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
        ->findAllWithToolInfo($tool);

    return $app['twig']->render('users_tool.html.twig', array('tool' => $tool, 'users' => $users));
});

$app->post('/users/tool', function() use ($app) {
    if ($app['request']->request->has('tool'))
    {
        $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\AccessControl')
            ->updateUser($app['request']->get('tool'));
    }

    return $app->redirect('/users');
})->bind('grant_acls_by_tool');

$app->post('/users/user', function() use ($app) {
    if ($app['request']->request->has('user'))
    {
        $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\AccessControl')
            ->updateTool($app['request']->get('user'));
    }

    return $app->redirect('/users');
})->bind('grant_acls_by_user');

$app->get('/nuke_password', function() use ($app) {
    $app['check_auth']();

    return $app['twig']->render('password_nuke.html.twig');
});

$app->post('/nuke_password', function() use ($app) {
    $app['check_auth']();

    $pass = $app['request']->get('password');
    $user = $app['session']->getUser();
    $error_msg = '';

    if ($app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')->validateLogin($user->getEmail(), $pass))
    {
        $error_msg = 'Vous devez indiquer un nouveau mot de passe.';
    }
    elseif ($pass !== $app['request']->get('password_bis'))
    {
        $error_msg = 'Les mots de passe ne coincident pas.';
    }
    else
    {
        try
        {
            $user->setPassword($pass);
            $user->setPasswordNuke(mt_rand(20, 50));
            $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
                ->saveOne($user);

            return $app->redirect('/');
        }
        catch(\ValidationException $e)
        {
            $error_msg = 'Le mot de passe est invalide. Il doit comporter au moins 10 caractères dont 8 lettres.';
        }
    }

    return $app['twig']->render('password_nuke.html.twig', array('error_msg' => $error_msg));
})->bind('pass_change');

return $app;
