[![Stories in Ready](https://badge.waffle.io/jrbing/ps-vagabond.png?label=ready&title=Ready)](https://waffle.io/jrbing/ps-vagabond)
ps-vagabond
===========

__NOTE__:  This project is still in beta and currently incomplete.

Vagabond is a project to help more easily create and manage PeopleSoft PUM environments on your local machine by using [Vagrant](https://vagrantup.com).  Once downloaded and configured, running `vagrant up` from within your Vagabond instance will...

* Download, configure, and start a base OEL Virtual Machine for use with the PUM
* Download the PUM DPK files from Oracle Support
* Unpack the DPK setup zip file and run the psft-dpk-setup script on the VM
* Copy the psft_customizations.yaml file from the local directory to the VM
* Apply the DPK Puppet manifests to build out the environment and start the PUM environment


------------------------------------------------------------------------------

Prerequisites
-------------

You'll need the following hardware and software in order to use Vagabond.

- Hardware
    - At least 8GB of RAM for the VM (not including host machine memory requirements)
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

To get started, simply download the [zipfile](https://github.com/jrbing/ps-vagabond/archive/master.zip) and extract the contents to whichever directory you choose.  If you need to manage more than one PeopleSoft Application, it is recommended that you create separate Vagabond installations for each application. For example:

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
git clone https://github.com/jrbing/ps-vagabond.git ps-vagabond-hcm
cd ps-vagabond
```

#### PowerShell Example ####

```powershell
$baseDirectory = "E:\pum" # Change this to the base directory you want to use
Set-Location -Path $baseDirectory
(New-Object System.Net.WebClient).DownloadFile("https://github.com/jrbing/ps-vagabond/archive/master.zip", "$basedirectory\ps-vagabond.zip")
(New-Object -com shell.application).namespace($baseDirectory).CopyHere((new-object -com shell.application).namespace("$basedirectory\ps-vagabond.zip").Items(),16)
Rename-Item "$baseDirectory\ps-vagabond-master" "ps-vagabond-hcm" # Change this to whichever application you're going to be using
Remove-Item "$baseDirectory\ps-vagabond.zip"
Set-Location -Path "$baseDirectory\ps-vagabond-hcm"
```

#### WGET Example ####

```bash
cd ~/pum # Change this to the base directory you want to use
wget https://github.com/jrbing/ps-vagabond/archive/master.zip --output-document="ps-vagabond.zip"
unzip ps-vagabond.zip
mv ps-vagabond-master ps-vagabond-hcm
rm ps-vagabond.zip
```

### Configuration ###

Once you've downloaded Vagabond you should have a directory containing the following files:

```
ps-vagabond
 ├── config
 │   ├── config.rb.example
 │   └── psft_customizations.yaml.example
 ├── dpks
 ├── scripts
 │   └── provision.sh
 ├── README.md
 └── Vagrantfile
```

The first thing you'll want to do is copy both the `config/config.rb.example` and `config/psft_customizations.yaml.example` files to `config/config.rb` and `config/psft_customizations.yaml`.

#### config.rb (required) ####
 
The `config.rb` file is what Vagabond will use to determine how to go about setting up the base configuration of your virtual machine.  Although some of the settings are optional, you'll need to provide your MOS credentials and the Patch ID for the PUM DPK you wish to use.  The Patch ID for each application can be found on the [pum homepage](https://support.oracle.com/epmos/faces/DocumentDisplay?id=1641843.2).  When copying the Patch ID, be sure to select the "Native OS" one.

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
 
#### psft_customizations.yaml (optional) ####

Additionally, if you wish to change the defaults that are used by the DPK you can use the psft_customizations.yaml file.

Usage
-----

Once configured, you simply have to change to the Vagabond instance directory and run `vagrant up`. Vagrant will then download the box image, start the VM, and begin the provisioning process. 

```text
C:\pum_images\hcm92>vagrant up
Bringing machine 'ps-vagabond' up with 'virtualbox' provider...
==> ps-vagabond: Cloning VM...
==> ps-vagabond: Matching MAC address for NAT networking...
==> ps-vagabond: Checking if box 'jrbing/ps-vagabond' is up to date...
==> ps-vagabond: Setting the name of the VM: HCM92
==> ps-vagabond: Clearing any previously set network interfaces...
==> ps-vagabond: Preparing network interfaces based on configuration...
    ps-vagabond: Adapter 1: nat
    ps-vagabond: Adapter 2: bridged
==> ps-vagabond: Forwarding ports...
    ps-vagabond: 22 (guest) => 2222 (host) (adapter 1)
==> ps-vagabond: Running 'pre-boot' VM customizations...
==> ps-vagabond: Booting VM...
==> ps-vagabond: Waiting for machine to boot. This may take a few minutes...
    ps-vagabond: SSH address: 127.0.0.1:2222
    ps-vagabond: SSH username: vagrant
    ps-vagabond: SSH auth method: private key
==> ps-vagabond: Machine booted and ready!
==> ps-vagabond: Checking for guest additions in VM...
==> ps-vagabond: Setting hostname...
==> ps-vagabond: Configuring and enabling network interfaces...
==> ps-vagabond: Mounting shared folders...
    ps-vagabond: /vagrant => C:/pum_images/hcm92
    ps-vagabond: /media/sf_HCM92 => C:/pum_images/hcm92/dpks
==> ps-vagabond: Running provisioner: shell...
    ps-vagabond: Running: inline script
==> ps-vagabond: Running provisioner: shell...
    ps-vagabond: Running: inline script
==> ps-vagabond: Running provisioner: shell...
    ps-vagabond: Running: c:/temp/4/vagrant-shell20160913-44604-1ljfoyc.sh
==> ps-vagabond:
==> ps-vagabond:
==> ps-vagabond:                                       dP                               dP
==> ps-vagabond:                                       88                               88
==> ps-vagabond:   dP   .dP .d8888b. .d8888b. .d8888b. 88d888b. .d8888b. 88d888b. .d888b88
==> ps-vagabond:   88   d8' 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88
==> ps-vagabond:   88 .88'  88.  .88 88.  .88 88.  .88 88.  .88 88.  .88 88    88 88.  .88
==> ps-vagabond:   8888P'   `88888P8 `8888P88 `88888P8 88Y8888' `88888P' dP    dP `88888P8
==> ps-vagabond:                          .88
==> ps-vagabond:                      d8888P
==> ps-vagabond:  ☆  INFO: Updating installed packages
==> ps-vagabond:  ☆  INFO: Installing additional packages
==> ps-vagabond:  ☆  INFO: Downloading patch files
==> ps-vagabond:  ☆  INFO: Unpacking DPK setup scripts
==> ps-vagabond:  ☆  INFO: Setting file execution attribute on psft-dpk-setup.sh
==> ps-vagabond:  ☆  INFO: Executing DPK setup script
==> ps-vagabond:  ☆  INFO: Copying customizations file
==> ps-vagabond:  ☆  INFO: Applying Puppet manifests
==> ps-vagabond:  ☆  INFO: Applying fix for psft-db init script
==> ps-vagabond:
==> ps-vagabond:  TASK                         DURATION
==> ps-vagabond: ========================================
==> ps-vagabond:  install_additional_packages  00:01:13
==> ps-vagabond:  update_packages              00:04:34
==> ps-vagabond:  unpack_setup_scripts         00:00:51
==> ps-vagabond:  execute_puppet_apply         03:26:28
==> ps-vagabond:  execute_psft_dpk_setup       01:28:12
==> ps-vagabond: ========================================
==> ps-vagabond:  TOTAL TIME:                  05:01:18
==> ps-vagabond:
==> ps-vagabond:  ☆  INFO: Cleaning up temporary files

C:\pum_images\hcm92>
```

Since Vagabond is just a set of configuration files and provisioning scripts for Vagrant, all of the delivered Vagrant commands can be used.  The following table lists some of the basic commands.


| Task              | Command           | 
| -------------     | -------------     | 
| Start the VM      | `vagrant up`      | 
| Stop the VM       | `vagrant halt`    | 
| Delete the VM     | `vagrant destroy` | 
| Connect to the VM | `vagrant ssh`     | 


TODO List
---------

- [X] Determine how to make provisioning script idempotent
- [X] Implement ability to download multiple PUM images and switch between them
- [ ] Determine how to store hiera keys for reuse
- [ ] Create additional powershell script for running client installation
- [ ] Remove unnecessary packages from OEL VM to save space
- [ ] Add additional providers (AWS, VMWare, HyperV, etc.)
- [ ] Figure out how to make network provisioning scripts idempotent
- [ ] Add option to change the vagrant user password
- [ ] Redirect debug logs to file in provisioning script
- [X] Disable root ssh login
- [ ] Implement recommendations for Oracle 12c on Redhat 7 (including hugepages)
- [ ] Documentation
    - [ ] Quickstart instructions
    - [ ] Bridged network configuration setup
    - [ ] Notification (pushover) setup
    - [ ] How to manage pum image downloads
    - [ ] Upgrading the base image and linked clones
    - [ ] Troubleshooting
    - [ ] Known Issues

