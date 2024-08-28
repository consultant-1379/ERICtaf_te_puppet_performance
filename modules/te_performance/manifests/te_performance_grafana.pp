class te_performance::te_performance_grafana(
    $gateway_host       = hiera('gateway_host'),
    $port_grafana       = hiera('port_grafana'),
    $port_graphite      = hiera('port_graphite'),
    $port_elasticsearch = hiera('port_elasticsearch')
    ) {  
    
    $default_dashboard = template('te_performance/grafana/taf_performance')

    require te_performance_proxy_config

    anchor { 'te_performance::te_performance_grafana::begin': } ->

    firewall { "100 open ${port_grafana} port for Grafana":
      port   => $port_grafana,
      proto  => tcp,
      action => accept,
    } ->

    firewall { "100 open ${port_elasticsearch} port for Elasticsearch":
      port   => $port_elasticsearch,
      proto  => tcp,
      action => accept,
    } ->
    
    package {'curl':
      ensure   => 'installed',
      provider => 'yum'
    } ->

    file_line { "Add listen port ${port_grafana}":
      path => '/etc/httpd/conf/httpd.conf',
      line => "Listen ${port_grafana}"
    } ->

    class { 'grafana':
      graphite_host       => $gateway_host,
      graphite_port       => $port_graphite,
      elasticsearch_host  => $gateway_host,
      version             => '1.7.0'
    } ->

    file { "/etc/httpd/conf.d/grafana.conf":
      ensure  => file,
      content => template('te_performance/httpd/grafana.conf'),
    } ->

    # Load default dashboard
    file_line { 'default_dashboard_conf':
      require => Class['grafana'],
      path    => '/opt/grafana/config.js',
      line    => '    default_route: \'/dashboard/db/TAF Performance\',',
      match   => 'default_route: .*,'
    }

    yumrepo { "elasticsearch":
      baseurl  => "http://packages.elasticsearch.org/elasticsearch/1.3/centos",
      descr    => "Elasticsearch repository for 1.3.x packages",
      enabled  => 1,
      gpgcheck => 0
    } -> 

    package { 'elasticsearch':
        ensure   => 'installed',
        provider => 'yum'
    } ->

    service { 'elasticsearch':
        ensure => 'running'
    }

    exec { 'create_taf_performance_dashboard':
      require => Service['elasticsearch'],
      unless  => "/usr/bin/curl http://${gateway_host}:9200/grafana-dash/dashboard/TAF%20Performance | /bin/grep '\"found\":true'",
      command => "/usr/bin/curl -X PUT -H 'Expect:' -d '${default_dashboard}' http://${gateway_host}:9200/grafana-dash/dashboard/TAF%20Performance",
    } ->

    anchor { 'te_performance::te_performance_grafana::end': }
}
