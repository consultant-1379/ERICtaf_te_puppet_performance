class te_performance::te_performance_graphite (
  $http_proxy    = hiera('common_http_proxy'),
  $port_graphite = hiera('port_graphite')
) {

require te_performance_proxy_config

anchor { 'te_performance::te_performance_graphite::begin': 
  notify => Class['graphite']
}

package { 'epel-release':
  ensure   => 'installed',
  source   => 'http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm',
  provider => 'rpm',
} ->

file { '/root/.pip/':
  ensure  => directory,
  mode    => '0644',
  recurse => true,
} ->

# Ensure proxy for PIP is set
ini_setting { 'PIP proxy':
  ensure  => present,
  path    => '/root/.pip/pip.conf',
  section => 'global',
  setting => 'proxy',
  value   => $http_proxy,
} ->

#Override txamqp version in graphite class
Package<| title == 'txamqp' |> {
  ensure => '0.6.2',
}

#Override twisted version in graphite class
Package<| title == 'twisted' |> {
  ensure => '11.1.0',
}

# Install graphite
class { 'graphite':
  gr_apache_port              => $port_graphite,
  gr_amqp_enable              => True,
  gr_amqp_host                => 'mb1',
  gr_amqp_port                => 5672,
  gr_amqp_vhost               => '/',
  gr_amqp_user                => 'guest',
  gr_amqp_password            => 'guest',
  gr_amqp_exchange            => 'eiffel.poc.graphite',
  gr_amqp_metric_name_in_body => True,
  gr_web_cors_allow_from_all  => True,
  gr_storage_schemas          => [
    {
      name       => 'carbon',
      pattern    => '^carbon\.',
      retentions => '1m:90d'
    },
    {
      name       => 'default',
      pattern    => '.*',
      retentions => '1s:7d,1m:30d,15m:5y'
    }
  ],  
}

file { '/opt/graphite':
  ensure  => directory,
  recurse => true,
  owner   => "apache",
  group   => "apache",
} ->

# Configure firewall
firewall { '100 open 80 port':
  port   => 80,
  proto  => tcp,
  action => accept,
}

anchor { 'te_performance::te_performance_graphite::end': 
  notify => Class['graphite']
}

}

