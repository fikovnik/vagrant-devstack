#!/bin/bash

OPENSTACK_VERSION=stable/icehouse

#-------------------------------------------------------------------------------

base="`dirname \"$0\"`"
base="`( cd \"$BASHPATH\" && pwd )`"

sudo apt-get update -qqy
sudo apt-get install -qqy git

if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
fi

devstack_home="$HOME/devstack"

if [ ! -d "$devstack_home" ]; then
  git clone https://github.com/openstack-dev/devstack.git "$devstack_home"
fi

cd "$devstack_home"

cat > "local.conf" <<EOF
[[local|localrc]]

DEST=/opt/stack
LOGFILE=/opt/stack/logs/stack.sh.log
SCREEN_LOGDIR=/opt/stack/logs/screen

ADMIN_PASSWORD=admin
DATABASE_PASSWORD=\$ADMIN_PASSWORD
RABBIT_PASSWORD=\$ADMIN_PASSWORD
SERVICE_PASSWORD=\$ADMIN_PASSWORD
SERVICE_TOKEN=\$ADMIN_PASSWORD

HOST_IP=192.168.42.11
FLAT_INTERFACE=eth1
FIXED_RANGE=10.1.1.0/24
FIXED_NETWORK_SIZE=256
FLOATING_RANGE=192.168.42.128/25

EOF

./unstack.sh && ./stack.sh

echo "OFFLINE=True" >> local.conf

# enable Internet access for the VMs
# https://github.com/lorin/devstack-vm/issues/2#issuecomment-26503612 
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE

# openstack configuration
source $devstack_home/openrc admin admin

nova keypair-add --pub_key=~/.ssh/id_rsa.pub default	

nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
