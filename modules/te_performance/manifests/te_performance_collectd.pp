class te_performance::te_performance_collectd (
  $host_name         = 'er3.vts.com',
  $jmx_host          = 'er3.vts.com',
  $jmx_port          = '1088',
  $jmx_user          = '1',
  $jmx_password      = '1',

  $jmx_mbeans        = ['java.lang:type=MemoryPool,*', 'java.lang:type=ClassLoading'],
  $jmx_mbeans_names  = ['name', ''],
  $jmx_attributes    = ['Usage', 'LoadedClassCount'],
  $jmx_tables        = [true, false],
  $jmx_prefixes      = ['memory-', 'loaded-class-count'],

  $amqp_host         = 'mb1',
  $amqp_virtual_host = '/',
  $amqp_user         = 'guest',
  $amqp_password     = 'guest',
  $amqp_exchange     = 'eiffel.poc.graphite',
  $jdk_home          = '/usr/java/jdk1.7.0_17',
) {

ini_setting { 'Yum proxy':
  ensure  => present,
  path    => '/etc/yum.conf',
  section => 'main',
  setting => 'proxy',
  value   => 'http://atproxy1.athtem.eei.ericsson.se:3128/',
} ->

package { 'epel-release':
  ensure   => 'installed',
  source   => 'http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm',
  provider => 'rpm',
} ->

yumrepo { 'marmotte':
    baseurl     => "http://dl.marmotte.net/rpms/redhat/el6/x86_64/",
    enabled     => 1,
    gpgcheck    => 0,
    descr       => 'Is needed for collectd-amqp rpm',
} ->

class { '::collectd':
  purge        => true,
  recurse      => true,
  purge_config => true,
  version      => '5.4.0-1.el6',
} ->

package { 'collectd-amqp':
  ensure   => 'installed',
  provider => 'yum',
} ->

package { 'collectd-java':
  ensure   => 'installed',
  provider => 'yum',
}

file { "/usr/lib64/libjvm.so":
  ensure => link,
  target => "$jdk_home/jre/lib/amd64/server/libjvm.so",
}

class { 'collectd::plugin::cpu':
}

class { 'collectd::plugin::memory':
}

class { 'collectd::plugin::amqp':
  amqphost       => "$amqp_host",
  amqpvhost      => "$amqp_virtual_host",
  graphiteprefix => "taf-monitoring.",
  amqppersistent => true,
  amqpexchange   => "$amqp_exchange",
  amqpuser       => "$amqp_user",
  amqppass       => "$amqp_password",
}

class { 'collectd::plugin::logfile':
  log_level => 'info',
  log_file  => '/var/log/collected.log'
}

class { 'collectd::plugin::processes':
  processes => ['java'],
}

file {'/etc/collectd.d/java.conf':
  content => template('te_performance/collectd/jmx.conf.erb'),
  notify  => Service['collectd'],
}



#ToDo: Java JMX
}