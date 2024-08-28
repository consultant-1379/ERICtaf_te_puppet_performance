class te_performance::te_performance_proxy_config(
$proxy_host = hiera('common_proxy_host'),
$proxy_port = hiera('common_proxy_port'),
){

anchor { 'te_performance::te_performance_proxy_config::begin': } ~>

# Add proxy config to wget / Jenkins
file_line { 'wget_proxy':
  path => '/etc/wgetrc',
  line => "http_proxy = http://${proxy_host}:${proxy_port}/",
} ->

# Add proxy config to curl / Graphana, Saiku
file { '/root/.curlrc' :
    ensure  => file,
} ->

file_line { 'curl_proxy':
  path => '/root/.curlrc',
  line => "proxy = ${proxy_host}:${proxy_port}",
} ->

# Add proxy config to Yum / Graphite, Collectd
ini_setting { 'yum_proxy':
  ensure  => present,
  path    => '/etc/yum.conf',
  section => 'main',
  setting => 'proxy',
  value   => "http://${proxy_host}:${proxy_port}/",
} ~>

anchor { 'te_performance::te_performance_proxy_config::end': }

}

