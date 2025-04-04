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
  
  # Define service monitors directly in Helm values
  service_monitors = [
    {
      name = "mongodb-metrics"
      selector = {
        matchLabels = {
          app = "mongodb"
        }
      }
      namespaceSelector = {
        any = true
      }
      endpoints = [
        {
          port = "metrics"
          interval = "30s"
          path = "/metrics"
        }
      ]
    },
    {
      name = "kafka-metrics"
      selector = {
        matchLabels = {
          app = "kafka"
        }
      }
      namespaceSelector = {
        any = true
      }
      endpoints = [
        {
          port = "metrics"
          interval = "30s"
          path = "/metrics"
        }
      ]
    }
  ]
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.monitoring_chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.monitoring[0].metadata[0].name : var.monitoring_namespace
  timeout    = 600

  # Combine all values into a single values block using yamlencode
  values = [
    yamlencode({
      # Add ServiceMonitors to monitor MongoDB and Kafka
      additionalServiceMonitors = local.service_monitors
      
      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          # Essential configurations
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues = false
          
          # Storage configuration
          retention = var.prometheus_retention_time
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
          
          # Add custom alert rules if provided
          additionalRuleGroups = length(var.alert_rules) > 0 ? [
            {
              name = "custom-rules"
              rules = values(var.alert_rules)
            }
          ] : []
          
          # Add scrape configs if provided
          additionalScrapeConfigsEnabled = length(var.additional_scrape_configs) > 0
          additionalScrapeConfigs = length(var.additional_scrape_configs) > 0 ? var.additional_scrape_configs : []
        }
        
        # Configure Prometheus Ingress if enabled
        ingress = {
          enabled = var.prometheus_ingress_enabled
          hosts = var.prometheus_ingress_enabled ? [var.prometheus_ingress_host] : []
        }
      }
      
      # Grafana configuration
      grafana = {
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled = true
          size = "10Gi"
        }
        defaultDashboardsEnabled = true
        
        # Configure Grafana Ingress if enabled
        ingress = {
          enabled = var.grafana_ingress_enabled
          hosts = var.grafana_ingress_enabled ? [var.grafana_ingress_host] : []
        }
      }
      
      # Node Exporter configuration
      nodeExporter = {
        enabled = var.enable_node_exporter
      }
      
      # Kube State Metrics configuration
      kubeStateMetrics = {
        enabled = var.enable_kube_state_metrics
      }
      
      # Alertmanager configuration
      alertmanager = {
        enabled = var.enable_alertmanager
        config = local.final_alertmanager_config
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.alert_manager_storage_size
                  }
                }
              }
            }
          }
        }
      }
    }),
    
    # Add any additional custom values
    yamlencode(var.monitoring_chart_values)
  ]
}