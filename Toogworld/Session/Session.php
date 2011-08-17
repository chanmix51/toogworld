<?php

namespace Toogworld\Session;

use Model\Pomm\Entity\Toogworld\MyUser as User;

class Session extends \Symfony\Component\HttpFoundation\Session
{
    protected $container;
    protected $user;

    public function setContainer($app)
    {
        $this->container = $app;
    }

    public function authenticate(User $user)
    {
        $this->set('user_id', $user->getId());
        $this->user = $user;
    }

    public function isAuthenticated()
    {
        return $this->has('user_id');
    }

    public function deauthenticate()
    {
        $this->remove('user_id');
        $this->user = null;
    }

    public function getUser()
    {
        if (is_null($this->user) && ($this->isAuthenticated()))
        {
            $this->user = $this->container['pomm']
                ->getDatabase()
                ->createConnection()
                ->getMapFor('Model\Pomm\Entity\Toogworld')
                ->findByPk(array('id' => $this->get('user_id')));
        }

        return $this->user;
    }
}
