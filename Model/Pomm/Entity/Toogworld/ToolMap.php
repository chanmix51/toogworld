<?php

namespace Model\Pomm\Entity\Toogworld;

use Model\Pomm\Entity\Toogworld\Base\ToolMap as BaseToolMap;
use Pomm\Exception\Exception;

class ToolMap extends BaseToolMap
{
    public function getForUser(MyUser $user)
    {
        $acl_map = $this->connection->getMapFor('Model\Pomm\Entity\Toogworld\AccessControl');
        $user_map = $this->connection->getMapFor('Model\Pomm\Entity\Toogworld\MyUser');
        $fields = $this->getSelectFields('tl');
        $fields[] = 'rank() OVER (PARTITION BY tl.zone ORDER BY tl.created_at ASC) AS rank_in_zone';

        $sql = "SELECT %s FROM %s tl, %s ac, %s mu WHERE mu.id = ? AND (mu.super_user OR (ac.tool_id = tl.id AND ac.user_id = mu.id))";
        $sql = sprintf($sql, join(', ', $fields), $this->getTableName(), $acl_map->getTableName(), $user_map->getTableName());

        return $this->query($sql, array($user->getId()));
    }

    public function findAllWithUserInfo(MyUser $user)
    {
        $fields = $this->getSelectFields('tl');
        $fields[] = sprintf("EXISTS (SELECT ac.tool_id FROM %s ac WHERE ac.user_id = ? AND ac.tool_id = tl.id) AS granted", $this->connection->getMapFor('Model\Pomm\Entity\Toogworld\AccessControl')->getTableName());

        $sql = sprintf("SELECT %s FROM %s tl ORDER BY zone ASC", join(', ', $fields), $this->getTableName());

        return $this->query($sql, array($user->getId()));
    }
}
