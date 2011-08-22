<?php

namespace Model\Pomm\Entity\Toogworld;

use Pomm\Object\BaseObject;
use Pomm\Exception\Exception;

class Tool extends BaseObject
{
    public function getUrl()
    {
        return array_key_exists('url', $this->fields) ? $this->fields['url'] : sprintf("%s.%s.%s", $this['name_slug'], $this['zone_slug'], $_SERVER['SERVER_NAME']);
    }
}
