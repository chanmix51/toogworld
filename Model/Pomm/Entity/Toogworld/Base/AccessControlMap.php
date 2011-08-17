<?php

namespace Model\Pomm\Entity\Toogworld\Base;

use Pomm\Object\BaseObjectMap;
use Pomm\Exception\Exception;

abstract class AccessControlMap extends BaseObjectMap
{
    public function initialize()
    {
        $this->object_class =  'Model\Pomm\Entity\Toogworld\AccessControl';
        $this->object_name  =  'toogworld.access_control';

        $this->addField('user_id', 'Number');
        $this->addField('tool_id', 'Number');
        $this->addField('app_data', 'String');

        $this->pk_fields = array('user_id', 'tool_id');
    }
}