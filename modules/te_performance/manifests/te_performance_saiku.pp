class te_performance::te_performance_saiku(
$te_metrics_olap_schema_url = hiera('te_saiku_metrics_olap_schema_url'),
$tomcat_version             = hiera('te_saiku_tomcat_version'),
$saiku_webapp               = hiera('te_saiku_webapp'),
$saiku_ui                   = hiera('te_saiku_ui'),
$db_host                    = hiera('te_mysql_db_host'),
$db_name                    = hiera('te_mysql_db_name'),
$db_user                    = hiera('te_mysql_db_user'),
$db_password                = hiera('te_mysql_db_password'),
$port_saiku                 = hiera('port_saiku')
) {

$db_url = "jdbc:mysql://${db_host}:3306/${db_name}?user=${db_user}&password=${db_password}"

require te_performance_proxy_config

anchor { 'te_performance::te_performance_saiku::begin': } -> 

# Configure firewall
firewall { "100 open ${port_saiku} port-saiku":
  port   => $port_saiku,
  proto  => tcp,
  action => accept,
} ->

# Install MySql
class { '::mysql::server':
  root_password => 'shroot',
} ->

# Create user
mysql_user { 'saiku_user@localhost':
  ensure        => 'present',
  password_hash => mysql_password('password')
} ->

# Add grants for user
mysql_grant { 'saiku_user@localhost/*.*':
  ensure     => 'present',
  options    => ['GRANT'],
  privileges => ['ALL'],
  table      => '*.*',
  user       => 'saiku_user@localhost',
} ->

# Create db, user & run bootstrap script
file { '/tmp/bootstrap.sql':
  ensure  => file,
  content => template('te_performance/sql/bootstrap.sql'),
} ->

mysql::db { $db_name:
  user     => $db_user,
  password => $db_password,
  host     => 'localhost',
  grant    => ['DELETE','INSERT','SELECT','UPDATE'],
  sql      => "/tmp/bootstrap.sql",
}

# Download tomcat

$target_dir  = '/opt/'
$tomcat_path = "${target_dir}apache-tomcat-${tomcat_version}"

$saiku_webapp_path = "${tomcat_path}/webapps/saiku/"
$saiku_ui_path     = "${tomcat_path}/webapps/saiku-ui/"

staging::deploy { 'deploy-tomcat.tar.gz':
  source  => "http://apache.mirrors.spacedump.net/tomcat/tomcat-7/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.tar.gz",
  target  => $target_dir,
  creates => $tomcat_path,
} ->

file_line { 'Tomcat Port':
    ensure => present,
    line   => "<Connector port=\"${port_saiku}\" protocol=\"HTTP/1.1\"",
    path   => "${tomcat_path}/conf/server.xml",
    match  => '<Connector port=".* protocol="HTTP/1.1"'
} ->

# If directories do not exit (webapps wasn't deployed) create it and stop Tomcat
file { [$saiku_webapp_path, $saiku_ui_path]:
  ensure  => directory,
  recurse => true,
} ~>
exec { 'stop_tomcat':
  command     => "${tomcat_path}/bin/shutdown.sh",
  refreshonly => true
}

staging::deploy { 'deploy_saiku.war':
  source  => $saiku_webapp,
  target  => $saiku_webapp_path,
  creates => "${saiku_webapp_path}WEB-INF",
} ->
staging::deploy { 'deploy_saiku_ui.war':
  source  => $saiku_ui,
  target  => $saiku_ui_path,
  creates => "${saiku_ui_path}index.html",
} ->

# Configure Saiku
file { ["${tomcat_path}/webapps/saiku/WEB-INF/classes/saiku-datasources/","${tomcat_path}/webapps/saiku/WEB-INF/classes/samples/","/tmp/te_metrics_olap_schema"]:
  ensure  => directory,
  recurse => true,
} ->
file { "${tomcat_path}/webapps/saiku/WEB-INF/classes/saiku.properties":
  ensure  => file,
  content => template('te_performance/saiku/saiku.properties'),
} ->
file { "${tomcat_path}/webapps/saiku/WEB-INF/classes/saiku-datasources/samples":
  ensure  => file,
  content => template('te_performance/saiku/saiku-datasources/samples'),
} ->
file { "${tomcat_path}/webapps/saiku/WEB-INF/classes/saiku-repository/Rpt Report.saiku":
  ensure  => file,
  content => template('te_performance/saiku/saiku-repository/Rpt Report.saiku'),
} ->
staging::deploy { 'download_olap_schema.zip':
  source  => $te_metrics_olap_schema_url,
  target  => '/tmp/te_metrics_olap_schema',
  creates => '/tmp/te_metrics_olap_schema/taf-metrics-schema.xml',
} ->
file { "${tomcat_path}/webapps/saiku/WEB-INF/classes/samples/samples.xml":
  ensure  => file,
  source  => '/tmp/te_metrics_olap_schema/taf-metrics-schema.xml',
} ->
exec { 'ensure_tomcat_running':
  unless  => '/usr/bin/pgrep -f tomcat',
  command => "${tomcat_path}/bin/startup.sh",
} ->

anchor { 'te_performance::te_performance_saiku::end': } 

}
