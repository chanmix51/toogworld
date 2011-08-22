<?php

namespace Model\Pomm\Entity\Toogworld\Base;

use Pomm\Object\BaseObjectMap;
use Pomm\Exception\Exception;

abstract class ToolMap extends BaseObjectMap
{
    public function initialize()
    {
        $this->object_class =  'Model\Pomm\Entity\Toogworld\Tool';
        $this->object_name  =  'toogworld.tool';

        $this->addField('id', 'Number');
        $this->addField('name', 'String');
        $this->addField('name_slug', 'String');
        $this->addField('zone', 'String');
        $this->addField('zone_slug', 'String');
        $this->addField('url', 'String');
        $this->addField('type', 'String');
        $this->addField('created_at', 'Timestamp');

        $this->pk_fields = array('id');
    }
}