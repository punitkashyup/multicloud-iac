output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = var.prometheus_ingress_enabled ? "https://${var.prometheus_ingress_host}" : "http://kube-prometheus-prometheus.${var.monitoring_namespace}.svc:9090"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = var.grafana_ingress_enabled ? "https://${var.grafana_ingress_host}" : "http://kube-prometheus-grafana.${var.monitoring_namespace}.svc:80"
}

output "alertmanager_url" {
  description = "URL to access AlertManager"
  value       = "http://kube-prometheus-alertmanager.${var.monitoring_namespace}.svc:9093"
}

output "monitoring_namespace" {
  description = "Namespace where monitoring stack is deployed"
  value       = var.create_namespace ? kubernetes_namespace.monitoring[0].metadata[0].name : var.monitoring_namespace
}