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
    - A [My Oracle Support](https://support.oracle.com) account and access to download PeopleSoft PUM DPK's

__NOTE:__ If you haven't used [Vagrant](https://vagrantup.com) before, it's *highly* recommended that you walk through the [vagrant project setup guide](https://www.vagrantup.com/docs/getting-started/project_setup.html) before getting started.

__Windows Users:__  Setting up ssh client integration with Vagrant can be tricky.  You might want to check out [Cmder](http://cmder.net/) as an alternative to the delivered Windows command shell. PowerShell will *probably* work, but has not been fully tested.


Setup
-----

### Download ###

To get started, simply download the zipfile and extract the contents to whichever directory you choose.  If you need to manage more than one PeopleSoft Application, it is recommended that you create separate Vagabond installations for each application. For example:

```
C:\vagabond
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
Rename-Item "$baseDirectory\ps-vagabond-master" "ps-vagabond-hcm"
Remove-Item "$basedirectory\ps-vagabond.zip"
Set-Location -Path "$baseDirectory\ps-vagabond"
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

Once you've downloaded Vagabond you should have a directory containing the following files - 

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
 
The `config.rb` file is what Vagabond will use to determine how to go about setting up the base configuration of your virtual machine.  Although some of the settings are optional, you'll need to provide your MOS credentials and the Patch ID for the PUM DPK you wish to use.  The Patch ID can be found on [pum homepage](https://support.oracle.com/epmos/faces/DocumentDisplay?id=1641843.2).  When copying the Patch ID, be sure to select the "Native OS" one.

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

Once configured, you simply have to change to the Vagabond instance directory and run `vagrant up`. Vagrant will then download the box image, start the VM, and begin the provisioning process.  Since Vagabond is just a set of configuration files and provisioning scripts for Vagrant, all of the delivered Vagrant commands can be used.  The following table lists some of the basic commands.


| Task              | Command           | 
| -------------     | -------------     | 
| Start the VM      | `vagrant up`      | 
| Stop the VM       | `vagrant halt`    | 
| Delete the VM     | `vagrant destroy` | 
| Connect to the VM | `vagrant ssh`     | 


TODO List
---------

- [ ] Determine how to make provisioning script idempotent
- [ ] Implement ability to download multiple PUM images and switch between them
- [ ] Determine how to store hiera keys for reuse
- [ ] Figure out options for aria2c in order to output download progress to console
- [ ] Create additional powershell script for running client installation
- [ ] Remove unnecessary packages from OEL VM to save space
- [ ] Add additional providers (AWS, VMWare, etc.)
- [ ] Add option to change the root password
- [ ] Disable root ssh login
- [ ] Implement recommendations for Oracle 12c on Redhat 7 (including hugepages)
- [ ] Figure out how to prevent sshd from binding to bridged network connections


License
-------

This project is licensed under the MIT License.

Copyright © 2016 JR Bing

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
