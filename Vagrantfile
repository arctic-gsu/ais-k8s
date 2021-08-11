vm1 = 'node-08'
vm2 = 'node-09'
vm3 = 'node-10'
vm4 = 'node-11'
vm5 = 'node-12'
vm6 = 'node-13'
vm7 = 'node-14'
vm8 = 'node-15'
vm9 = 'node-16'
vm10 = 'node-17'
vm11 = 'node-18'
vm12 = 'node-19'
vm13 = 'node-20'

servers = [
  { svrName: "#{vm1}", template: 'ubuntu/bionic64', ip: '10.10.10.108',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm2}", template: 'ubuntu/bionic64', ip: '10.10.10.109',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm3}", template: 'ubuntu/bionic64', ip: '10.10.10.110',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm4}", template: 'ubuntu/bionic64', ip: '10.10.10.111',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm5}", template: 'ubuntu/bionic64', ip: '10.10.10.112',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm6}", template: 'ubuntu/bionic64', ip: '10.10.10.113',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm7}", template: 'ubuntu/bionic64', ip: '10.10.10.114',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm8}", template: 'ubuntu/bionic64', ip: '10.10.10.115',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm9}", template: 'ubuntu/bionic64', ip: '10.10.10.116',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm10}", template: 'ubuntu/bionic64', ip: '10.10.10.117',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm11}", template: 'ubuntu/bionic64', ip: '10.10.10.118',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm12}", template: 'ubuntu/bionic64', ip: '10.10.10.119',  memory: '2048', vcpus: '1' },
  { svrName: "#{vm13}", template: 'ubuntu/bionic64', ip: '10.10.10.120',  memory: '2048', vcpus: '1' }
]

inventory = {
      "cpu-node-population" => ["#{vm1}","#{vm2}","#{vm3}","#{vm4}","#{vm5}","#{vm6}","#{vm7}","#{vm8}","#{vm9}","#{vm10}","#{vm11}","#{vm12}"],
      "cpu-worker-node" => ["#{vm1}","#{vm2}","#{vm3}","#{vm4}","#{vm5}","#{vm6}","#{vm7}","#{vm8}","#{vm9}","#{vm10}","#{vm11}","#{vm12}"],
      "kube-master" => ["#{vm1}","#{vm2}","#{vm3}"],
      "etcd" => ["#{vm1}","#{vm2}","#{vm3}"],
      "first_three" => ["#{vm1}","#{vm2}","#{vm3}"],
      "last_three" => ["#{vm10}","#{vm11}","#{vm12}"],
      "kube_control_plane" => ["#{vm1}","#{vm2}","#{vm3}"],
      "kube-node:children" => ["cpu-worker-node"],
      "k8s-cluster:children" => ["kube-master","kube-node","calico-rr"],
      "allactive:children" => ["k8s-cluster","etcd"],
      "calico-rr" => [],
      "es" => ["#{vm1}","#{vm2}","#{vm3}"]

}

host_vars = {
      "#{vm1}" => { "ip" => "10.10.10.108", "etcd_member_name" => "etcd1"},
      "#{vm2}" => { "ip" => "10.10.10.109", "etcd_member_name" => "etcd2"},
      "#{vm3}" => { "ip" => "10.10.10.110", "etcd_member_name" => "etcd3"},
      "#{vm4}" => { "ip" => "10.10.10.111", "etcd_member_name" => "etcd4"},
      "#{vm5}" => { "ip" => "10.10.10.112", "etcd_member_name" => "etcd5"},
      "#{vm6}" => { "ip" => "10.10.10.113", "etcd_member_name" => "etcd6"},
      "#{vm7}" => { "ip" => "10.10.10.114"},
      "#{vm8}" => { "ip" => "10.10.10.115"},
      "#{vm9}" => { "ip" => "10.10.10.116"},
      "#{vm10}" => { "ip" => "10.10.10.117"},
      "#{vm11}" => { "ip" => "10.10.10.118"},
      "#{vm12}" => { "ip" => "10.10.10.119"}
}

Vagrant.configure('2') do |config|

  servers.each do |server|

    host_name = server[:svrName]

    config.vm.define host_name do |node|

        node.vm.hostname = host_name
        node.vm.box = server[:template]
        node.vm.network 'private_network', ip: server[:ip]
        #node.vm.network "public_network", :dev => "br0", :mode => 'bridge', :type => "bridge"

        node.vm.provider :virtualbox do |v|
            v.memory = server[:memory]
            v.cpus = server[:vcpus]
        end

        config.vm.provision "step1", type: "ansible" do |ansible|
          ansible.host_vars = host_vars
          ansible.groups = inventory
          ansible.playbook = "playbooks/ais_enable_multiqueue.yml"
          ansible.verbose = true
        end

        config.vm.provision "step2", type: "ansible" do |ansible|
          ansible.host_vars = host_vars
          ansible.groups = inventory
          ansible.playbook = "playbooks/ais_host_config_common.yml"
          ansible.verbose = true
        end

        config.vm.provision "step3", type: "ansible" do |ansible|
          ansible.host_vars = host_vars
          ansible.groups = inventory
          ansible.limit = "all"
          ansible.playbook = "kubespray/cluster.yml"
          ansible.verbose = true
          ansible.become = true
        end

        config.vm.provision "step4", type: "ansible" do |ansible|
          ansible.host_vars = host_vars
          ansible.groups = inventory
          ansible.limit = "all"
          ansible.playbook = "playbooks/ais_host_post_kubespray.yml"
          ansible.verbose = true
          ansible.become = true
        end

        config.vm.provision "step5", type: "ansible" do |ansible|
          ansible.host_vars = host_vars
          ansible.groups = inventory
          ansible.limit = "all"
          ansible.playbook = "playbooks/ais_datafs_mkfs.yml"
          ansible.verbose = true
          ansible.become = true
        end

        config.vm.provision "step6", type: "ansible" do |ansible|
          ansible.host_vars = host_vars
          ansible.groups = inventory
          ansible.limit = "all"
          ansible.playbook = "playbooks/ais_deploy_operator.yml"
          ansible.verbose = true
          ansible.become = true
        end
    end
    end
end

