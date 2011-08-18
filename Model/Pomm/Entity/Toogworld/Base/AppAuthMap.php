<?php

namespace Model\Pomm\Entity\Toogworld\Base;

use Pomm\Object\BaseObjectMap;
use Pomm\Exception\Exception;

abstract class AppAuthMap extends BaseObjectMap
{
    public function initialize()
    {
        $this->object_class =  'Model\Pomm\Entity\Toogworld\AppAuth';
        $this->object_name  =  'toogworld.app_auth';

        $this->addField('app_ref', 'String');
        $this->addField('token', 'String');
        $this->addField('user_id', 'Number');
        $this->addField('created_at', 'Timestamp');

        $this->pk_fields = array('app_ref', 'token');
    }
}