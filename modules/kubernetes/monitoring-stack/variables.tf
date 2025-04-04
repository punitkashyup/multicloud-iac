variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create monitoring namespace"
  type        = bool
  default     = true
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring components"
  type        = string
  default     = "monitoring"
}

variable "prometheus_retention_time" {
  description = "Prometheus data retention period"
  type        = string
  default     = "10d"
}

variable "prometheus_storage_size" {
  description = "Prometheus storage size"
  type        = string
  default     = "100Gi"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "prom-operator" # Not secure - use secrets management in production
}

variable "enable_alertmanager" {
  description = "Whether to deploy Alertmanager"
  type        = bool
  default     = true
}

variable "alert_manager_storage_size" {
  description = "AlertManager storage size"
  type        = string
  default     = "10Gi"
}

variable "monitoring_chart_version" {
  description = "Version of the kube-prometheus-stack Helm chart"
  type        = string
  default     = "45.7.1" # Update to the latest version as needed
}

variable "additional_scrape_configs" {
  description = "Additional Prometheus scrape configurations"
  type        = list(any)
  default     = []
}

variable "alert_rules" {
  description = "Custom Prometheus alert rules"
  type        = map(any)
  default     = {}
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alerts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "email_to" {
  description = "Email address to send alerts to"
  type        = string
  default     = ""
}

variable "grafana_ingress_enabled" {
  description = "Enable Ingress for Grafana"
  type        = bool
  default     = false
}

variable "grafana_ingress_host" {
  description = "Hostname for Grafana Ingress"
  type        = string
  default     = "grafana.example.com"
}

variable "prometheus_ingress_enabled" {
  description = "Enable Ingress for Prometheus"
  type        = bool
  default     = false
}

variable "prometheus_ingress_host" {
  description = "Hostname for Prometheus Ingress"
  type        = string
  default     = "prometheus.example.com"
}

variable "monitoring_chart_values" {
  description = "Custom values for kube-prometheus-stack Helm chart"
  type        = map(any)
  default     = {}
}

variable "enable_node_exporter" {
  description = "Whether to deploy Node Exporter"
  type        = bool
  default     = true
}

variable "enable_kube_state_metrics" {
  description = "Whether to deploy kube-state-metrics"
  type        = bool
  default     = true
}