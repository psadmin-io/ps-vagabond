# Optional Windows Usage

_These options have not been used supported since PeopleTools 8.55 so use with caution._

#### psft_customizations.yaml (optional) ####

Additionally, if you wish to change the defaults that are used by the DPK you can use the psft_customizations.yaml file.

(Windows Guest Only) If you make changes to the `psft_customizations.yaml` file, you can tell Vagabond to re-sync the file. Use the command `vagrant provision --provision-with=yaml` and the local `psft_customizations.yaml` file will be copied to `$PUPPET_HOME\etc\data\`

#### Custom DPK Modules (optional) ####

(Windows Guest Only) If you want to deploy and test custom DPK modules with Vagabond, copy your Puppet modules and code to `$vagabond_home\config\modules`. Vagabond will check if you have code in the `modules` folder and will copy it to the `$PUPPET_HOME` folder. You can also run `vagrant provision --provision-with=dpk-modules` to re-copy the files into the VM.

If you have a custom DPK Role you want to execute, you can set that in the `config.rb` file. 

```ruby
# CUSTOM DPK ROLE
# Change the DPK Role in site.pp to something custom.
# Use `vagrant provision --provision-with=dpk-modules` to update the site.pp file.
DPK_ROLE = '::io_role::io_tools_demo'
```

#### Apply a PeopleTools Patch (optional) ####

(Windows Guest Only) The Windows version of Vagabond can download and apply a PeopleTools Patch to the PeopleSoft Image. To apply a patch, uncomment two values in the `config.rb` file:

```ruby
# PEOPLETOOLS_PATCH
# To apply a PeopleTools Patch to the PeopleSoft Image, you must be using 
# a Windows NativeOS DPK. Change APPLY_PT_PATCH to 'true' and enter the 
# Patch ID for PTP_PATCH_ID.
APPLY_PT_PATCH='true'
PTP_PATCH_ID='26201347' # 8.55.17
```

Uncommenting the `APPLY_PT_PATCH` line will tell Vagabond to run additional provisions that apply a PT Patch to a fully build PeopleSoft Image. You must also provide a valid Patch ID for the PeopleTools Patch you want to apply. Vagabond will automatically download the patch files for you. Once the files are downloaded, Vagabond will apply the patch to the database and rebuild the domains on the new PeopleTools version.

### Operating System

Vagabond supports the Linux and Windows NativeOS Deployment Packages. By default, Vagabond will use the Linux NativeOS DPK with an Oracle Enterprise Linux virtual machine. To enable a Windows build with Vagabond, uncomment this line in the `config/config.rb` file.

```ruby

# OPERATING_SYSTEM
# Which OS to use as the base box for the DPK.  The available options
# are either 'LINUX' (Oracle Enterprise Linux 7.x) or 'WINDOWS'
# If left undefined, it will default to Linux.
OPERATING_SYSTEM = 'WINDOWS'
# One Windows Versions is supported, "2016"
# WIN_VERSION = "2016"
```

The Windows virtual machine is an evaluation version of Windows 2016 and is only intended for demonstration purposes. [You can build your own base Windows VM](https://www.vagrantup.com/docs/virtualbox/boxes.html) with a licensed copy of Windows to use for testing and production support.
