<?php

$app = require __DIR__.'/bootstrap.php';
$sql = file_get_contents(__DIR__.'/resources/sql/database.sql');
$app['db']->begin();

try
{
    $app['db']
        ->getPdo()
        ->exec($sql);
    $user = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
        ->createObject();
    $user->setEmail(sprintf('admin@%s.toogworld.net', WORLD));
    $user->setPassword('admin');
    $user->setSuperUser(true);
    $user = $app['db']->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
        ->saveOne($user);
}
catch(\Pomm\Exception\Exception $e)
{
    $app['db']->rollback();
    exit(1);
}
