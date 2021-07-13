$dpk_location = hiera('dpk_location')

case $::osfamily {
  'windows': {
    exec { 'fix-dpk-bug':
      command  => "(gc ${dpk_location}/puppet/production/modules/pt_config/lib/puppet/provider/psae.rb) | %{ \$_ -replace \"ae_program_name=`\"PTEM_CONFIG`\"\", \"ae_program_name=resource[:program_id]\" } | set-content ${dpk_location}/puppet/production/modules/pt_config/lib/puppet/provider/psae.rb",
      provider => powershell,
    }
}
  'RedHat', 'linux': {
    # Remove the PTEM_CONFIG hardcoding - this value is passed in :program_id
    # This change allows us to call any AE
    exec { 'fix-dpk-bug':
      command => "sed -i 's/ae_program_name=\"PTEM_CONFIG\"/ae_program_name=resource[:program_id]/' \
                  ${dpk_location}/puppet/production/modules/pt_config/lib/puppet/provider/psae.rb",
      path    => '/usr/bin',
    }
    # Fix the syntax to look up the connect password
    -> exec { 'fix-connect-pwd-bug':
      command => "sed -i 's/resource[:db_connect_pwd]/:db_connect_pwd/' \
                  ${dpk_location}/puppet/production/modules/pt_config/lib/puppet/provider/psae.rb",
      path    => '/usr/bin',
    }
    # Set the connect password - missing from the lookups
    # Insert below the key_db_connect_id line
    -> exec { 'fix-connect-pwd-bug2':
      command => "sed -i '/key_db_connect_id  = :db_connect_id/a \ \ \ \ \ \ key_db_connect_pwd = :db_connect_pwd' \
                  ${dpk_location}/puppet/production/modules/pt_config/lib/puppet/provider/psae.rb",
      path    => '/usr/bin',
    }
    -> exec { 'fix-connect-pwd-bug3':
      command => "sed -i 's/#{db_connect_pwd}/#{@db_hash[key_db_connect_pwd]}/' \
                  ${dpk_location}/puppet/production/modules/pt_config/lib/puppet/provider/psae.rb",
      path    => '/usr/bin',
    }
  }
}