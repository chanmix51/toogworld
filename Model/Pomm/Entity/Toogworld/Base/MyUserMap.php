<?php

namespace Model\Pomm\Entity\Toogworld\Base;

use Pomm\Object\BaseObjectMap;
use Pomm\Exception\Exception;

abstract class MyUserMap extends BaseObjectMap
{
    public function initialize()
    {
        $this->object_class =  'Model\Pomm\Entity\Toogworld\MyUser';
        $this->object_name  =  'toogworld.my_user';

        $this->addField('id', 'Number');
        $this->addField('email', 'String');
        $this->addField('password', 'String');
        $this->addField('is_active', 'Boolean');
        $this->addField('password_nuke', 'Number');

        $this->pk_fields = array('id');
    }
}