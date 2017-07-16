define io_config::io_signon (
	$ensure 			= present,
	$domain_name		= undef,
	$pia_domain_info 	= undef,
	)
{

	  $index_html_template = @(END)
	  <html>
	  	<head>
	  		<title>PSADMIN.IO</title>
	  		<META http-equiv="refresh" content="0;URL='<%= @root_signon_url %>'" />
	  	</head>
	  	<body>
	  	</body>
	  </html>
	  END

	$cfg_home = $pia_domain_info['ps_cfg_home_dir']
	$baseWebPath = "${cfg_home}/webserv/${domain_name}/applications/peoplesoft/PORTAL.war/"
	$root_signon_url = $pia_domain_info['root_signon_url']

	file {"io-redirect-${domain_name}":
		ensure		=> $ensure,
		path 		=> "${baseWebPath}/index.html",
		content		=> inline_template($index_html_template),
	}

	$site_list = $pia_domain_info['site_list']
	$site_list.each | $site_name, $site_info | {

		file {"io-logo-${domain_name}-${site_name}":
			ensure 	=> $ensure,
			path	=> "${baseWebPath}/${site_name}/images/io_logo.png",
			source  => "puppet:///modules/io_config/psadmin_io_blue_400.png",
			source_permissions => ignore,
		}

		file {"io-sigin-${domain_name}-${site_name}":
			ensure 	=> $ensure,
			path	=> "${baseWebPath}/WEB-INF/psftdocs/${site_name}/signin.html",
			source 	=> "puppet:///modules/io_config/signin.html",
			source_permissions	=> ignore,
		}
	} #end site_list


}