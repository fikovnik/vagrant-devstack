#!/bin/bash

OPENSTACK_VERSION=stable/icehouse

#-------------------------------------------------------------------------------

base="`dirname \"$0\"`"
base="`( cd \"$BASHPATH\" && pwd )`"

sudo apt-get update
sudo apt-get install -qqy git

if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
fi

devstack_home="$HOME/devstack"

if [ ! -d "$devstack_home" ]
then
  git clone -b $OPENSTACK_VERSION https://github.com/openstack-dev/devstack.git "$devstack_home"
fi

cat > "$devstack_home/local.conf" <<EOF
[[local|localrc]]

# MULTI_HOST=1
DEST=/opt/stack
SCREEN_LOGDIR=/opt/stack/logs/screen

ADMIN_PASSWORD=admin
DATABASE_PASSWORD=\$ADMIN_PASSWORD
RABBIT_PASSWORD=\$ADMIN_PASSWORD
SERVICE_PASSWORD=\$ADMIN_PASSWORD
SERVICE_TOKEN=\$ADMIN_PASSWORD

HOST_IP=192.168.1.11
FLAT_INTERFACE=eth1
FIXED_RANGE=10.1.1.0/24
FIXED_NETWORK_SIZE=256
FLOATING_RANGE=192.168.1.128/25
#PUBLIC_INTERFACE=eth1

# Disable default enabled services
#disable_service cinder c-sch c-api c-vol
#disable_service tempest
#disable_service horizon

#CINDER_BRANCH=$OPENSTACK_VERSION
#GLANCE_BRANCH=$OPENSTACK_VERSION
#HORIZON_BRANCH=$OPENSTACK_VERSION
#KEYSTONE_BRANCH=$OPENSTACK_VERSION
#NOVA_BRANCH=$OPENSTACK_VERSION
#SWIFT_BRANCH=$OPENSTACK_VERSION
EOF

cd "$devstack_home"

# WORKAROUND: https://bugs.launchpad.net/python-openstackclient/+bug/1326811
patch_1326811="bug_1326811.patch" 
if [ ! -f "$patch_1326811" ]; then
  git fetch https://review.openstack.org/openstack-dev/devstack refs/changes/63/98263/1 && git format-patch -1 --stdout FETCH_HEAD > "$patch_1326811"
  git apply < "$patch_1326811"
fi

./unstack.sh && FORCE=yes ./stack.sh

# enable Internet access for the VMs
# https://github.com/lorin/devstack-vm/issues/2#issuecomment-26503612 
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE

# openstack configuration
source $devstack_home/openrc admin admin

nova keypair-add --pub_key=~/.ssh/id_rsa.pub $(hostname)

nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
