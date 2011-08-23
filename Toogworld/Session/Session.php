<?php

namespace Toogworld\Session;

use Model\Pomm\Entity\Toogworld\MyUser as User;

class Session extends \Symfony\Component\HttpFoundation\Session
{
    protected $container;
    protected $user;
    protected $connection;

    public function setContainer($app)
    {
        $this->container = $app;
        $this->connection = $this->container['pomm']
            ->getDatabase()
            ->createConnection();
    }

    public function authenticate(User $user)
    {
        $this->set('user_id', $user->getId());
        $this->user = $user;

        $url_back = '/';

        if ($this->has('token') && $this->has('app_ref'))
        {
            $map = $this->connection
                ->getMapFor('Model\Pomm\Entity\Toogworld\AppAuth');

            $map->deleteTokensForUser($user);
            $this->addToken($this->get('app_ref'), $this->get('token'), $map);

            $url_back = $this->get('url_back');

            $this->remove('app_ref');
            $this->remove('token');
        }

        if ($user['password_nuke'] > 0 && --$user['password_nuke'] == 0)
        {
            $url_back = '/nuke_password';
        }
        elseif ($this->has('url_back'))
        {
            $this->remove('url_back');
        }

        return $url_back;
    }

    public function isAuthenticated()
    {
        return $this->has('user_id');
    }

    public function deauthenticate()
    {
        $this->connection->getMapFor('Model\Pomm\Entity\Toogworld\AppAuth')
            ->deleteTokensForUser($this->getUser());

        $this->remove('user_id');
        $this->remove('tokens');
        $this->user = null;
    }

    public function getUser()
    {
        if (is_null($this->user) && ($this->isAuthenticated()))
        {
            $this->user = $this->connection
                ->getMapFor('Model\Pomm\Entity\Toogworld\MyUser')
                ->findByPk(array('id' => $this->get('user_id')));
        }

        return $this->user;
    }

    public function addToken($app_ref, $token, \Model\Pomm\Entity\Toogworld\AppAuthMap $map = null)
    {
        $map =  ! is_null($map) ? $map : $this->connection->getMapFor('Model\Pomm\Entity\Toogworld\AppAuth');

        if (!$this->has('tokens'))
        {
            $this->set('tokens', array());
        }

        $this->attributes['tokens'][$app_ref] = $token;

        $map->addNew($app_ref, $token, $this->get('user_id'));
    }

    public function hasToken($app_ref)
    {
        return $this->has('tokens') && array_key_exists($app_ref, $this->attributes['tokens']) ? $this->attributes['tokens'][$app_ref] : false;
    }

}
