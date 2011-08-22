<?php

namespace Model\Pomm\Entity\Toogworld;

use Model\Pomm\Entity\Toogworld\Base\AccessControlMap as BaseAccessControlMap;
use Pomm\Exception\Exception;

class AccessControlMap extends BaseAccessControlMap
{
    protected function generateValuesFromUsers($tool_id, Array $user_ids)
    {
        $values = array();
        foreach(array_keys($user_ids) as $user_id)
        {
            $values[] = sprintf("(%d, %d)", $user_id, $tool_id);
        }

        return $values;
    }
    protected function generateValuesFromTools($user_id, Array $tool_ids)
    {
        $values = array();
        foreach(array_keys($tool_ids) as $tool_id)
        {
            $values[] = sprintf("(%d, %d)", $user_id, $tool_id);
        }

        return $values;
    }

    public function updateUser($form_data)
    {
        $user_id = array_shift(array_keys($form_data));

        $this->connection->begin();
        $this->query(sprintf("DELETE FROM %s WHERE user_id = ?", $this->getTableName()), array($user_id));
        $this->query(sprintf("INSERT INTO %s (%s) VALUES %s", $this->getTableName(), join(', ', $this->getPrimaryKey()), join(', ', $this->generateValuesFromTools($user_id, $form_data[$user_id]))));
        $this->connection->commit();
    }

    public function updateTool($form_data)
    {
        $tool_id = array_shift(array_keys($form_data));

        $this->connection->begin();
        $this->query(sprintf("DELETE FROM %s WHERE tool_id = ?", $this->getTableName()), array($tool_id));
        $this->query(sprintf("INSERT INTO %s (%s) VALUES %s", $this->getTableName(), join(', ', $this->getPrimaryKey()), join(', ', $this->generateValuesFromUsers($tool_id, $form_data[$tool_id]))));
        $this->connection->commit();
    }
}
