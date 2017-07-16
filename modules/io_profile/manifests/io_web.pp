class io_profile::io_web {

	notify { "Applying io_profile::io_web": }
	$ensure = hiera('ensure')

	$pia_domain_list = hiera('pia_domain_list')
	if $pia_domain_list {
		$pia_domain_list.each | $domain_name, $pia_domain_info | {

			# Custom Signon
			io_config::io_signon {"${domain_name}-signon":
				ensure		=> $ensure,
				domain_name	=> $domain_name,
				pia_domain_info => $pia_domain_info,
			}

			# Build key on pscipher
			io_config::io_pscipher {"${domain_name}-buildKey":
				ps_cfg_home_dir		=> $pia_domain_info['ps_cfg_home_dir'],
				domain_name			=> $domain_name,
			}

		}
	}
}