# Installing AIStore using Ansible playbooks

## References
___
+ **AIStore K8s Deployment Guide**
https://github.com/NVIDIA/ais-k8s/blob/master/docs/README.md

+ **AIS K8s Playbooks**
https://github.com/NVIDIA/ais-k8s/blob/master/playbooks/README.md

+ **Using Kubespray to Establish a K8s Cluster for AIStore**
https://github.com/NVIDIA/ais-k8s/blob/master/docs/kubespray/README.md



## Hardware
___
|Role|FQDN|IP|OS|RAM|CPU|
|----|----|----|----|----|----|
|Ansible|articvm|10.0.2.15|CentOS 7|4GB|2|
|Master|acidscdcn001.rs.gsu.edu|10.245.11.145|Ubuntu 18.04|187G|56|
|Worker|acidscdcn002.rs.gsu.edu|10.245.11.146|Ubuntu 18.04|187G|56|
|Worker|acidscdcn003.rs.gsu.edu|10.245.11.147|Ubuntu 18.04|187G|56|
|Worker|acidscdcn004.rs.gsu.edu|10.245.11.148|Ubuntu 18.04|187G|56|
|Worker|acidscdcn005.rs.gsu.edu|10.245.11.149|Ubuntu 18.04|187G|56|
|Worker|acidscdcn006.rs.gsu.edu|10.245.11.150|Ubuntu 18.04|187G|56|


## Ansible Control Node Setup
____

#### **Version**
```bash
ansible 2.9.23
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/home/ageraldo1/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python2.7/site-packages/ansible
  executable location = /usr/bin/ansible
  python version = 2.7.5 (default, Nov 16 2020, 22:23:17) [GCC 4.8.5 20150623 (Red Hat 4.8.5-44)]
```

### **1. Create working directory**
```bash
mkdir -p $HOME/work_area

cd $HOME/work_area
``` 
### **2. Clone NVidia Git repositories**
```bash
git clone https://github.com/NVIDIA/ais-k8s.git
```

### **3. Add HPC SSH key to ssh-agent**
```bash
ssh-add /home/ageraldo1/ssh_keys/artic/hpcageraldo1
Identity added: /home/ageraldo1/ssh_keys/artic/hpcageraldo1 (/home/ageraldo1/ssh_keys/artic/hpcageraldo1)
```

### **4. Setup ansible working directory**
```bash
mkdir -p $HOME/work_area/ansible
cd $HOME/work_area/ansible
```

### **5. Setup ansible inventory file**
```ini
#inventory.ini
[master]
10.245.11.145 ansible_connection=ssh  ansible_user=hpcageraldo1

[worker]
10.245.11.146 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.147 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.148 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.149 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.150 ansible_connection=ssh  ansible_user=hpcageraldo1

[multi:children]
master
worker
```

### **6. Perform Ansible smoke test**
```bash
ansible -i inventory.ini -m ping all -b
```

**Output:**
```json
10.245.11.147 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    }, 
    "changed": false, 
    "ping": "pong"
}
10.245.11.145 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    }, 
    "changed": false, 
    "ping": "pong"
}
10.245.11.148 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    }, 
    "changed": false, 
    "ping": "pong"
}
10.245.11.149 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    }, 
    "changed": false, 
    "ping": "pong"
}
10.245.11.146 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    }, 
    "changed": false, 
    "ping": "pong"
}
10.245.11.150 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    }, 
    "changed": false, 
    "ping": "pong"
}
```
> **Hardware/software information of a node (including memory, disk, system setup):** ```ansible -i inventory.ini -m setup master -b```



## AIS K8s Playbooks
### Minimum Setup
**Reference:** https://github.com/NVIDIA/ais-k8s/tree/master/playbooks
___

### **1. Ansible host minimum configuration file**
+ **File location:** $HOME/work_area/ansible/host_minimum.ini

+ **Template:** $HOME/work_area/ais-k8s/playbooks/hosts-example.ini

```ini
#
# All cpu nodes, whether active in k8s cluster or not
#
[cpu-node-population]
10.245.11.145 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.146 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.147 ansible_connection=ssh  ansible_user=hpcageraldo1

#
# Active CPU worker nodes - those in AIS k8s cluster
#
[cpu-worker-node]
10.245.11.146 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.147 ansible_connection=ssh  ansible_user=hpcageraldo1

#
# Kube master hosts
#
[kube-master]
10.245.11.145 ansible_connection=ssh  ansible_user=hpcageraldo1



#
# The etcd cluster hosts
#
[etcd]
10.245.11.145 ansible_connection=ssh  ansible_user=hpcageraldo1

#
# As it says.
#
[first_three]
10.245.11.145 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.146 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.147 ansible_connection=ssh  ansible_user=hpcageraldo1


#
# As it says.
#
[last_three]
10.245.11.145 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.146 ansible_connection=ssh  ansible_user=hpcageraldo1
10.245.11.147 ansible_connection=ssh  ansible_user=hpcageraldo1


#
# kube-node addresses all worker nodes
#
[kube-node:children]
cpu-worker-node

#
# k8s-cluster addresses the worker nodes and the masters
#
[k8s-cluster:children]
kube-master
kube-node

#
# All nodes - not required by kubespray, so only for admin convenience.
# Loops in active workers of all types, etcd and master hosts.
#
# XXX Tempting to name this 'all', but Ansible seems to expand that to
# mean "all hosts mentioned in the inventory regardless of grouping".
#
[allactive:children]
k8s-cluster
etcd

#
# See kubespray docs/ansible.md
#
[calico-rr]

[es]
10.245.11.145 ansible_connection=ssh  ansible_user=hpcageraldo1
```

### **2. Export Ansible configuration file (AIS)**
```bash
cp $HOME/work_area/ais-k8s/playbooks/ansible-example.cfg $HOME/work_area/ansible/ansible.cfg

export ANSIBLE_CONFIG=$HOME/work_area/ansible/ansible.cfg
```

### **3. Enable MQ IO scheduler**
+ **Reference:** https://github.com/NVIDIA/ais-k8s/blob/master/playbooks/docs/ais_enable_multiqueue.md

```bash
ansible-playbook -i $HOME/work_area/ansible/host_minimum.ini $HOME/work_area/ais-k8s/playbooks/ais_enable_multiqueue.yml -e playhosts=cpu-worker-node --become
```

**Output:**
```
PLAY [cpu-worker-node] ***************************************************************************************************************************

TASK [ais_enable_multiqueue : Add line for MQ variable in grub cfg] ******************************************************************************
changed: [10.245.11.147]
changed: [10.245.11.146]

TASK [ais_enable_multiqueue : Include MQ in GRUB_CMDLINE_LINUX] **********************************************************************************
changed: [10.245.11.147]
changed: [10.245.11.146]

TASK [ais_enable_multiqueue : Update grub.cfg] ***************************************************************************************************
changed: [10.245.11.147]
changed: [10.245.11.146]

TASK [ais_enable_multiqueue : Note reboot required] **********************************************************************************************
ok: [10.245.11.146] => {
    "msg": "Manual reboot is required for MQ change to take effect"
}
ok: [10.245.11.147] => {
    "msg": "Manual reboot is required for MQ change to take effect"
}

PLAY RECAP ***************************************************************************************************************************************
10.245.11.146              : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
10.245.11.147              : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

**Reboot:**
```bash
ansible -i $HOME/work_area/ansible/host_minimum.ini cpu-worker-node -a "/sbin/shutdown -r +1" -b
```

### **4. Run ais_host_config_common on all nodes**
+ **Reference:** https://github.com/NVIDIA/ais-k8s/blob/master/playbooks/docs/ais_host_config_common.md

>**Note:** Using minimal requirement (tags = aisrequired)

+ **aisrequired**
    ```bash
    ansible-playbook $HOME/work_area/ais-k8s/playbooks/ais_host_config_common.yml --list-tasks  --tags aisrequired
    ```
    ```json
    tasks:
        ais_host_config_common : Configure ulimits for host	TAGS: [aisrequired, ulimits]
        ais_host_config_common : Tweak sysctl.conf - required tweaks	TAGS: [aisrequired, sysctlrequired]
    ```
+ **never**
    ```bash
    ansible-playbook $HOME/work_area/ais-k8s/playbooks/ais_host_config_common.yml --list-tasks  --tags never
    ```

    ```json
    tasks:
      ais_host_config_common : Disable unattended upgrades	TAGS: [aisdev, debugpkgs, never]
      ais_host_config_common : Install desired packages	TAGS: [aisdev, debugpkgs, never]
      ais_host_config_common : Tweak sysctl.conf - optional network tweaks	TAGS: [never, nvidiastd, sysctlnetwork]
      ais_host_config_common : Tweak sysctl.conf - optional misc bits	TAGS: [never, nvidiastd, sysctlnetmisc]
      ais_host_config_common : Set host mtu in netplan	TAGS: [aisdev, mtu, never, nvidiastd]
      ais_host_config_common : Apply netplan if changed	TAGS: [aisdev, mtu, never, nvidiastd]
      ais_host_config_common : Install packages required for cpupower	TAGS: [cpufreq, never, nvidiastd]
      ais_host_config_common : Set CPU frequency governor to requested mode	TAGS: [cpufreq, never, nvidiastd]
      ais_host_config_common : Persist CPU governor choice	TAGS: [cpufreq, never, nvidiastd]
      ais_host_config_common : Make sure we have a /usr/local/bin	TAGS: [iosched_ethtool, never, nvidiastd]
      ais_host_config_common : Install /usr/local/bin/ais_host_config.sh	TAGS: [iosched_ethtool, never, nvidiastd]
      ais_host_config_common : Create aishostconfig systemctl unit	TAGS: [iosched_ethtool, never, nvidiastd]
      ais_host_config_common : (Re)start aishostconfig service	TAGS: [iosched_ethtool, never, nvidiastd]
      pcm : Check PCM directory exists .	TAGS: [aisdev, never]
      pcm : Get PCM code as zip	TAGS: [aisdev, never]
      Unarchive pcm.zip	TAGS: [aisdev, never]
      pcm : Install PCM tool	TAGS: [aisdev, never]
    
    ```
+ **nvidiastd (post deployment)**
    ```bash
    ansible-playbook $HOME/work_area/ais-k8s/playbooks/ais_host_config_common.yml --list-tasks  --tags nvidiastd
    ```

    ```json
    tasks:
      ais_host_config_common : Tweak sysctl.conf - optional network tweaks	TAGS: [never, nvidiastd, sysctlnetwork]
      ais_host_config_common : Tweak sysctl.conf - optional misc bits	TAGS: [never, nvidiastd, sysctlnetmisc]
      ais_host_config_common : Set host mtu in netplan	TAGS: [aisdev, mtu, never, nvidiastd]
      ais_host_config_common : Apply netplan if changed	TAGS: [aisdev, mtu, never, nvidiastd]
      ais_host_config_common : Install packages required for cpupower	TAGS: [cpufreq, never, nvidiastd]
      ais_host_config_common : Set CPU frequency governor to requested mode	TAGS: [cpufreq, never, nvidiastd]
      ais_host_config_common : Persist CPU governor choice	TAGS: [cpufreq, never, nvidiastd]
      ais_host_config_common : Make sure we have a /usr/local/bin	TAGS: [iosched_ethtool, never, nvidiastd]
      ais_host_config_common : Install /usr/local/bin/ais_host_config.sh	TAGS: [iosched_ethtool, never, nvidiastd]
      ais_host_config_common : Create aishostconfig systemctl unit	TAGS: [iosched_ethtool, never, nvidiastd]
      ais_host_config_common : (Re)start aishostconfig service	TAGS: [iosched_ethtool, never, nvidiastd]

    ```


```bash
ansible-playbook -i $HOME/work_area/ansible/host_minimum.ini $HOME/work_area/ais-k8s/playbooks/ais_host_config_common.yml --become
```

**Output:**
```
PLAY [k8s-cluster] *******************************************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************************************
ok: [10.245.11.145]
ok: [10.245.11.147]
ok: [10.245.11.146]

TASK [ais_host_config_common : Configure ulimits for host] ***************************************************************************************
changed: [10.245.11.145] => (item={u'comment': u'required in AIS docs (but also need to change in pods)', u'limit_item': u'nofile', u'limit_type': u'soft', u'value': 1048576})
changed: [10.245.11.146] => (item={u'comment': u'required in AIS docs (but also need to change in pods)', u'limit_item': u'nofile', u'limit_type': u'soft', u'value': 1048576})
changed: [10.245.11.147] => (item={u'comment': u'required in AIS docs (but also need to change in pods)', u'limit_item': u'nofile', u'limit_type': u'soft', u'value': 1048576})
changed: [10.245.11.145] => (item={u'comment': u'required in AIS docs (but also need to change in pods)', u'limit_item': u'nofile', u'limit_type': u'hard', u'value': 1048576})
changed: [10.245.11.147] => (item={u'comment': u'required in AIS docs (but also need to change in pods)', u'limit_item': u'nofile', u'limit_type': u'hard', u'value': 1048576})
changed: [10.245.11.146] => (item={u'comment': u'required in AIS docs (but also need to change in pods)', u'limit_item': u'nofile', u'limit_type': u'hard', u'value': 1048576})

TASK [ais_host_config_common : Tweak sysctl.conf - required tweaks] ******************************************************************************
changed: [10.245.11.146] => (item={u'default': 128, u'comment': u'Maximum number of connection requests that can be queued to a given listening socket. Needs to absorb burst of connection requests. AIS clients will usually keep connections open to proxy and targets, so we do not expect ongoing high new connection rate.', u'state': u'present', u'name': u'net.core.somaxconn', u'value': 100000})
changed: [10.245.11.145] => (item={u'default': 128, u'comment': u'Maximum number of connection requests that can be queued to a given listening socket. Needs to absorb burst of connection requests. AIS clients will usually keep connections open to proxy and targets, so we do not expect ongoing high new connection rate.', u'state': u'present', u'name': u'net.core.somaxconn', u'value': 100000})
changed: [10.245.11.147] => (item={u'default': 128, u'comment': u'Maximum number of connection requests that can be queued to a given listening socket. Needs to absorb burst of connection requests. AIS clients will usually keep connections open to proxy and targets, so we do not expect ongoing high new connection rate.', u'state': u'present', u'name': u'net.core.somaxconn', u'value': 100000})
changed: [10.245.11.146] => (item={u'default': 0, u'comment': u'If sockets hang around in timewait state for long then (since we\'re PUTting and GETting lots of objects) we very soon find that we exhaust local port range. So we stretch the available range of local ports (ip_local_port_range), increase the max number of timewait buckets held by the system simultaneously (tcp_max_tw_buckets), and reuse sockets in timewait state as soon as it is "safe from a protocol point of view" (whatever that means, tcp_tw_reuse).', u'state': u'present', u'name': u'net.ipv4.tcp_tw_reuse', u'value': 1})
changed: [10.245.11.145] => (item={u'default': 0, u'comment': u'If sockets hang around in timewait state for long then (since we\'re PUTting and GETting lots of objects) we very soon find that we exhaust local port range. So we stretch the available range of local ports (ip_local_port_range), increase the max number of timewait buckets held by the system simultaneously (tcp_max_tw_buckets), and reuse sockets in timewait state as soon as it is "safe from a protocol point of view" (whatever that means, tcp_tw_reuse).', u'state': u'present', u'name': u'net.ipv4.tcp_tw_reuse', u'value': 1})
changed: [10.245.11.147] => (item={u'default': 0, u'comment': u'If sockets hang around in timewait state for long then (since we\'re PUTting and GETting lots of objects) we very soon find that we exhaust local port range. So we stretch the available range of local ports (ip_local_port_range), increase the max number of timewait buckets held by the system simultaneously (tcp_max_tw_buckets), and reuse sockets in timewait state as soon as it is "safe from a protocol point of view" (whatever that means, tcp_tw_reuse).', u'state': u'present', u'name': u'net.ipv4.tcp_tw_reuse', u'value': 1})
changed: [10.245.11.147] => (item={u'default': u'32768 60999', u'comment': u'See comment for tw_reuse', u'state': u'present', u'name': u'net.ipv4.ip_local_port_range', u'value': u'2048 65535'})
changed: [10.245.11.146] => (item={u'default': u'32768 60999', u'comment': u'See comment for tw_reuse', u'state': u'present', u'name': u'net.ipv4.ip_local_port_range', u'value': u'2048 65535'})
changed: [10.245.11.145] => (item={u'default': u'32768 60999', u'comment': u'See comment for tw_reuse', u'state': u'present', u'name': u'net.ipv4.ip_local_port_range', u'value': u'2048 65535'})
changed: [10.245.11.147] => (item={u'default': 262144, u'comment': u'See comment for tw_reuse', u'state': u'present', u'name': u'net.ipv4.tcp_max_tw_buckets', u'value': 1440000})
changed: [10.245.11.146] => (item={u'default': 262144, u'comment': u'See comment for tw_reuse', u'state': u'present', u'name': u'net.ipv4.tcp_max_tw_buckets', u'value': 1440000})
changed: [10.245.11.145] => (item={u'default': 262144, u'comment': u'See comment for tw_reuse', u'state': u'present', u'name': u'net.ipv4.tcp_max_tw_buckets', u'value': 1440000})

PLAY RECAP ***************************************************************************************************************************************
10.245.11.145              : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
10.245.11.146              : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
10.245.11.147              : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

### **5. Kuberspary setup**
+ **Reference:** https://github.com/NVIDIA/ais-k8s/blob/master/docs/kubespray/README.md

#### **a) Clone the Kubespray repo**
```bash
cd $HOME/work_area
git clone --branch v2.16.0 https://github.com/kubernetes-sigs/kubespray.git
```

#### **b) Install Kubespray requirements for the ansible controller**
```bash
cd kubespray
sudo pip install -r requirements.txt
```

#### **c) Copy the sample inventory as per the Kubespray README:**
```bash
mkdir inventory/aiscluster
cp -rf inventory/sample/* inventory/aiscluster/
```
#### **d) Update configuration files**
+ **inventory/aiscluster/group_vars/k8s_cluster/addons.yml**
    ```yaml
    helm_enabled: true
    metrics_server_enabled: true
    ```
+ **inventory/aiscluster/group_vars/k8s_cluster/k8s-cluster.yml**    
    ```yaml
    kube_service_addresses: 192.168.0.0/18
    kube_pods_subnet: 192.168.64.0/18
    cluster_name: aiscluster.local
    kubeconfig_localhost: true
    kubectl_localhost: true
    ```
+ **inventory/aiscluster/group_vars/k8s_cluster/k8s-net-calico.yml**    
    ```yaml
    nat_outgoing: true
    # if Set host mtu in netplan is applied
    # calico_mtu: 8980     
    ```

#### **e) Complete the ansible inventory file (inventory/aiscluster/hosts.ini)**

```bash
cp $HOME/work_area/ais-k8s/docs/kubespray/hosts.ini inventory/aiscluster/hosts.ini
```
**host.ini**
```ini
#
# All CPU nodes we want to talk to with Ansible, regardless of whether
# included/active in cluster.
#
[cpu-node-population]
acidscdcn001	 ansible_host=10.245.11.145 ansible_connection=ssh  ansible_user=hpcageraldo1
acidscdcn002	 ansible_host=10.245.11.146 ansible_connection=ssh  ansible_user=hpcageraldo1
acidscdcn003	 ansible_host=10.245.11.147 ansible_connection=ssh  ansible_user=hpcageraldo1

#
# All GPU nodes we want to talk to with Ansible, regardless of whether
# included/active in cluster.
#
[dgx-node-population]

#
# Active CPU worker nodes
#
[cpu-worker-node]
acidscdcn002
acidscdcn003

#
# Active GPU worker nodes
#
[gpu-worker-node]

#
# Kube master hosts
#
[kube-master]
acidscdcn001

#
# The etcd cluster hosts
#
[etcd]
acidscdcn001

#
# kube-node addresses all worker nodes
#
[kube-node:children]
cpu-worker-node
gpu-worker-node

#
# k8s-cluster addresses the worker nodes and the masters
#
[k8s-cluster:children]
kube-master
kube-node

[allactive:children]
k8s-cluster
etcd

[calico-rr]

[bastion]
```
#### **f) Run kubespray as follow**
```bash
# avoid using ansible.cfg file of a previous version
unset ANSIBLE_CONFIG

cd $HOME/work_area/kubespray
ansible-playbook -i inventory/aiscluster/hosts.ini cluster.yml --become
```
**Output:**

```
PLAY RECAP ***********************************************************************************************************************************************
acidscdcn001               : ok=602  changed=137  unreachable=0    failed=0    skipped=1083 rescued=0    ignored=1   
acidscdcn002               : ok=391  changed=82   unreachable=0    failed=0    skipped=705  rescued=0    ignored=0   
acidscdcn003               : ok=366  changed=79   unreachable=0    failed=0    skipped=621  rescued=0    ignored=0   
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

Thursday 22 July 2021  13:18:30 -0400 (0:00:00.189)       0:12:31.527 ********* 
=============================================================================== 
kubernetes/kubeadm : Join to cluster ------------------------------------------------------------------------------------------------------------- 25.56s
container-engine/docker : ensure docker packages are installed ----------------------------------------------------------------------------------- 20.76s
kubernetes/client : Copy kubectl binary to ansible host ------------------------------------------------------------------------------------------ 19.51s
kubernetes/control-plane : kubeadm | Initialize first master ------------------------------------------------------------------------------------- 16.82s
kubernetes-apps/ansible : Kubernetes Apps | Lay Down CoreDNS templates --------------------------------------------------------------------------- 16.64s
kubernetes-apps/metrics_server : Metrics Server | Create manifests ------------------------------------------------------------------------------- 15.18s
kubernetes/preinstall : Install packages requirements --------------------------------------------------------------------------------------------- 9.72s
kubernetes-apps/ansible : Kubernetes Apps | Start Resources --------------------------------------------------------------------------------------- 9.20s
network_plugin/calico : Calico | Create calico manifests ------------------------------------------------------------------------------------------ 8.51s
kubernetes/control-plane : Master | wait for kube-scheduler --------------------------------------------------------------------------------------- 6.97s
policy_controller/calico : Create calico-kube-controllers manifests ------------------------------------------------------------------------------- 6.79s
wait for etcd up ---------------------------------------------------------------------------------------------------------------------------------- 6.70s
kubernetes-apps/metrics_server : Metrics Server | Apply manifests --------------------------------------------------------------------------------- 6.27s
kubernetes/preinstall : Update package management cache (APT) ------------------------------------------------------------------------------------- 5.89s
kubernetes/preinstall : Get current calico cluster version ---------------------------------------------------------------------------------------- 5.70s
Configure | Check if etcd cluster is healthy ------------------------------------------------------------------------------------------------------ 5.52s
container-engine/docker : ensure docker-ce repository is enabled ---------------------------------------------------------------------------------- 5.39s
Configure | Wait for etcd cluster to be healthy --------------------------------------------------------------------------------------------------- 5.22s
kubernetes-apps/ansible : Kubernetes Apps | Lay Down nodelocaldns Template ------------------------------------------------------------------------ 4.95s
download_container | Download image if required --------------------------------------------------------------------------------------------------- 4.26s
```

#### **g) Kubectl config**
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### **h) Get Cluster Info**
```bash
kubectl get nodes -o wide
```

```bash
NAME           STATUS   ROLES                  AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
acidscdcn001   Ready    control-plane,master   64m   v1.20.7   10.245.11.145   <none>        Ubuntu 18.04.5 LTS   4.15.0-147-generic   docker://19.3.15
acidscdcn002   Ready    <none>                 62m   v1.20.7   10.245.11.146   <none>        Ubuntu 18.04.5 LTS   4.15.0-151-generic   docker://19.3.15
acidscdcn003   Ready    <none>                 62m   v1.20.7   10.245.11.147   <none>        Ubuntu 18.04.5 LTS   4.15.0-151-generic   docker://19.3.15
```

### **6. Perform ais_host_post_kubespray playbook**
+ **Reference:** https://github.com/NVIDIA/ais-k8s/blob/master/playbooks/docs/ais_host_post_kubespray.md

```bash
export ANSIBLE_CONFIG=$HOME/work_area/ansible/ansible.cfg

cd $HOME/work_area/ais-k8s/playbooks
ansible-playbook -i $HOME/work_area/ansible/host_minimum.ini ais_host_post_kubespray.yml -e playhosts=k8s-cluster --become
```

**Output:**

```
PLAY [k8s-cluster] ***************************************************************************************************************************************

TASK [ais_post_kubespray : Allow somaxconn sysctl in containers] *****************************************************************************************
changed: [10.245.11.145]
changed: [10.245.11.146]
changed: [10.245.11.147]

TASK [ais_post_kubespray : Restart kubeletenv] ***********************************************************************************************************
changed: [10.245.11.147]
changed: [10.245.11.146]
changed: [10.245.11.145]

PLAY RECAP ***********************************************************************************************************************************************
10.245.11.145              : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
10.245.11.146              : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
10.245.11.147              : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```


### **6. Make filesystems**
+ **Reference:** https://github.com/NVIDIA/ais-k8s/blob/master/playbooks/docs/ais_datafs.md


+ Available Disks
    + **acidscdcn001.rs.gsu.edu**
        + Disk /dev/sdc: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdd: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sde: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdf: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdg: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors

    + **acidscdcn002.rs.gsu.edu**
        + Disk /dev/sda: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdb: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdc: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdd: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sde: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors  
        + Disk /dev/sdf: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors

    + **acidscdcn003.rs.gsu.edu**
        + Disk /dev/sdb: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdc: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdd: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sde: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdf: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdg: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors


    + **Minimum setup selection**
        + Disk /dev/sdc: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdd: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sde: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors
        + Disk /dev/sdf: 1.7 TiB, 1800360124416 bytes, 3516328368 sectors


```bash
cd $HOME/work_area/ais-k8s/playbooks

ansible-playbook -i $HOME/work_area/ansible/host_minimum.ini ais_datafs_mkfs.yml -e '{"ais_hosts": ["10.245.11.146", "10.245.11.147"], "ais_devices": ["sdc", "sdd", "sde", "sdf"]}' --become
```

**Output:**

```
Are you sure you want to destroy and mkfs AIS filesystems on ['10.245.11.146', '10.245.11.147'], devices ['sdc', 'sdd', 'sde', 'sdf']? Type 'yes' to confirm. [no]: yes

PLAY [['10.245.11.146', '10.245.11.147']] ****************************************************************************************************************

TASK [check confirmation] ********************************************************************************************************************************
skipping: [10.245.11.147]
skipping: [10.245.11.146]

TASK [check disk list] ***********************************************************************************************************************************
skipping: [10.245.11.146]
skipping: [10.245.11.147]

TASK [ais_datafs : umount] *******************************************************************************************************************************
skipping: [10.245.11.147] => (item=sdc) 
skipping: [10.245.11.147] => (item=sdd) 
skipping: [10.245.11.147] => (item=sde) 
skipping: [10.245.11.147] => (item=sdf) 
skipping: [10.245.11.146] => (item=sdc) 
skipping: [10.245.11.146] => (item=sdd) 
skipping: [10.245.11.146] => (item=sde) 
skipping: [10.245.11.146] => (item=sdf) 

TASK [ais_datafs : umount and remove from fstab] *********************************************************************************************************
changed: [10.245.11.146] => (item=sdc)
changed: [10.245.11.146] => (item=sdd)
ok: [10.245.11.147] => (item=sdc)
changed: [10.245.11.146] => (item=sde)
ok: [10.245.11.147] => (item=sdd)
changed: [10.245.11.146] => (item=sdf)
ok: [10.245.11.147] => (item=sde)
ok: [10.245.11.147] => (item=sdf)

TASK [ais_datafs : mkfs] *********************************************************************************************************************************
changed: [10.245.11.147] => (item=sdc)
changed: [10.245.11.146] => (item=sdc)
changed: [10.245.11.147] => (item=sdd)
changed: [10.245.11.146] => (item=sdd)
changed: [10.245.11.147] => (item=sde)
changed: [10.245.11.146] => (item=sde)
changed: [10.245.11.147] => (item=sdf)
changed: [10.245.11.146] => (item=sdf)

TASK [ais_datafs : mount and populate fstab] *************************************************************************************************************
changed: [10.245.11.147] => (item=sdc)
changed: [10.245.11.146] => (item=sdc)
changed: [10.245.11.147] => (item=sdd)
changed: [10.245.11.146] => (item=sdd)
changed: [10.245.11.147] => (item=sde)
changed: [10.245.11.146] => (item=sde)
changed: [10.245.11.147] => (item=sdf)
changed: [10.245.11.146] => (item=sdf)

TASK [ais_datafs : chown and chmod ais dir] **************************************************************************************************************
changed: [10.245.11.146] => (item=sdc)
changed: [10.245.11.147] => (item=sdc)
changed: [10.245.11.147] => (item=sdd)
changed: [10.245.11.146] => (item=sdd)
changed: [10.245.11.147] => (item=sde)
changed: [10.245.11.146] => (item=sde)
changed: [10.245.11.147] => (item=sdf)
changed: [10.245.11.146] => (item=sdf)

PLAY RECAP ***********************************************************************************************************************************************
10.245.11.146              : ok=4    changed=4    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
10.245.11.147              : ok=4    changed=3    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
```

### **7. Deploy AIS K8s operator**
+ **Reference:** https://github.com/NVIDIA/ais-k8s/blob/master/playbooks/docs/ais_cluster_management.md

#### **a) Update ais_deploy_operator.yml file**
```yaml
---
- hosts: "{{ controller }}"
  gather_facts: no
  roles:
    - {role: ais_deploy_operator}
```

#### **b) Deploy operator**

```bash
cd $HOME/work_area/ais-k8s/playbooks

ansible-playbook -i $HOME/work_area/ansible/host_minimum.ini ais_deploy_operator.yml -e '{"controller": ["10.245.11.145"]}' --become
``` 


**Output:**
```
PLAY [['10.245.11.145']] *********************************************************************************************************************************

TASK [ais_deploy_operator : Copy operator deploy script] *************************************************************************************************
changed: [10.245.11.145]

TASK [ais_deploy_operator : Run deploy operator scripts] *************************************************************************************************
changed: [10.245.11.145]

PLAY RECAP ***********************************************************************************************************************************************
10.245.11.145              : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

#### **c) Deployment verification**
```bash
kubectl get pods -n ais-operator-system -o wide
```

```bash
NAME                                               READY   STATUS    RESTARTS   AGE     IP              NODE           NOMINATED NODE   READINESS GATES
ais-operator-controller-manager-79bfb76567-mdk5p   2/2     Running   0          2m23s   192.168.118.3   acidscdcn002   <none>           <none>
```

```bash
kubectl get pods -n cert-manager -o wide
```

```
NAME                                       READY   STATUS    RESTARTS   AGE     IP              NODE           NOMINATED NODE   READINESS GATES
cert-manager-6588898cb4-lfq2w              1/1     Running   0          2m53s   192.168.118.2   acidscdcn002   <none>           <none>
cert-manager-cainjector-7bcbdbd99f-kds5v   1/1     Running   0          2m53s   192.168.104.2   acidscdcn003   <none>           <none>
cert-manager-webhook-5fd9f9dd86-64ppr      1/1     Running   0          2m53s   192.168.104.1   acidscdcn003   <none>           <none>
```

```bash
kubectl get deployment -n ais-operator-system
```

```
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
ais-operator-controller-manager   1/1     1            1           9m14s
```


### **8. Deploy AIS cluster**
+ **Reference:** https://github.com/NVIDIA/ais-k8s/blob/master/playbooks/docs/ais_cluster_management.md


#### **a) Update ais_deploy_cluster.yml file**
```yaml
---
- hosts: "{{ controller }}"
  gather_facts: no
  vars_files:
    - "vars/ais_mpaths.yml"

  pre_tasks:
    - name: check mountpath list
      fail:
        msg: "no ais_mpaths specified!"
      when: ais_mpaths is undefined

    - name: check mountpath size
      fail:
        msg: "no ais_mpath_size specified!"
      when: ais_mpath_size is undefined

  roles:
    - {role: ais_deploy_cluster}
```
#### **b) Update vars/ais_mpaths.yml**
```yaml
ais_mpaths:
  - "/ais/sdc"
  - "/ais/sdd"
  - "/ais/sde"
  - "/ais/sdf"
ais_mpath_size: 1.7Ti
```

#### **c) Deploy AIS Cluster**

```bash
cd $HOME/work_area/ais-k8s/playbooks

ansible-playbook -i $HOME/work_area/ansible/host_minimum.ini ais_deploy_cluster.yml -e cluster="ais" -e controller="10.245.11.145" --become
```

**Output:**
```
PLAY [10.245.11.145] *************************************************************************************************************************************

TASK [check mountpath list] ******************************************************************************************************************************
skipping: [10.245.11.145]

TASK [check mountpath size] ******************************************************************************************************************************
skipping: [10.245.11.145]

TASK [ais_deploy_cluster : Copy PV scripts/templates] ****************************************************************************************************
ok: [10.245.11.145] => (item=create-pvs.sh)
ok: [10.245.11.145] => (item=pv.template.yaml)
ok: [10.245.11.145] => (item=label-nodes.sh)

TASK [ais_deploy_cluster : Copy cluster yaml] ************************************************************************************************************
changed: [10.245.11.145]

TASK [ais_deploy_cluster : Create PVs] *******************************************************************************************************************
changed: [10.245.11.145]

TASK [ais_deploy_cluster : Create namespace if not exists] ***********************************************************************************************
ok: [10.245.11.145]

TASK [ais_deploy_cluster : Label nodes] ******************************************************************************************************************
ok: [10.245.11.145]

TASK [ais_deploy_cluster : Deploy clusters] **************************************************************************************************************
changed: [10.245.11.145]

PLAY RECAP ***********************************************************************************************************************************************
10.245.11.145              : ok=6    changed=3    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0   
```
> **NOTE**: To destroy cluster, execute:
```bash
ansible-playbook -i $HOME/work_area/ansible/host_minimum.ini ais_destroy_cluster.yml -e cluster="ais" -e controller="10.245.11.145" --become
```

#### **d) Deployment verification**
> **AIS Namespace:** ais

+ Persist Volumes
    ```bash
    kubectl get pvc -n ais
    ```

    ``` 
    NAME                       STATUS   VOLUME                    CAPACITY   ACCESS MODES   STORAGECLASS        AGE
    ais-ais-sdc-ais-target-0   Bound    acidscdcn003-pv-ais-sdc   500Gi      RWO            ais-local-storage   5s
    ais-ais-sdc-ais-target-1   Bound    acidscdcn002-pv-ais-sdc   500Gi      RWO            ais-local-storage   5s
    ais-ais-sdd-ais-target-0   Bound    acidscdcn003-pv-ais-sdd   500Gi      RWO            ais-local-storage   5s
    ais-ais-sdd-ais-target-1   Bound    acidscdcn002-pv-ais-sdd   500Gi      RWO            ais-local-storage   5s
    ais-ais-sde-ais-target-0   Bound    acidscdcn003-pv-ais-sde   500Gi      RWO            ais-local-storage   5s
    ais-ais-sde-ais-target-1   Bound    acidscdcn002-pv-ais-sde   500Gi      RWO            ais-local-storage   5s
    ais-ais-sdf-ais-target-0   Bound    acidscdcn003-pv-ais-sdf   500Gi      RWO            ais-local-storage   5s
    ais-ais-sdf-ais-target-1   Bound    acidscdcn002-pv-ais-sdf   500Gi      RWO            ais-local-storage   5s
    ```

+ PODS
    ```bash
    kubectl get pods -n ais -o wide
    ```

    ```
    NAME           READY   STATUS    RESTARTS   AGE     IP              NODE           NOMINATED NODE   READINESS GATES
    ais-proxy-0    1/1     Running   0          2m25s   192.168.118.6   acidscdcn002   <none>           <none>
    ais-proxy-1    1/1     Running   0          2m15s   192.168.104.5   acidscdcn003   <none>           <none>
    ais-target-0   1/1     Running   0          2m5s    192.168.104.6   acidscdcn003   <none>           <none>
    ais-target-1   1/1     Running   0          2m5s    192.168.118.7   acidscdcn002   <none>           <none>
    ```

+ AIS proxy
    ```bash
    curl -X GET http://192.168.104.5:51080/v1/daemon?what=config
    ```

    ```json
    {
    "backend":null,
    "mirror":{
        "copies":2,
        "util_thresh":0,
        "burst_buffer":512,
        "optimize_put":false,
        "enabled":true
    },
    "ec":{
        "objsize_limit":262144,
        "compression":"never",
        "data_slices":2,
        "parity_slices":2,
        "batch_size":64,
        "enabled":false,
        "disk_only":false
    },
    "log":{
        "level":"3",
        "max_size":4194304,
        "max_total":67108864
    },
    "periodic":{
        "stats_time":"10s",
        "retry_sync_time":"2s",
        "notif_time":"30s"
    },
    "timeout":{
        "cplane_operation":"2s",
        "max_keepalive":"4s",
        "max_host_busy":"20s",
        "startup_time":"1m",
        "send_file_time":"5m"
    },
    "client":{
        "client_timeout":"2m",
        "client_long_timeout":"30m",
        "list_timeout":"10m",
        "features":"0"
    },
    "proxy":{
        "primary_url":"http://10.245.11.147:51080",
        "original_url":"http://ais-proxy:51080",
        "discovery_url":"http://ais-proxy:51080",
        "non_electable":false
    },
    "lru":{
        "lowwm":75,
        "highwm":90,
        "out_of_space":95,
        "dont_evict_time":"2h0m",
        "capacity_upd_time":"10m",
        "enabled":false
    },
    "disk":{
        "disk_util_low_wm":20,
        "disk_util_high_wm":80,
        "disk_util_max_wm":95,
        "iostat_time_long":"2s",
        "iostat_time_short":"100ms"
    },
    "rebalance":{
        "dest_retry_time":"2m",
        "quiescent":"20s",
        "compression":"never",
        "multiplier":2,
        "enabled":false
    },
    "resilver":{
        "enabled":false
    },
    "checksum":{
        "type":"xxhash",
        "validate_cold_get":true,
        "validate_warm_get":false,
        "validate_obj_move":false,
        "enable_read_range":false
    },
    "versioning":{
        "enabled":true,
        "validate_warm_get":false
    },
    "net":{
        "l4":{
            "proto":"tcp",
            "sndrcv_buf_size":0
        },
        "http":{
            "server_crt":"",
            "server_key":"",
            "write_buffer_size":0,
            "read_buffer_size":0,
            "use_https":false,
            "skip_verify":false,
            "chunked_transfer":true
        }
    },
    "fshc":{
        "test_files":4,
        "error_limit":2,
        "enabled":true
    },
    "auth":{
        "secret":"",
        "enabled":false
    },
    "keepalivetracker":{
        "proxy":{
            "interval":"10s",
            "name":"heartbeat",
            "factor":3
        },
        "target":{
            "interval":"10s",
            "name":"heartbeat",
            "factor":3
        },
        "retry_factor":5,
        "timeout_factor":3
    },
    "downloader":{
        "timeout":"1h0m"
    },
    "distributed_sort":{
        "duplicated_records":"ignore",
        "missing_shards":"ignore",
        "ekm_malformed_line":"abort",
        "ekm_missing_key":"abort",
        "default_max_mem_usage":"80%",
        "call_timeout":"10m",
        "compression":"never",
        "dsorter_mem_threshold":"100GB"
    },
    "compression":{
        "block_size":262144,
        "checksum":false
    },
    "md_write":"",
    "lastupdate_time":"2021-07-23 16:49:54.909206001 +0000 UTC m=+60.066484872",
    "uuid":"Re_A9Gr8n",
    "config_version":"1",
    "replication":{
        "on_cold_get":false,
        "on_put":false,
        "on_lru_eviction":false
    },
    "confdir":"/etc/ais",
    "log_dir":"/var/log/ais",
    "host_net":{
        "hostname":"10.245.11.147",
        "hostname_intra_control":"ais-proxy-1.ais-proxy.ais.svc.aiscluster.local",
        "hostname_intra_data":"ais-proxy-1.ais-proxy.ais.svc.aiscluster.local",
        "port":"51080",
        "port_intra_control":"51081",
        "port_intra_data":"51082"
    },
    "fspaths":null,
    "test_fspaths":{
        "root":"",
        "count":0,
        "instance":0
    }
    }    
    ```

## AIS CLI configuration
**Reference:** https://github.com/NVIDIA/aistore/blob/master/docs/cli.md#installing
____

### **1. Download AIS CLI distribution**
+ **URL:** https://github.com/NVIDIA/aistore/releases/tag/3.6
+ **Release:** ais-linux-amd64

### **2. Make binary distribution file executable**
```bash
sudo cp $HOME/Downloads/ais-linux-amd64 /usr/local/bin/ais
sudo chmod +x /usr/local/bin/ais
```

### **3. Export AIS_ENDPOINT variable**
```bash
export AIS_ENDPOINT="http://10.245.11.146:51080"
```

### **4. Get Cluster Information**
```bash
ais show cluster
```

**Output:**
```
ROXY		 MEM USED %	 MEM AVAIL	 UPTIME
JtuUUZOV[P]	 0.03%		 187.54GiB	 3d22h
sbFpwhLU	 0.03%		 187.54GiB	 3d22h

TARGET		 MEM USED %	 MEM AVAIL	 CAP USED %	 CAP AVAIL	 CPU USED %	 REBALANCE	 UPTIME
IfNrGyZK	 0.03%		 187.54GiB	 0.00%		 6.540TiB	 0.08%		 -		 3d22h
zsmNOXSO	 0.03%		 187.54GiB	 0.00%		 6.540TiB	 0.08%		 -		 3d22h

Summary:
 Proxies:	2 (0 unelectable)
 Targets:	2
 Primary Proxy:	JtuUUZOV
 Smap Version:	10
 Deployment:	K8s
```

### **5. Get Disk Information**
```bash
ais show disk
```
**Output:**
```
TARGET		 DISK	 READ	 WRITE	 UTIL %
IfNrGyZK	 sdc	 0B/s	 0B/s	 0%
IfNrGyZK	 sdd	 0B/s	 0B/s	 0%
IfNrGyZK	 sde	 0B/s	 0B/s	 0%
IfNrGyZK	 sdf	 0B/s	 0B/s	 0%
zsmNOXSO	 sdc	 0B/s	 0B/s	 0%
zsmNOXSO	 sdd	 0B/s	 0B/s	 0%
zsmNOXSO	 sde	 0B/s	 0B/s	 0%
zsmNOXSO	 sdf	 0B/s	 0B/s	 0%
```

### **6. Create a dummy file**
```bash
fallocate -l 1M dummy.out
```

### **7. Create a new AIS bucket**
```bash
ais bucket create ais://smoke_test
```

**Output:**
```
"ais://smoke_test" bucket created
```

### **8. Upload dummy file to AIS bucket**
```bash
ais object put --progress dummy.out ais://smoke_test
```
**Output:**
```
dummy.out 1.00 MiB / 1.00 MiB [==============================================================] 100 %
PUT "dummy.out" into bucket "ais://smoke_test"
```


## AIS Loader
+ **Reference:** https://github.com/NVIDIA/aistore/blob/master/docs/aisloader.md
____

### **1. Download AIS loader distribution**
+ **URL:** https://github.com/NVIDIA/aistore/releases/tag/3.6
+ **Release:** aisloader-linux-amd64

### **2. Make binary distribution file executable**
```bash
sudo cp $HOME/Downloads/aisloader-linux-amd64 /usr/local/bin/aisloader
sudo chmod +x /usr/local/bin/aisloader
```







