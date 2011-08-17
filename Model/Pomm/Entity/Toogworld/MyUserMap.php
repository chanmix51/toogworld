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
}
