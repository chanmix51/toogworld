<?php

namespace Model\Pomm\Entity\Toogworld;

use Model\Pomm\Entity\Toogworld\Base\MyUserMap as BaseMyUserMap;
use Pomm\Exception\Exception;
use Toogworld\Cryptlib\Cryptlib;

class MyUserMap extends BaseMyUserMap
{
    public function validateLogin($email, $password)
    {
        $coll = $this->findWhere('email = ? AND password = ?', array($email, Cryptlib::encrypt($password, $email)));

        if ($coll->isEmpty())
        {
            return false;
        }
        else
        {
            return $coll[0];
        }
    }

    public function getSelectFields($alias = null)
    {
        $fields = parent::getSelectFields($alias);
        $alias = is_null($alias) ? '' : sprintf("%s.", $alias);

        return array_filter($fields, function($val) use ($alias) { return $val !== sprintf("%spassword", $alias); });
    }

    public function findAllWithToolInfo(Tool $tool) 
    {
        $fields = $this->getSelectFields();
        $fields[] = sprintf("EXISTS (SELECT ac.user_id FROM %s ac WHERE ac.tool_id = ?) AS granted", $this->connection->getMapFor('Model\Pomm\Entity\Toogworld\AccessControl')->getTableName());

        $sql = sprintf("SELECT %s FROM %s mu ORDER BY mu.email ASC", join(', ', $fields), $this->getTableName());

        return $this->query($sql, array($tool->getId()));
    }
}
