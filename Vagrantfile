# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Recommended OS: Ubuntu Server 24.04 LTS
  config.vm.box = "ubuntu/jammy64"

  # VM definitions: name, IP address, RAM, CPU
  machines = [
    { name: "lb-01",  ip: "192.168.56.10", ram: 512,  cpu: 1 },
    { name: "lb-02",  ip: "192.168.56.11", ram: 512,  cpu: 1 },
    { name: "web-01", ip: "192.168.56.20", ram: 1024, cpu: 1 },
    { name: "web-02", ip: "192.168.56.21", ram: 1024, cpu: 1 },
  ]

  machines.each do |machine|
    config.vm.define machine[:name] do |node|
      node.vm.hostname = machine[:name]

      # Assign private static IP
      node.vm.network "private_network", ip: machine[:ip]

      # Provider settings for VirtualBox on Windows
      node.vm.provider "virtualbox" do |vb|
        vb.name = machine[:name]
        vb.memory = machine[:ram]
        vb.cpus = machine[:cpu]
        # Promiscuous mode allows Keepalived VRRP packets across the host-only adapter
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      end

      # Provision base DNS resolver to ensure internet connectivity
      node.vm.provision "shell", inline: <<-SHELL
        sed -i 's/#DNS=/DNS=8.8.8.8 1.1.1.1/' /etc/systemd/resolved.conf || true
        systemctl restart systemd-resolved || true
      SHELL
    end
  end
end