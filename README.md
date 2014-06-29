# vagrant-devstack

A sample [devstack](http://devstack.org) deployment in [Vagrant](http://vagrantup.com).
While there are plenty of similar projects on [github](https://github.com/search?q=vagrant%20devstack) and elsewhere, I did not find a one that would satisfy the following requirements:

- support single/multi-node deployment
- minimum dependencies, i.e., no Chef, Puppet and the like
- allows one to connect to VMs from the host machine using floating IPs
- allows one to connect to Internet from VMs
- transparently caches packages (APT, PIP) to speed up deployment

## single-node setup

1. Boot up

  ```sh
  $ git clone 
  $ cd vagrant-devstack/single-node
  $ vagrant up
  ...
  Horizon is now available at http://192.168.1.11/
  Keystone is serving at http://192.168.1.11:5000/v2.0/
  Examples on using novaclient command line is in exercise.sh
  The default users are: admin and demo
  The password: admin
  This is your host ip: 192.168.1.11
  ```

1. Create a new VM using CLI 
    1. Connect to the control node (using vagrant)
  
        ```sh
        [host:single-node (master)]$ vagrant ssh
        ```

    1. Connect to the control node (using plain ssh)

        ```sh
        [host:~]$ ssh vagrant@192.168.1.11
        ```
  
    1. Spawn a new instance
   
        ```sh
        vagrant@devstack:~$ source devstack/openrc admin admin
        vagrant@devstack:~$ nova boot --flavor m1.micro --image cirros-0.3.2-x86_64-uec --key-name devstack  myvm
        ```
  
    1. Associate it with a floating ip
        
        ```sh
        vagrant@devstack:~$ nova floating-ip-create
        vagrant@devstack:~$ nova floating-ip-associate myvm 192.168.1.129
        ```

    1. Check
        
        ```sh
        vagrant@devstack:~$ nova list
        +--------------------------------------+------+--------+------------+-------------+---------------------------------+
        | ID                                   | Name | Status | Task State | Power State | Networks                        |
        +--------------------------------------+------+--------+------------+-------------+---------------------------------+
        | d453bf24-1ca4-45e3-980b-631b22c9782d | myvm | ACTIVE | -          | Running     | private=10.1.1.2, 192.168.1.129 |
        +--------------------------------------+------+--------+------------+-------------+---------------------------------+
        ```

1. Create a new VM using GUI
   - Navigate to [http://192.168.1.11/](http://192.168.1.11/)

1. Test the VMs

    1. Connect to myvm from the host
  
        ```sh
        [host:~]$ ssh cirros@192.168.1.129
        ```

    1. Check if it can access Internet
   
        ```sh
        $ ping google.com
        PING google.com (173.194.34.14): 56 data bytes
        64 bytes from 173.194.34.14: seq=0 ttl=61 time=8.733 ms
        64 bytes from 173.194.34.14: seq=1 ttl=61 time=8.089 ms
        ```
  
    1. Check if it can access the out vm
  
        _The following depends on how did you create the VM in Horizon console._

        ```sh
        $ ping 192.168.1.130
        ```

## multi-node setup

Multi node deployment is pretty much the same as the single-node.
Before you boot it using `vagrant up` check the `Vagrantfile` if the node configuration is reasonable for the host machine.