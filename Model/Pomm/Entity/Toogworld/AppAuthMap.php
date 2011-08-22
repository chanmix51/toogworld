<?php

namespace Model\Pomm\Entity\Toogworld;

use Model\Pomm\Entity\Toogworld\Base\AppAuthMap as BaseAppAuthMap;
use Pomm\Exception\Exception;

class AppAuthMap extends BaseAppAuthMap
{
    public function deleteTokensForUser(MyUser $user)
    {
        $sql = sprintf("DELETE FROM %s WHERE user_id = ?", $this->object_name);

        $this->query($sql, array($user->getId()));
    }

    public function addNew($app_ref, $token, $user_id)
    {
        $app_auth = $this->createObject();
        $app_auth->setToken($token);
        $app_auth->setAppRef($app_ref);
        $app_auth->setUserId($user_id);
        $this->saveOne($app_auth);
    }

    public function findByPkJoinUser($pk) 
    {
        $user_map = $this->connection
            ->getMapFor('Model\Pomm\Entity\Toogworld\MyUser');

        $sql = sprintf("SELECT %s,%s FROM %s au JOIN %s mu ON au.user_id = mu.id WHERE %s", join(', ', $this->getSelectFields('au')), join(', ', $user_map->getSelectFields('mu')), $this->object_name, $user_map->getTableName(), $this->createSqlAndFrom($pk, 'au'));

        $app_auths = $this->query($sql, array_values($pk));
        if (!$app_auths->isEmpty())
        {
            $app_auth = $app_auths[0];
            $app_auth->set('MyUser', $user_map->createObject()->hydrate($app_auth->extract()));

            return $app_auth;
        }

        return false;
    }
}
