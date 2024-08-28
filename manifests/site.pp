node 'grafana.vts.com' {
  class { "te_performance::te_performance_graphite": } ->
  class { "te_performance::te_performance_grafana": }
}

node 'saiku.vts.com' {
  include te_performance::te_performance_saiku
  include te_performance::te_performance_metrics_dwh
}
