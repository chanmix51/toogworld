<?php

namespace Model\Pomm\Entity\Toogworld;

use Pomm\Object\BaseObject;
use Pomm\Exception\Exception;
use Toogworld\Cryptlib\Cryptlib;

class MyUser extends BaseObject
{
    public function validatePassword($password)
    {
        return (strlen($password) >= 10) && (preg_match('/[a-z]{8,}/i', $password));
    }

    public function setPassword($password)
    {

        if ($this->validatePassword($password))
        {
            parent::set('password', Cryptlib::encrypt($password, $this->email));
        }
        else 
        {
            throw new ValidationException("Invalid password.");
        }
    }

    public function getPassword()
    {
        throw new LogicException('Can not access password from here, sorry.');
    }
}
