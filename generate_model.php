<?php
define('ENV', 'dev');

$app = require "bootstrap.php";

$scan = new Pomm\Tools\ScanSchemaTool(array(
    'schema' => 'toogworld',
    'connection' => $app['pomm']->getDatabase(),
    'prefix_dir' => __DIR__,

    ));
$scan->execute();
