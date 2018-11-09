# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'config/config'

required_plugins = {
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
      vbox.memory = 4096
      # vbox.memory = 8192
      vbox.cpus = 2
      vbox.gui = false
      if NETWORK_SETTINGS[:type] == "hostonly"
        vbox.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      end
    end

    ######################
    #  Operating System  #
    ######################

    case OPERATING_SYSTEM.upcase
    when "WINDOWS"
      case WIN_VERSION.upcase
      when "2012R2"
        # Base box
        vmconfig.vm.box = "psadmin-io/ps-vagabond-win"
        # vmconfig.vm.box_check_update = true
        # vmconfig.vm.box_version = "1.0.5"
      when "2016"
        # Base box
        vmconfig.vm.box = "psadmin-io/ps-vagabond-win-2016"
        # vmconfig.vm.box_check_update = true
        # vmconfig.vm.box_version = "1.0.1"
      end
      # Sync folder to be used for downloading the dpks
      vmconfig.vm.synced_folder "#{DPK_LOCAL_DIR}", "#{DPK_REMOTE_DIR_WIN}"
      # WinRM communication settings
      vmconfig.vm.communicator = "winrm"
      config.winrm.username = "vagrant"
      config.winrm.password = "vagrant"
      config.winrm.timeout = 10000
      # Plugin settings
    when "LINUX"
      # Base box
      # vmconfig.vm.box = "jrbing/ps-vagabond"
      vmconfig.vm.box = "ol7-latest"
      vmconfig.vm.box_url = "https://yum.oracle.com/boxes/oraclelinux/latest/ol7-latest.box"
      # Sync folder to be used for downloading the dpks
      vmconfig.vm.synced_folder "#{DPK_LOCAL_DIR}", "#{DPK_REMOTE_DIR_LNX}"
    else
      raise Vagrant::Errors::VagrantError.new, "Operating System #{OPERATING_SYSTEM} is not supported"
    end

    ###########
    # Storage #
    ###########

    case OPERATING_SYSTEM.upcase
    when "LINUX"
      # add 2nd disk
      # disk  = "./disk2.vmdk"
      line = `vboxmanage list systemproperties`.split(/\n/).grep(/Default machine folder/).first
      vb_machine_folder = line.split(':')[1].strip()
      disk = File.join(vb_machine_folder, "#{DPK_VERSION}", 'disk2.vmdk')

      config.vm.provider "virtualbox" do | p |
        unless File.exist?(disk)
          p.customize ['createhd', '--filename', disk, '--size', 100 * 1024]
        end
        p.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk]
      end
   
      # extend default volume group to increase drive space
      $extend = <<-SCRIPT
      echo ####### Extending volume group ########
      echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
      pvcreate /dev/sdb1
      vgextend vg_main /dev/sdb1
      lvextend -l +100%FREE /dev/mapper/vg_main-lv_root
      xfs_growfs /dev/mapper/vg_main-lv_root
      SCRIPT
      vmconfig.vm.provision "shell", run: "once", inline: $extend
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
        vmconfig.vm.network "public_network"
      when "LINUX"
        vmconfig.vm.network "public_network", ip: "#{NETWORK_SETTINGS[:ip_address]}"
        # The following is necessary when using the bridged network adapter
        # with Linux in order to make the machine available from other networks.
        # config.vm.provision "shell",
        #   run: "always",
        #   inline: "route add default gw #{NETWORK_SETTINGS[:gateway]}"
        # config.vm.provision "shell",
        #   run: "aways",
        #   inline: "eval `route -n | awk '{ if ($8 ==\"eth0\" && $2 != \"0.0.0.0\") print \"route del default gw \" $2; }'`"config.vm.provision "shell",
        config.vm.provision "shell",  
          run: "always",
          inline: "nmcli connection modify \"enp0s3\" ipv4.never-default yes && nmcli connection modify \"System enp0s8\" ipv4.gateway #{NETWORK_SETTINGS[:gateway]} && nmcli networking off && nmcli networking on"
      else
        raise Vagrant::Errors::VagrantError.new, "Operating System #{OPERATING_SYSTEM} is not supported"
      end
    end

    # HyperV
    vmconfig.vm.provider "hyperv" do |hyperv|
      hyperv.vmname = "#{DPK_VERSION}"
      hyperv.memory = 8192
      hyperv.cpus = 2
      hyperv.vm_integration_services = {
        guest_service_interface: true,
        heartbeat: true,
        key_value_pair_exchange: true,
        shutdown: true,
        time_synchronization: true,
        vss: true
      }
    end

    ##################
    #  Provisioning  #
    ##################

    if OPERATING_SYSTEM.upcase == "WINDOWS"

      vmconfig.vm.provision "banner", type: "shell" do |boot|
        boot.path = "scripts/banner.ps1"
        boot.upload_path = "C:/temp/banner.ps1"
      end

      vmconfig.vm.provision "download", type: "shell" do |boot|
        boot.path = "scripts/provision-download.ps1"
        boot.upload_path = "C:/temp/provision-download.ps1"
        boot.env = {
          "MOS_USERNAME"  => "#{MOS_USERNAME}",
          "MOS_PASSWORD"  => "#{MOS_PASSWORD}",
          "PATCH_ID"      => "#{PATCH_ID}",
          "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PATCH_ID}"
        }
      end

      vmconfig.vm.provision "bootstrap-ps", type: "shell" do |boot|
        boot.path = "scripts/provision-bootstrap-ps.ps1"
        boot.upload_path = "C:/temp/provision-bootstrap-ps.ps1"
        boot.env = {
          "PATCH_ID"      => "#{PATCH_ID}",
          "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PATCH_ID}",
          "PSFT_BASE_DIR" => "#{PSFT_BASE_DIR}",
          "PUPPET_HOME"   => "#{PUPPET_HOME}"
        }
      end

      vmconfig.vm.provision "yaml", type: "shell"  do |yaml|
        yaml.path = "scripts/provision-yaml.ps1"
        yaml.upload_path = "C:/temp/provision-yaml.ps1"
        yaml.env = {
          "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PATCH_ID}",
          "PSFT_BASE_DIR" => "#{PSFT_BASE_DIR}",
          "PUPPET_HOME"   => "#{PUPPET_HOME}"
        }
      end

      vmconfig.vm.provision "dpk-modules", type: "shell" do |modules|
        modules.path = "scripts/provision-dpk-modules.ps1"
        modules.upload_path = "C:/temp/provision-dpk-modules.ps1"
        modules.env = {
          "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PATCH_ID}",
          "PSFT_BASE_DIR" => "#{PSFT_BASE_DIR}",
          "PUPPET_HOME"   => "#{PUPPET_HOME}",
          "DPK_ROLE"      => "#{DPK_ROLE}"
        }
      end

      vmconfig.vm.provision "puppet", type: "shell" do |puppet|
        puppet.path = "scripts/provision-puppet-apply.ps1"
        puppet.upload_path = "C:/temp/provision-puppet-apply.ps1"
        puppet.env = {
          "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PATCH_ID}",
          "PSFT_BASE_DIR" => "#{PSFT_BASE_DIR}",
          "PUPPET_HOME"   => "#{PUPPET_HOME}",
        }

      end

      if APPLY_PT_PATCH.downcase == 'true'
        vmconfig.vm.provision "download-ptp", type: "shell" do |boot|
          boot.path = "scripts/provision-download.ps1"
          boot.upload_path = "C:/temp/provision-download.ps1"
          boot.env = {
            "MOS_USERNAME"  => "#{MOS_USERNAME}",
            "MOS_PASSWORD"  => "#{MOS_PASSWORD}",
            "PATCH_ID"      => "#{PTP_PATCH_ID}",
            "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PTP_PATCH_ID}"
          }
        end

        vmconfig.vm.provision "bootstrap-ptp", type: "shell" do |boot|
          boot.path = "scripts/provision-bootstrap-ptp.ps1"
          boot.upload_path = "C:/temp/provision-bootstrap-ptp.ps1"
          boot.env = {
            "PATCH_ID"      => "#{PTP_PATCH_ID}",
            "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PATCH_ID}",
            "PTP_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PTP_PATCH_ID}",
            "PUPPET_HOME"   => "#{PUPPET_HOME}"
          }
        end
      end

      if CLIENT_TOOLS.downcase == 'true'
        vmconfig.vm.provision "client", type: "shell"  do |client|
          client.path        = "scripts/provision-client.ps1"
          client.upload_path = "C:/temp/provision-client.ps1"
          client.privileged  = "true"
          client.env = {
            "CA_SETUP"       => "#{CA_SETTINGS[:setup]}",
            "CA_PATH"        => "#{CA_SETTINGS[:path]}",
            "CA_TYPE"        => "#{CA_SETTINGS[:type]}",
            "CA_BACKUP"      => "#{CA_SETTINGS[:backup]}",
            "IE_HOMEPAGE"    => "#{IE_HOMEPAGE}",
            "PTF_SETUP"      => "#{PTF_SETUP}"
          }
        end
      end

      if APPLY_PT_PATCH.downcase == 'true'
        vmconfig.vm.provision "dpk-modules-ptp", type: "shell"  do |yaml|
          yaml.path = "scripts/provision-dpk-modules.ps1"
          yaml.upload_path = "C:/temp/provision-dpk-modules.ps1"
          yaml.env = {
            "PUPPET_HOME"   => "#{PUPPET_HOME}",
            "DPK_ROLE"      => "#{DPK_ROLE}"
          }
        end

        vmconfig.vm.provision "apply-ptp", type: "shell" do |boot|
          boot.path = "scripts/provision-apply-ptp.ps1"
          boot.upload_path = "C:/temp/provision-apply-ptp.ps1"
          boot.env = {
            "PATCH_ID"      => "#{PTP_PATCH_ID}",
            "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PATCH_ID}",
            "PTP_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{PTP_PATCH_ID}",
            "PUPPET_HOME"   => "#{PUPPET_HOME}",
            "CA_PATH"       => "#{CA_SETTINGS[:path]}"
          }
        end
      end

      # Uncomment to download the Elasticsearch DPK
      # vmconfig.vm.provision "download-es", type: "shell" do |boot|
      #   boot.path = "scripts/provision-download.ps1"
      #   boot.upload_path = "C:/temp/provision-download.ps1"
      #   boot.env = {
      #     "MOS_USERNAME"  => "#{MOS_USERNAME}",
      #     "MOS_PASSWORD"  => "#{MOS_PASSWORD}",
      #     "PATCH_ID"      => "#{ES_PATCH_ID}",
      #     "DPK_INSTALL"   => "#{DPK_REMOTE_DIR_WIN}/#{ES_PATCH_ID}"
      #   }
      # end

    elsif OPERATING_SYSTEM.upcase == "LINUX"
      vmconfig.vm.provision "shell" do |script|
        script.path = "scripts/provision.sh"
        script.upload_path = "/tmp/provision.sh"
        script.env = {
          "MOS_USERNAME" => "#{MOS_USERNAME}",
          "MOS_PASSWORD" => "#{MOS_PASSWORD}",
          "PATCH_ID"     => "#{PATCH_ID}",
          "DPK_INSTALL"  => "#{DPK_REMOTE_DIR_LNX}/#{PATCH_ID}",
          "PSFT_CFG_DIR" => "#{PSFT_CFG_DIR}"
        }
      end
    else
      raise Vagrant::Errors::VagrantError.new, "Operating System #{OPERATING_SYSTEM} is not supported"
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
