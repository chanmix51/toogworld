<?php

namespace Model\Pomm\Entity\Toogworld;

use Pomm\Object\BaseObject;
use Pomm\Exception\Exception;
use Toogworld\Cryptlib\Cryptlib;

class MyUser extends BaseObject
{
    public function setPassword($password)
    {
        parent::set('password', Cryptlib::encrypt($password, $this->email));
    }

    public function getPassword()
    {
        throw new LogicException('Can not access password from here, sorry.');
    }
}
