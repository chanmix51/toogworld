<?php

define('WORLD', '{world}');

require __DIR__.'/vendor/silex.phar';
require __DIR__.'/resources/exceptions/UnauthorizedException.php';
require __DIR__.'/resources/exceptions/ValidationException.php';

use Silex\Application;
use Silex\Extension\TwigExtension;
use GHub\PommExtension\PommExtension;

$config = array('db_dsn' => 'pgsql://world:{db-password}@{db-host}/{world}');
$app = new Application();

/* DEBUG */
$app['debug'] = (defined('ENV') && ENV !== 'prod');

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
                'dsn' => $config['db_dsn'],
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
