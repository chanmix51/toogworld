<?php

namespace Toogworld\Cryptlib;

class Cryptlib
{
    static protected function formatSalt($salt)
    {
        $split = preg_split('/@/', $salt);

        return sprintf('$1$%.12s$', $split[0]);
    }

    static public function encrypt($string, $salt)
    {
        return crypt($string, self::formatSalt($salt));
    }
}
