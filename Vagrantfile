# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'config/config'

required_plugins = {
  'vagrant-vbguest' => '~>0.13.0'
}

needs_restart = false
required_plugins.each do |name, version|
  unless Vagrant.has_plugin? name, version
    system "vagrant plugin install #{name} --plugin-version=\"#{version}\""
    needs_restart = true
  end
end

if needs_restart
  exec "vagrant #{ARGV.join' '}"
end

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define 'ps-vagabond' do |vmconfig|

    # Increase the timeout limit for booting the VM
    vmconfig.vm.boot_timeout = 600

    # Increase the timeout limit for halting the VM
    vmconfig.vm.graceful_halt_timeout = 600

    # Automatically download the latest version of whatever box we're using
    vmconfig.vm.box_check_update = true

    ##############
    #  Provider  #
    ##############

    # VirtualBox
    vmconfig.vm.provider "virtualbox" do |vbox,override|
      vbox.name = "#{DPK_VERSION}"
      # vbox.memory = 4096
      vbox.memory = 8192
      vbox.cpus = 2
      vbox.gui = false
    end

    ######################
    #  Operating System  #
    ######################

    case OPERATING_SYSTEM.upcase
    when "WINDOWS"
      # Base box
      vmconfig.vm.box = "psadmin-io/ps-vagabond-win"
      # vmconfig.vm.box_check_update = true
      vmconfig.vm.box_version = "1.0.4"
      # Sync folder to be used for downloading the dpks
      vmconfig.vm.synced_folder "#{DPK_LOCAL_DIR}", "#{DPK_REMOTE_DIR_WIN}"
      # WinRM communication settings
      vmconfig.vm.communicator = "winrm"
      config.winrm.username = "vagrant"
      config.winrm.password = "vagrant"
      config.winrm.timeout = 10000
      # Plugin settings
      vmconfig.vbguest.auto_update = false
    when "LINUX"
      # Base box
      vmconfig.vm.box = "jrbing/ps-vagabond"
      # Sync folder to be used for downloading the dpks
      vmconfig.vm.synced_folder "#{DPK_LOCAL_DIR}", "#{DPK_REMOTE_DIR_LNX}"
    else
      raise Vagrant::Errors::VagrantError.new, "Operating System #{OPERATING_SYSTEM} is not supported"
    end

    #############
    #  Network  #
    #############

    vmconfig.vm.hostname = "#{FQDN}".downcase


    # Host-only network adapter
    if NETWORK_SETTINGS[:type] == "hostonly"
      config.vm.network "private_network", type: "dhcp"
      config.vm.network "forwarded_port",
        guest: NETWORK_SETTINGS[:guest_http_port],
        host: NETWORK_SETTINGS[:host_http_port]
      config.vm.network "forwarded_port",
        guest: NETWORK_SETTINGS[:guest_listener_port],
        host: NETWORK_SETTINGS[:host_listener_port]
      config.vm.network "forwarded_port",
        guest: NETWORK_SETTINGS[:guest_rdp_port],
        host: NETWORK_SETTINGS[:host_rdp_port]
    end

    # Bridged network adapter
    if NETWORK_SETTINGS[:type] == "bridged"
      case OPERATING_SYSTEM.upcase
      when "WINDOWS"
        vmconfig.vm.network "public_network", bridge: "en0: Ethernet"
      when "LINUX"
        vmconfig.vm.network "public_network", ip: "#{NETWORK_SETTINGS[:ip_address]}", bridge: "en0: Ethernet"
        # The following is necessary when using the bridged network adapter
        # with Linux in order to make the machine available from other networks.
        config.vm.provision "shell",
          run: "always",
          inline: "route add default gw #{NETWORK_SETTINGS[:gateway]}"
        config.vm.provision "shell",
          run: "always",
          inline: "eval `route -n | awk '{ if ($8 ==\"eth0\" && $2 != \"0.0.0.0\") print \"route del default gw \" $2; }'`"
      else
        raise Vagrant::Errors::VagrantError.new, "Operating System #{OPERATING_SYSTEM} is not supported"
      end
    end

    ##################
    #  Provisioning  #
    ##################

    if OPERATING_SYSTEM.upcase == "WINDOWS"
      vmconfig.vm.provision "boot", type: "shell" do |boot|
        boot.path = "scripts/provision-boot.ps1"
        boot.upload_path = "C:/temp/provision-boot.ps1"
        boot.env = {
          "MOS_USERNAME"  => "#{MOS_USERNAME}",
          "MOS_PASSWORD"  => "#{MOS_PASSWORD}",
          "PATCH_ID"      => "#{PATCH_ID}",
          "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PATCH_ID}"
        }
      end

      vmconfig.vm.provision "puppet", type: "shell"  do |puppet|
        puppet.path = "scripts/provision-puppet.ps1"
        puppet.upload_path = "C:/temp/provision-puppet.ps1"
        puppet.env = {
          "PUPPET_HOME"   => "#{PUPPET_HOME}"
        }
      end

      vmconfig.vm.provision "client", type: "shell"  do |client|
        client.path        = "scripts/provision-client.ps1"
        client.upload_path = "C:/temp/provision-client.ps1"
        client.privileged  = "true"
        client.env = {
          "CA_SETUP"       => "#{CA_SETTINGS[:setup]}",
          "CA_PATH"        => "#{CA_SETTINGS[:path]}",
          "CA_TYPE"        => "#{CA_SETTINGS[:type]}",
          "CA_BACKUP"      => "#{CA_SETTINGS[:backup]}",
          "PTF_SETUP"      => "#{PTF_SETUP}"
        }
      end
    elsif OPERATING_SYSTEM == "LINUX"
      vmconfig.vm.provision "shell" do |script|
        script.path = "scripts/provision.sh"
        script.upload_path = "/tmp/provision.sh"
        script.env = {
          "MOS_USERNAME" => "#{MOS_USERNAME}",
          "MOS_PASSWORD" => "#{MOS_PASSWORD}",
          "PATCH_ID"     => "#{PATCH_ID}",
          "DPK_INSTALL"  => "#{DPK_REMOTE_DIR_LNX}/#{PATCH_ID}"
        }
      end
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
    vmconfig.ssh.insert_key = false if Vagrant::VERSION == '1.8.5'

  end


end
