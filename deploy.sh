#!/bin/bash

for i in `vagrant global-status | grep libvirt | awk '{ print $1 }'` ; do vagrant destroy -f $i ; done

vagrant up --no-provision
vagrant provision
cp .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory kubespray/inventory/aiscluster/hosts.ini

ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory -e playhosts=cpu-worker-node --become playbooks/ais_enable_multiqueue.yml
ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory playbooks/ais_host_config_common.yml --list-tasks  --tags aisrequired
ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory playbooks/ais_host_config_common.yml --list-tasks  --tags never
ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory --become playbooks/ais_host_config_common.yml

#set group vars for network and other stuff from kubespray section
unset ANSIBLE_CONFIG
cd kubspray
ansible-playbook -i kubespray/inventory/aiscluster/hosts.ini kubespray/cluster.yml --become
cd ../

export ANSIBLE_CONFIG=ansible.cfg
ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory --become playbooks/ais_host_post_kubespray.yml

ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory --become playbooks/ais_config_users_control.yml

ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory --become playbooks/ais_datafs_mkfs.yml -e '{"ais_hosts": ["node-09","node-10"], "ais_devices": ["vdb", "vdc", "vde", "vdf","vdg"]}' --become

ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory --become playbooks/ais_deploy_operator.yml -e '{"controller": ["node-08"]}' --become

ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory playbooks/ais_deploy_cluster.yml -e cluster="ais" -e controller="node-08" --become
