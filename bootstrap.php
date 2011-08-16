<?php

require 'vendor/silex.phar';
require 'resources/exceptions/UnauthorizedException.php';

use Silex\Application;
use Silex\Extension\TwigExtension;
use GHub\PommExtension\PommExtension;

$db_dsn = array('dev' => 'pgsql://greg/greg');
$app = new Application();

/* AUTOLOADING */
$app['autoloader']->registerNamespace('GHub', __DIR__.'/vendor');
$app['autoloader']->registerNamespace('Model', __DIR__);

/* EXTENSIONS */
$app->register(
    new Silex\Extension\SessionExtension(),
    array(
        'name'     => '_WORLD',
        'lifetime' => 1800,
    )
);

$app->register(
    new GHub\PommExtension\PommExtension(), 
    array(
        'pomm.class_path' => __DIR__.'/vendor/pomm', 
        'pomm.connections' => array(
            'default' => array(
                'dsn' => $db_dsn[ENV],
            )))
        );
