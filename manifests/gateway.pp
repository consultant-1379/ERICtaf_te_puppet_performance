# Ensure that ports are forwarded
$port_graphite      = hiera('port_graphite')
$port_saiku         = hiera('port_saiku')
$port_grafana       = hiera('port_grafana')
$port_elasticsearch = hiera('port_elasticsearch')
$port_rabbitmq_cli  = hiera('port_rabbitmq_cli')

$ip_graphite      = hiera('ip_graphite')
$ip_saiku         = hiera('ip_saiku')
$ip_grafana       = hiera('ip_grafana')
$ip_elasticsearch = hiera('ip_elasticsearch')

firewall { '102 forward to Graphite':
   chain => 'PREROUTING',
   proto => 'tcp',
   todest => "${ip_graphite}:${port_graphite}",
   dport => $port_graphite,
   source => '! 192.168.0.1/24',
   jump => 'DNAT',
   table => 'nat',
}

firewall { '104 forward to Saiku':
  chain => 'PREROUTING',
  proto => 'tcp',
  todest => "${ip_saiku}:${port_saiku}",
  dport => $port_saiku,
  jump => 'DNAT',
  source => '! 192.168.0.1/24',
  table => 'nat',
}

firewall { '104 forward to Graphana':
  chain => 'PREROUTING',
  proto => 'tcp',
  todest => "${ip_grafana}:${port_grafana}",
  dport => $port_grafana,
  source => '! 192.168.0.1/24',
  jump => 'DNAT',
  table => 'nat',
}

firewall { '105 forward to Elasticsearch':
  chain => 'PREROUTING',
  proto => 'tcp',
  todest => "${ip_elasticsearch}:${port_elasticsearch}",
  dport => $port_elasticsearch,
  source => '! 192.168.0.1/24',
  jump => 'DNAT',
  table => 'nat',
}
