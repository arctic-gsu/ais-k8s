vm1 = 'node-08'
vm2 = 'node-09'
vm3 = 'node-10'
vm4 = 'node-11'

servers = [
  { svrName: "#{vm1}", template: 'peru/ubuntu-18.04-server-amd64', ip: '192.168.64.10',  memory: '4096', vcpus: '1' },
  { svrName: "#{vm2}", template: 'peru/ubuntu-18.04-server-amd64', ip: '192.168.64.11',  memory: '4096', vcpus: '1', disks: [['sda','50G'],['sdb','50G'],['sdc','50G'],['sdd','50G'],['sde','50G'],['sdf','50G']] },
  { svrName: "#{vm3}", template: 'peru/ubuntu-18.04-server-amd64', ip: '192.168.64.12',  memory: '4096', vcpus: '1', disks: [['sda','50G'],['sdb','50G'],['sdc','50G'],['sdd','50G'],['sde','50G'],['sdf','50G']] }
]

inventory = {
      "cpu-node-population" => ["#{vm1}","#{vm2}","#{vm3}"],
      "cpu-worker-node" => ["#{vm2}","#{vm3}"],
      "kube-master" => ["#{vm1}"],
      "etcd" => ["#{vm1}"],
      "first_three" => ["#{vm1}","#{vm2}","#{vm3}"],
      "last_three" => ["#{vm1}","#{vm2}","#{vm3}"],
      "kube-node:children" => ["cpu-worker-node"],
      "k8s-cluster:children" => ["kube-master","kube-node"],
      "kube_control_plane" => ["#{vm1}","#{vm2}","#{vm3}"],
      "allactive:children" => ["k8s-cluster","etcd"],
      "calico-rr" => [],
      "ais" => ["#{vm2}","#{vm3}"],
      "es" => ["#{vm1}"]
}

host_vars = {
      "#{vm1}" => { "key" => "value" },
      "#{vm2}" => { "key" => "value" },
      "#{vm3}" => { "key" => "value" }
}

Vagrant.configure('2') do |config|

  servers.each do |server|

    host_name = server[:svrName]

    config.vm.define host_name do |node|

        node.vm.hostname = host_name
        node.vm.box = server[:template]
        node.vm.box_version = "20210701.01"
        #node.vm.network 'private_network', ip: server[:ip]
        #node.vm.network "public_network", :dev => "br0", :mode => 'bridge', :type => "bridge"

        node.vm.provider :libvirt do |v|
            v.memory = server[:memory]
            v.cpus = server[:vcpus]

            if server.key?(:disks)
                server[:disks].each do |disk|
                    v.storage :file, :size => disk[1]
                end
            end

        end

        config.vm.provision "ansible" do |ansible|
          ansible.host_vars = host_vars
          ansible.groups = inventory
          ansible.limit = "all"
          ansible.playbook = "upgrade-ubuntu.yml"
          ansible.verbose = true
          ansible.become = true
        end	

    end
    end
end

