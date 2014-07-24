class rails(
	$ruby_version 		= $rails::params::ruby_version,
	$uses 				= $rails::params::uses,
	$db					= $rails::params::db,
	$serve_using		= $rails::params::serve_using,
	$deploy_using		= $rails::params::deploy_using,
	$shared_dirs		= $rails::params::shared_dirs,
	$server_name		= $rails::params::server_name,
) inherits rails::params {

}