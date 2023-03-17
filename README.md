ps-vagabond
===========

Vagabond is a project to help more easily create and manage PeopleSoft PUM environments on your local machine by using [Vagrant](https://vagrantup.com).  Once downloaded and configured, running `vagrant up` from within your Vagabond instance will...

* Download, configure, and start a base OEL or Windows (evaluation) Virtual Machine for use with the PUM
* Download the PUM DPK files from Oracle Support
* Unpack the DPK setup zip file and run the psft-dpk-setup script on the VM
* Copy the psft_customizations.yaml file from the local directory to the VM
* Apply the DPK Puppet manifests to build out the environment and start the PUM environment

------------------------------------------------------------------------------

Prerequisites
-------------

You'll need the following hardware and software in order to use Vagabond.

- Hardware
    - At least 10GB of RAM for the VM (not including host machine memory requirements)
    - Minimum of 2 CPU cores
- Software
    - [VirtualBox](https://www.virtualbox.org)
    - [Vagrant](https://vagrantup.com)
- Credentials
    - [My Oracle Support](https://support.oracle.com) account and access to download PeopleSoft PUM DPK's

__NOTE:__ If you haven't used [Vagrant](https://vagrantup.com) before, it's *highly* recommended that you walk through the [vagrant project setup guide](https://www.vagrantup.com/docs/getting-started/project_setup.html) before getting started.

__Windows Users:__  Setting up ssh client integration with Vagrant can be tricky.  You might want to check out [Cmder](http://cmder.net/) as an alternative to the delivered Windows command shell. PowerShell will *probably* work, but has not been fully tested.


Setup
-----

### Download ###

To get started, simply download the [zipfile](https://github.com/psadmin-io/ps-vagabond/archive/master.zip) and extract the contents to whichever directory you choose.  If you need to manage more than one PeopleSoft Application, it is recommended that you create separate Vagabond installations for each application. For example:

```
E:\vagabond
   ├─ fscm92
   └─ hcm92
```

Depending on your platform, you can use one of the examples below or do it manually.

#### Git Example ####

If you have git installed, this is the preferred method as it will allow future updates to be performed much more easily.

```bat
cd E:\pum
git clone https://github.com/psadmin-io/ps-vagabond.git ps-vagabond-hcm
cd ps-vagabond-hcm
```

#### PowerShell Example ####

```powershell
$baseDirectory = "E:\pum" # Change this to the base directory you want to use
Set-Location -Path $baseDirectory
(New-Object System.Net.WebClient).DownloadFile("https://github.com/psadmin-io/ps-vagabond/archive/master.zip", "$basedirectory\ps-vagabond.zip")
(New-Object -com shell.application).namespace($baseDirectory).CopyHere((new-object -com shell.application).namespace("$basedirectory\ps-vagabond.zip").Items(),16)
Rename-Item "$baseDirectory\ps-vagabond-master" "ps-vagabond-hcm" # Change this to whichever application you're going to be using
Remove-Item "$baseDirectory\ps-vagabond.zip"
Set-Location -Path "$baseDirectory\ps-vagabond-hcm"
```

#### WGET Example ####

```bash
cd ~/pum # Change this to the base directory you want to use
wget https://github.com/psadmin-io/ps-vagabond/archive/master.zip --output-document="ps-vagabond.zip"
unzip ps-vagabond.zip
mv ps-vagabond-master ps-vagabond-hcm
rm ps-vagabond.zip
```

### Configuration ###

Once you've downloaded Vagabond you should have a directory containing the following files:

```
ps-vagabond
├── LICENSE.md
├── README.md
├── Vagrantfile
├── config
│   ├── PSCFG.CFG.example
│   ├── client.reg.example
│   ├── config.rb.example
│   ├── psft_customizations.yaml.example
├── dpks
├── keys
└── scripts
    ├── banner.ps1
    ├── loadcache.ps
    ├── provision-*.ps1
    ├── provision.sh
    ├── rubyGems.pem
```

The first thing you'll want to do is copy both the `config/config.rb.example` and `config/psft_customizations.yaml.example` files to `config/config.rb` and `config/psft_customizations.yaml`. The `PSCFG.CFG.example` and `client.reg.example` file is used if you want to apply a PeopleTools Patch when provisioning the PeopleSoft Image.

#### config.rb (required) ####
 
The `config.rb` file is what Vagabond will use to determine how to go about setting up the base configuration of your virtual machine.  Although some of the settings are optional, you'll need to provide your MOS credentials and the Patch ID for the PUM DPK you wish to use.  The Patch ID for each application can be found on the [PUM Homepage](https://support.oracle.com/epmos/faces/DocumentDisplay?id=1641843.2).  When copying the Patch ID, be sure to select the "Native OS" one.

```ruby
##############
#  Settings  #
##############

# REQUIRED >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# ORACLE SUPPORT CREDENTIALS
# MOS username and password must be specified in order to
# download the DPK files from Oracle.

MOS_USERNAME='USER@EXAMPLE.COM'
MOS_PASSWORD='MYMOSPASSWORD'

# PATCH ID
# Specify the patch id for the PUM you wish to use
PATCH_ID='23711856'
```
Usage
-----

Once configured, you simply have to change to the Vagabond instance directory and run `vagrant up`. Vagrant will then download the box image, start the VM, and begin the provisioning process.

```text
C:\pum_images\hcm92>vagrant up

Bringing machine 'ps-vagabond' up with 'virtualbox' provider...
==> ps-vagabond: Importing base box 'generic/oracle8'...
==> ps-vagabond: Matching MAC address for NAT networking...
==> ps-vagabond: Setting the name of the VM: HR045
==> ps-vagabond: Clearing any previously set network interfaces...
==> ps-vagabond: Preparing network interfaces based on configuration...
    ps-vagabond: Adapter 1: nat
    ps-vagabond: Adapter 2: hostonly
==> ps-vagabond: Forwarding ports...
    ps-vagabond: 8000 (guest) => 8000 (host) (adapter 1)
    ps-vagabond: 1521 (guest) => 1521 (host) (adapter 1)
    ps-vagabond: 1522 (guest) => 1522 (host) (adapter 1)
    ps-vagabond: 33389 (guest) => 3389 (host) (adapter 1)
    ps-vagabond: 9200 (guest) => 9200 (host) (adapter 1)
    ps-vagabond: 5601 (guest) => 5601 (host) (adapter 1)
    ps-vagabond: 22 (guest) => 2222 (host) (adapter 1)
==> ps-vagabond: Running 'pre-boot' VM customizations...
==> ps-vagabond: Booting VM...
==> ps-vagabond: Waiting for machine to boot. This may take a few minutes...
    ps-vagabond: SSH address: 127.0.0.1:2222
    ps-vagabond: SSH username: vagrant
    ps-vagabond: SSH auth method: private key
    ps-vagabond: Key inserted! Disconnecting and reconnecting using new SSH key...
==> ps-vagabond: Machine booted and ready!
==> ps-vagabond: Checking for guest additions in VM...
    ps-vagabond: The guest additions on this VM do not match the installed version of
    ps-vagabond: VirtualBox! In most cases this is fine, but in rare cases it can
    ps-vagabond: prevent things such as shared folders from working properly. If you see
    ps-vagabond: shared folder errors, please make sure the guest additions within the
    ps-vagabond: virtual machine match the version of VirtualBox you have installed on
    ps-vagabond: your host and reload your VM.
    ps-vagabond:
    ps-vagabond: Guest Additions Version: 6.1.30
    ps-vagabond: VirtualBox Version: 7.0
==> ps-vagabond: Setting hostname...
==> ps-vagabond: Configuring and enabling network interfaces...
==> ps-vagabond: Mounting shared folders...
    ps-vagabond: /vagrant => /Users/dan/repos/ps-vagabond
    ps-vagabond: /media/sf_HR045 => /Users/dan/repos/ps-vagabond/dpks/download
==> ps-vagabond: Detected mount owner ID within mount options. (uid: 1000 guestpath: /media/sf_HR045)
==> ps-vagabond: Detected mount group ID within mount options. (gid: 1000 guestpath: /media/sf_HR045)
==> ps-vagabond: Running provisioner: domain_resolver (shell)...
    ps-vagabond: Running: inline script
    ps-vagabond: search psadmin.local
==> ps-vagabond: Running provisioner: hostname_resolver (shell)...
    ps-vagabond: Running: inline script
    ps-vagabond: add '192.168.56.26 psvagabond.psadmin.local' to your hosts file
==> ps-vagabond: Running provisioner: storage (shell)...
    ps-vagabond: Running: inline script
    ps-vagabond: Extending Volume Group
    ps-vagabond: PeopleSoft Mount: /dev/mapper/ol_oracle8-ps   xfs       150G  1.1G  149G   1% /opt/oracle
==> ps-vagabond: Running provisioner: bootstrap-lnx (shell)...
    ps-vagabond:
    ps-vagabond:
    ps-vagabond:                                       dP                               dP
    ps-vagabond:                                       88                               88
    ps-vagabond:   dP   .dP .d8888b. .d8888b. .d8888b. 88d888b. .d8888b. 88d888b. .d888b88
    ps-vagabond:   88   d8' 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88
    ps-vagabond:   88 .88'  88.  .88 88.  .88 88.  .88 88.  .88 88.  .88 88    88 88.  .88
    ps-vagabond:   8888P'   `88888P8 `8888P88 `88888P8 88Y8888' `88888P' dP    dP `88888P8
    ps-vagabond:                          .88
    ps-vagabond:                      d8888P
    ps-vagabond:
    ps-vagabond:
    ps-vagabond:  ☆  INFO: Updating installed packages
    ps-vagabond:  ☆  INFO: Installing additional packages
    ps-vagabond:  ☆  INFO: Patch files already downloaded
    ps-vagabond:  ☆  INFO: Setup scripts already unpacked
    ps-vagabond:  ☆  INFO: Executing Pre setup script
    ps-vagabond:  ☆  INFO: Executing DPK setup script
    ps-vagabond:  ☆  INFO: Install psadmin_plus
    ps-vagabond:  ☆  INFO: Open Firewall Ports
    ps-vagabond:
    ps-vagabond:  TASK                         DURATION
    ps-vagabond: ========================================
    ps-vagabond:  install_psadmin_plus         00:00:01
    ps-vagabond:  execute_pre_setup            00:00:00
    ps-vagabond:  install_additional_packages  00:01:16
    ps-vagabond:  update_packages              00:02:44
    ps-vagabond:  execute_psft_dpk_setup       00:51:33
    ps-vagabond:  generate_response_file       00:00:00
    ps-vagabond: ========================================
    ps-vagabond:  TOTAL TIME:                  00:55:34
    ps-vagabond:
    ps-vagabond:  ☆  INFO: Cleaning up temporary files
==> ps-vagabond: Running provisioner: cache-lnx (shell)...
    ps-vagabond:  ☆  INFO: Downloading Manifests
    ps-vagabond:  ☆  INFO: Fix DPK App Engine Bug
    ps-vagabond:  ☆  INFO: Pre-load Application Cache
    ps-vagabond:
    ps-vagabond:  TASK                         DURATION
    ps-vagabond: ========================================
    ps-vagabond:  fix_dpk_bug                  00:00:07
    ps-vagabond:  load_cache                   00:18:16
    ps-vagabond:  download_manifests           00:00:01
    ps-vagabond: ========================================
    ps-vagabond:  TOTAL TIME:                  00:18:24

C:\pum_images\hcm92>
```

Since Vagabond is just a set of configuration files and provisioning scripts for Vagrant, all of the delivered Vagrant commands can be used.  The following table lists some of the basic commands.


| Task                                         | Command                                          |
| -------------                                | -------------                                    |
| Start the VM                                 | `vagrant up`                                     |
| Stop the VM                                  | `vagrant halt`                                   |
| Delete the VM                                | `vagrant destroy`                                |
| Connect to the VM                            | `vagrant ssh`                                    |
| Take a VM Snapshot                           | `vagrant snapshot save <name>`                   |
| Connect to the VM (via RDP)                  | `vagrant rdp`                                    |
| Pre-load app cache                           | `vagrant provision --provision-with=cache-lnx`   |
| Copy your `psft_customizations.yaml` file    | `vagrant provision --provision-with=yaml`        |
| Copy custom DPK modules                      | `vagrant provision --provision-with=dpk-modules` |

To view the DPK script output while the instance is building, you can use the `vagrant ssh` command to log into the instance. 

```bash
vagrant ssh
tail -f /media/sf_*/*/setup/psft_dpk_setup.log
```

### Manually Download DPK Files

If the host running Vagabond does not have internet access, you can download the DPK files manually for Vagabond. Use a tool like [`getMOSPatch`](http://psadmin.io/2016/08/23/simplify-peoplesoft-image-downloads/) to download the files on your local machine. 

Let's assume that you have Vagabond installed to `c:\pum\hcm92`. Copy the files to the folder `c:\pum\hcm92\dpks\download\[PATCH_ID]` on the machine running Vagabond.

Next, copy the text below and save it as `vagabond.json` in the same directory: 

```json
{
    "download_patch_files":  "true",
    "unpack_setup_scripts":  "false"
}
```

The `vagabond.json` file tracks the download and unzipping status of the DPK files. Setting `"download_patch_files": "true"` will tell Vagabond to skip the download for that patch. Now you can run `vagrant up` and Vagabond will build the PeopleSoft Image.


### Options for Windows Native OS DPK

[There are some optional features to use with the Windows OS Native DPK.](WINDOWS-DPK.md)