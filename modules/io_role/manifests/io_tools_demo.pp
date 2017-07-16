/*
 * ***************************************************************
 *  This software and related documentation are provided under a
 *  license agreement containing restrictions on use and
 *  disclosure and are protected by intellectual property
 *  laws. Except as expressly permitted in your license agreement
 *  or allowed by law, you may not use, copy, reproduce,
 *  translate, broadcast, modify, license, transmit, distribute,
 *  exhibit, perform, publish or display any part, in any form or
 *  by any means. Reverse engineering, disassembly, or
 *  decompilation of this software, unless required by law for
 *  interoperability, is prohibited.
 *  The information contained herein is subject to change without
 *  notice and is not warranted to be error-free. If you find any
 *  errors, please report them to us in writing.
 *
 *  Copyright (C) 1988, 2015, Oracle and/or its affiliates.
 *  All Rights Reserved.
 * ***************************************************************
 */
class io_role::io_tools_demo inherits pt_role::pt_base {

  notify { "Applying io_role::io_tools_demo": }

  $ensure   = hiera('ensure')
  $env_type = hiera('env_type')

  if $env_type != 'fulltier' {
    fail('The io_tools_demo role can only be applied to env_type of fulltier')
  }
  contain ::pt_profile::pt_tools_deployment
  contain ::pt_profile::pt_psft_environment
  contain ::pt_profile::pt_appserver
  contain ::pt_profile::pt_prcs
  contain ::pt_profile::pt_pia
  contain ::io_profile::io_web
  contain ::pt_profile::pt_samba
  contain ::pt_profile::pt_source_details

  if $ensure == present {
    contain ::pt_profile::pt_tools_preboot_config
    contain ::pt_profile::pt_domain_boot
    contain ::pt_profile::pt_tools_postboot_config

    Class['::pt_profile::pt_system'] ->
    Class['::pt_profile::pt_tools_deployment'] ->
    Class['::pt_profile::pt_psft_environment'] ->
    Class['::pt_profile::pt_appserver'] ->
    Class['::pt_profile::pt_prcs'] ->
    Class['::pt_profile::pt_pia'] ->
    Class['::io_profile::io_web'] ->
    Class['::pt_profile::pt_samba'] ->
    Class['::pt_profile::pt_tools_preboot_config'] ->
    Class['::pt_profile::pt_domain_boot'] ->
    Class['::pt_profile::pt_tools_postboot_config'] -> 
    Class['::pt_profile::pt_source_details'] 
  }
  elsif $ensure == absent {
    Class['::pt_profile::pt_samba'] ->
    Class['::io_profile::io_web'] ->
    Class['::pt_profile::pt_pia'] ->
    Class['::pt_profile::pt_prcs'] ->
    Class['::pt_profile::pt_appserver'] ->
    Class['::pt_profile::pt_psft_db'] ->
    Class['::pt_profile::pt_psft_environment'] ->
    Class['::pt_profile::pt_tools_deployment'] ->
    Class['::pt_profile::pt_system']
  }
}
