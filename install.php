<?php

$app = require __DIR__.'/bootstrap.php';
$sql = file_get_contents(__DIR__.'/resources/sql/database.sql');
$app['db']->begin();

$scan = new Pomm\Tools\ScanSchemaTool(array(
    'schema' => WORLD.'/world',
    'connection' => $app['pomm']->getDatabase(),
    'prefix_dir' => __DIR__,

    ));
try
{
    $app['db']
        ->getPdo()
        ->exec($sql);
    $scan->execute();
    $user = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
        ->createObject();
    $user->setEmail(sprintf('admin@%s.toogworld.net', WORLD));
    $user->setPassword('administrateur');
    $user->setSuperUser(true);
    $user = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
        ->saveOne($user);
    $app['db']->commit();
}
catch(\Pomm\Exception\Exception $e)
{
    file_put_contents("php://stderr", sprintf("Exception raised: '%s'.\n", $e->getMessage()));
    $app['db']->rollback();
    exit(1);
}
