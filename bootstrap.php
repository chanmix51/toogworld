<?php

require __DIR__.'/vendor/silex.phar';
require __DIR__.'/resources/exceptions/UnauthorizedException.php';

use Silex\Application;
use Silex\Extension\TwigExtension;
use GHub\PommExtension\PommExtension;

$db_dsn = array('dev' => 'pgsql://greg:omevGink8@172.16.0.1/greg');
$app = new Application();

/* DEBUG */
$app['debug'] = (ENV !== 'prod');

/* AUTOLOADING */
$app['autoloader']->registerNamespace('GHub', __DIR__.'/vendor');
$app['autoloader']->registerNamespace('Model', __DIR__);
$app['autoloader']->registerNamespace('Toogworld', __DIR__);

/* EXTENSIONS */
$app->register(
    new Silex\Extension\SessionExtension(),
    array(
        'name'     => '_WORLD',
        'lifetime' => 1800,
    )
);

$app['session'] = $app->share(function ($app) {
    $session =  new Toogworld\Session\Session($app['session.storage']);
    $session->setContainer($app);

    return $session;
});

$app->register(
    new GHub\PommExtension\PommExtension(), 
    array(
        'pomm.class_path' => __DIR__.'/vendor/pomm', 
        'pomm.connections' => array(
            'default' => array(
                'dsn' => $db_dsn[ENV],
            )))
        );

$app['db'] = $app['pomm']->getDatabase()
    ->createConnection();

$app->register(new Silex\Extension\TwigExtension(), array(
    'twig.path'       => __DIR__.'/resources/templates',
    'twig.class_path' => __DIR__.'/vendor/Twig/lib',
));

$app->register(new Silex\Extension\UrlGeneratorExtension());

return $app;
