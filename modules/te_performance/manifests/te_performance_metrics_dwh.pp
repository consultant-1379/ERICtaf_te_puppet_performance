class te_performance::te_performance_metrics_dwh(
$distribution_url = hiera('te_metrics_dwh_distribution_url'),
$target_dir       = hiera('te_metrics_dwh_target_dir'),
$amqp_url         = hiera('te_metrics_dwh_amqp_url'),
$amqp_exchange    = hiera('te_metrics_dwh_amqp_exchange'),
$db_host          = hiera('te_mysql_db_host'),
$db_name          = hiera('te_mysql_db_name'),
$db_user          = hiera('te_mysql_db_user'),
$db_password      = hiera('te_mysql_db_password')
) {

$db_url       = "jdbc:mysql://${db_host}:3306/${db_name}?user=${db_user}&password=${db_password}"
$metrics_dir  = "${target_dir}te-metrics-dwh"

anchor { 'te_performance::te_performance_metrics_dwh::begin': } ->  
# Create Ericsson dir
file { $target_dir:
  ensure  => directory,
  mode    => '0644',
  recurse => true,
} ->

# Download and extract jar
staging::deploy { 'deploy_te_metrics_dwh.zip':
  source  => $distribution_url,
  target  => $target_dir,
  creates => $metrics_dir ,
} ->

# Register as service
file { '/etc/init.d/te-metrics-dwh':
  owner  => 'root',
  mode   => '0744',
  source => "${metrics_dir}/service.sh",
} ->

# Copy properties and restart service if properties changed
file { "${metrics_dir}/local.properties":
  ensure  => file,
  content => template('te_performance/metrics/local.properties'),
  notify  => Service['te-metrics-dwh'],
} ->

# Ensure service is running
service { 'te-metrics-dwh':
  ensure => 'running',
  enable => 'true',
} ->

anchor { 'te_performance::te_performance_metrics_dwh::end': }

}
