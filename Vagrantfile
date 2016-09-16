# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'config/config'

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define 'ps-vagabond' do |vmconfig|

    # Increase the timeout limit for booting the VM
    vmconfig.vm.boot_timeout = 600

    # Increase the timeout limit for halting the VM
    vmconfig.vm.graceful_halt_timeout = 600

    # Define the box we'll be using and automatically download the latest version
    vmconfig.vm.box = "jrbing/ps-vagabond"
    vmconfig.vm.box_check_update = true

    # Sync folder to be used for downloading the dpks
    vmconfig.vm.synced_folder "#{DPK_LOCAL_DIR}", "#{DPK_REMOTE_DIR}"

    #############
    #  Network  #
    #############

    vmconfig.vm.hostname = "#{FQDN}"

    # Host-only network adapter
    if NETWORK_SETTINGS[:type] == "hostonly"
      config.vm.network "private_network", type: "dhcp"
      config.vm.network "forwarded_port",
        guest: NETWORK_SETTINGS[:guest_http_port],
        host: NETWORK_SETTINGS[:host_http_port]
      config.vm.network "forwarded_port",
        guest: NETWORK_SETTINGS[:guest_listener_port],
        host: NETWORK_SETTINGS[:host_listener_port]
    end

    # Bridged network adapter
    if NETWORK_SETTINGS[:type] == "bridged"
      vmconfig.vm.network "public_network", ip: "#{NETWORK_SETTINGS[:ip_address]}"
      # The following is necessary when using the bridged network adapter
      # in order to make the machine available from other networks.
      config.vm.provision "shell",
        run: "always",
        inline: "route add default gw #{NETWORK_SETTINGS[:gateway]}"
      config.vm.provision "shell",
        run: "always",
        inline: "eval `route -n | awk '{ if ($8 ==\"eth0\" && $2 != \"0.0.0.0\") print \"route del default gw \" $2; }'`"
    end

    ################################
    #  Provider-specific Settings  #
    ################################

    # VirtualBox
    vmconfig.vm.provider "virtualbox" do |vbox,override|
      vbox.name = "#{DPK_VERSION}"
      vbox.memory = 8192
      vbox.cpus = 2
      #vbox.linked_clone = true if Vagrant::VERSION =~ /^1.8/
    end

    ##################
    #  Provisioning  #
    ##################

    vmconfig.vm.provision "shell" do |script|
      script.path = "scripts/provision.sh"
      script.upload_path = "/tmp/provision.sh"
      script.env = {
        "MOS_USERNAME" => "#{MOS_USERNAME}",
        "MOS_PASSWORD" => "#{MOS_PASSWORD}",
        "PATCH_ID"     => "#{PATCH_ID}",
        "DPK_INSTALL"  => "#{DPK_REMOTE_DIR}/#{PATCH_ID}"
      }
    end

    ##################
    #  Notification  #
    ##################
    # Vagrant-Pushover Notification
    # https://github.com/tcnksm/vagrant-pushover
    # install: vagrant plugin install vagrant-pushover
    # initialize: vagrant pushover-init
    # configure: $EDITOR .vagrant/pushover.rb
    if Vagrant.has_plugin?("vagrant-pushover")
      config.pushover.read_key
    end

    #################
    #  Workarounds  #
    #################
    # Workaround for issue with Vagrant 1.8.5
    # https://github.com/mitchellh/vagrant/issues/7610
    vmconfig.ssh.insert_key = false

  end


end
