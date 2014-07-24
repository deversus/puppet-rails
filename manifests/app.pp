define rails::app (
	$app_name 		= $title,
	$ruby_version 	= $rails::ruby_version,
	$db 			= $rails::db,
	$uses 			= $rails::uses,
	$serve_using 	= $rails::serve_using,
	$deploy_using 	= $rails::deploy_using,
	$server_name	= $rails::server_name,
	$shared_dirs 	= $rails::shared_dirs,
) {
	validate_string($app_name)
	if $ruby_version {
		validate_string($ruby_version)
	}
	validate_string($db)
	validate_hash($uses)

	# Helps us order things:
	$deps = "rails::app::${title}::deps"
	$setup = "rails::app::${title}::setup"
	anchor {$deps: } -> anchor {$setup: }

	# Universal deps

	$dep_packages = [
		'nodejs',
		'build-essential',
	]
	ensure_packages($dep_packages)
	Package[$dep_packages] -> Anchor[$deps]


	# Gem-specific deps

	if 'rmagick' in $uses {
		$magick = 'libmagickwand-dev'
		ensure_packages([$magick])
		Package[$magick] -> Anchor[$deps]
	}


	if 'sidekiq' in $uses {
		$redis = 'redis-server'
		ensure_packages([$redis])
		ensure_resource('service', $redis, {
			ensure => 'running'
		})
		
		Package[$redis]  -> Service[$redis] -> Anchor[$deps]
	}

	if 'nokogiri' in $uses {
		$xml_libs = ['libxslt1-dev','libxml2-dev']
		ensure_packages($xml_libs)
		Package[$xml_libs] -> Anchor[$deps]
	}

	if 'elasticsearch' in $uses {
		# elasticsearch-elasticsearch
		$es_version = $uses['elasticsearch']
		# there can be only one service running anyway
		class {'elasticsearch':
			ensure       => present,
			package_url  => "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${es_version}.deb",
			java_install => true,
			config 		 => {},
		} -> Anchor[$deps]
	}

	# Db deps
	case $db {
		'mysql': {
			$mysql = 'libmysqlclient-dev'
			ensure_packages([$mysql])
			Package[$mysql] -> Anchor[$deps]
		}
		default: {
			fail("Unknown db type: $db")
		}
	}

	# Serving

	case $serve_using {
		'nginx/puma': {
			$share_group = 'puma' # used by capistrano below
			
			puma::app {$app_name:
				app_root => $app_root,
				rvm_ruby => $ruby_version,
			} -> Anchor[$setup]

			puma::nginxconfig {$app_name:
				server_name		=> $server_name,
				public_root 	=> $public_root,
				require			=> Puma::App[$app_name],
				
			}

		}
		default: {
			fail("Unknown serving method: $serve_using")
		}
	}

	# Deploy

	case $deploy_using {
		'capistrano': {
			capistrano::deploytarget {$app_name:
				share_group => $share_group,
				shared_dirs => $shared_dirs,
			}

			$app_root 		= join([sprintf($capistrano::deploy_dir_spf, $app_name), 'current'], '/')
			$public_root 	= join([sprintf($capistrano::deploy_dir_spf, $app_name), 'current', 'public'], '/')
		}
		default: {
			fail("Unknown deploy method: $deploy_using")
		}
	}

	

}