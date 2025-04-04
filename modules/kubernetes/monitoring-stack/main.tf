resource "kubernetes_namespace" "monitoring" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.monitoring_namespace
    labels = {
      name = var.monitoring_namespace
      environment = var.environment
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

locals {
  # Default alerting configuration
  default_alertmanager_config = {
    global = {
      resolve_timeout = "5m"
    }
    route = {
      group_by = ["job"]
      group_wait = "30s"
      group_interval = "5m"
      repeat_interval = "12h"
      receiver = "null"
      routes = [
        {
          match = {
            alertname = "Watchdog"
          }
          receiver = "null"
        }
      ]
    }
    receivers = [
      {
        name = "null"
      }
    ]
  }

  # Add Slack configuration if webhook URL is provided
  slack_receiver = length(var.slack_webhook_url) > 0 ? [
    {
      name = "slack"
      slack_configs = [
        {
          channel = "#alerts"
          send_resolved = true
          api_url = var.slack_webhook_url
          title = "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}"
          text = "{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}"
        }
      ]
    }
  ] : []

  # Add Email configuration if email is provided
  email_receiver = length(var.email_to) > 0 ? [
    {
      name = "email"
      email_configs = [
        {
          to = var.email_to
          send_resolved = true
        }
      ]
    }
  ] : []

  # Combine all receivers
  all_receivers = concat([{name = "null"}], local.slack_receiver, local.email_receiver)

  # Update routing for additional receivers
  alertmanager_routes = length(local.all_receivers) > 1 ? [
    {
      match = {
        severity = "critical"
      }
      receiver = length(local.slack_receiver) > 0 ? "slack" : (length(local.email_receiver) > 0 ? "email" : "null")
    }
  ] : []

  final_alertmanager_config = {
    global = {
      resolve_timeout = "5m"
    }
    route = {
      group_by = ["job"]
      group_wait = "30s"
      group_interval = "5m"
      repeat_interval = "12h"
      receiver = "null" 
      routes = local.alertmanager_routes
    }
    receivers = local.all_receivers
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.monitoring_chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.monitoring[0].metadata[0].name : var.monitoring_namespace
  timeout    = 600

  # Essential components
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues" 
    value = "false"
  }

  # Storage configuration
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention_time
  }
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  # Grafana configuration
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.size"
    value = "10Gi"
  }

  # Configure default dashboards
  set {
    name  = "grafana.defaultDashboardsEnabled"
    value = "true"
  }

  # Node Exporter configuration
  set {
    name  = "nodeExporter.enabled"
    value = var.enable_node_exporter
  }

  # Kube State Metrics configuration
  set {
    name  = "kubeStateMetrics.enabled"
    value = var.enable_kube_state_metrics
  }

  # Alertmanager configuration
  set {
    name  = "alertmanager.enabled"
    value = var.enable_alertmanager
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.alert_manager_storage_size
  }

  # Configure AlertManager with constructed config
  set {
    name  = "alertmanager.config"
    value = yamlencode(local.final_alertmanager_config)
  }

  # Configure Grafana Ingress if enabled
  dynamic "set" {
    for_each = var.grafana_ingress_enabled ? [1] : []
    content {
      name  = "grafana.ingress.enabled"
      value = "true"
    }
  }

  dynamic "set" {
    for_each = var.grafana_ingress_enabled ? [1] : []
    content {
      name  = "grafana.ingress.hosts[0]"
      value = var.grafana_ingress_host
    }
  }

  # Configure Prometheus Ingress if enabled
  dynamic "set" {
    for_each = var.prometheus_ingress_enabled ? [1] : []
    content {
      name  = "prometheus.ingress.enabled"
      value = "true"
    }
  }

  dynamic "set" {
    for_each = var.prometheus_ingress_enabled ? [1] : []
    content {
      name  = "prometheus.ingress.hosts[0]"
      value = var.prometheus_ingress_host
    }
  }

  # Set additional scrape configs if provided
  set {
    name  = "prometheus.prometheusSpec.additionalScrapeConfigsEnabled"
    value = length(var.additional_scrape_configs) > 0 ? "true" : "false"
  }

  dynamic "set" {
    for_each = length(var.additional_scrape_configs) > 0 ? [1] : []
    content {
      name  = "prometheus.prometheusSpec.additionalScrapeConfigs"
      value = yamlencode(var.additional_scrape_configs)
    }
  }

  # Add custom alert rules if provided
  dynamic "set" {
    for_each = var.alert_rules
    content {
      name  = "prometheus.prometheusSpec.additionalRuleGroups[0].name"
      value = "custom-rules"
    }
  }

  dynamic "set" {
    for_each = var.alert_rules
    content {
      name  = "prometheus.prometheusSpec.additionalRuleGroups[0].rules"
      value = yamlencode(var.alert_rules)
    }
  }

  # Apply any additional custom values provided
  dynamic "set" {
    for_each = var.monitoring_chart_values
    content {
      name  = set.key
      value = set.value
    }
  }
}

# ServiceMonitor for MongoDB
resource "kubernetes_manifest" "mongodb_service_monitor" {
  count = var.create_namespace ? 1 : 0
  depends_on = [helm_release.kube_prometheus_stack]

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "mongodb-metrics"
      namespace = kubernetes_namespace.monitoring[0].metadata[0].name
      labels = {
        release = "kube-prometheus"
      }
    }
    spec = {
      endpoints = [
        {
          port     = "metrics"
          interval = "30s"
          path     = "/metrics"
        }
      ]
      selector = {
        matchLabels = {
          app = "mongodb"
        }
      }
      namespaceSelector = {
        any = true
      }
    }
  }
}

# ServiceMonitor for Kafka
resource "kubernetes_manifest" "kafka_service_monitor" {
  count = var.create_namespace ? 1 : 0
  depends_on = [helm_release.kube_prometheus_stack]

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "kafka-metrics"
      namespace = kubernetes_namespace.monitoring[0].metadata[0].name
      labels = {
        release = "kube-prometheus"
      }
    }
    spec = {
      endpoints = [
        {
          port     = "metrics"
          interval = "30s"
          path     = "/metrics"
        }
      ]
      selector = {
        matchLabels = {
          app = "kafka"
        }
      }
      namespaceSelector = {
        any = true
      }
    }
  }
}