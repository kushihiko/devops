VAGRANTFILE_API_VERSION = "2"

box = "bento/ubuntu-22.04"
vm_memory = 2048
vm_cpus = 2

config_file = "ansible/ansible.cfg"
playbook = "ansible/playbook.yml"

master = {
    :hostname => "master",
    :box => box,
    :ram => vm_memory,
    :cpu => vm_cpus
}

worker = {
    :hostname => "worker",
    :box => box,
    :ram => vm_memory,
    :cpu => vm_cpus
}


def configure_machine_node(config, machine, node)
    node.vm.box = machine[:box]
    node.vm.hostname = machine[:hostname]
    node.vm.provider "vmware-desctop" do |vmware|
        vmware.memory = machine[:ram]
        vmware.cpus = machine[:cpu]
    end
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.define worker[:hostname] do |node|
        configure_machine_node(config, worker, node)
    end

    config.vm.define master[:hostname] do |node|
        configure_machine_node(config, master, node)

        node.vm.network "forwarded_port", guest: 80, host: 80
        node.vm.network "forwarded_port", guest: 443, host: 443
        node.vm.network "forwarded_port", guest: 3000, host: 3000
        node.vm.network "forwarded_port", guest: 2000, host: 2000
        
        node.vm.provision "ansible" do |ansible|
            ansible.compatibility_mode = "2.0"
            ansible.config_file = config_file
            ansible.playbook = playbook
            ansible.limit = "all"
            ansible.groups = {
                "master" => [master[:hostname]],
                "worker" => [worker[:hostname]],
            }
        end
    end
end