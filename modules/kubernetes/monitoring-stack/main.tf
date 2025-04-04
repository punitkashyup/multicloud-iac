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

# Add local variable for MongoDB service monitor
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
  
  # Define service monitors directly in Helm values - Updated with more precise selectors
  service_monitors = [
    {
      name = "mongodb-metrics"
      # More specific label selectors for MongoDB metrics service
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "mongodb"
        }
      }
      # Specify which namespace to monitor
      namespaceSelector = {
        any = true  # Monitor MongoDB in any namespace
      }
      endpoints = [
        {
          # Port name that matches the metrics service port
          port = "metrics"
          interval = "30s"
          path = "/metrics"
          # Handle TLS if needed
          scheme = "http"
        }
      ]
    },
    {
      name = "kafka-metrics"
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "kafka"
        }
      }
      namespaceSelector = {
        any = true  # Monitor Kafka in any namespace
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
  
  # Define MongoDB job name for dashboard queries
  mongodb_job_name = "mongodb-metrics"
  
  # MongoDB metric prefix based on exporter version (may vary)
  mongodb_metric_prefix = "mongodb_"
  
  # Is this a single node or replica set deployment?
  mongodb_type = "replicaset"  # or "standalone"
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
          
          # Ensure service monitors from all namespaces are discovered
          serviceMonitorNamespaceSelector = {}
          serviceMonitorSelector = {}
          
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
        
        # Enable dashboard sidecar to discover ConfigMaps with dashboards
        sidecar = {
          dashboards = {
            enabled = true
            label = "grafana_dashboard"
            searchNamespace = "ALL"
          }
        }
        
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

# Debugging resource for MongoDB metrics
resource "null_resource" "debug_prometheus_mongodb" {
  depends_on = [helm_release.kube_prometheus_stack]

  # Only run in non-production environments
  count = var.environment == "prod" ? 0 : 1

  provisioner "local-exec" {
    command = <<-EOT
      echo "==============================================="
      echo "MONITORING STACK DEBUGGING INFO"
      echo "==============================================="
      echo "Checking MongoDB metrics service in all namespaces..."
      kubectl get svc --all-namespaces -l app.kubernetes.io/name=mongodb --show-labels
      
      echo "Checking MongoDB metrics endpoints in all namespaces..."
      kubectl get endpoints --all-namespaces -l app.kubernetes.io/name=mongodb
      
      echo "Checking service monitors..."
      kubectl get servicemonitor -n \${var.monitoring_namespace}
      
      echo "Checking Prometheus configuration..."
      kubectl get prometheuses -n \${var.monitoring_namespace} kube-prometheus-prometheus -o jsonpath='{.spec.serviceMonitorSelector}'
      
      echo "==============================================="
      echo "If services exist but no metrics are showing, check:"
      echo "1. MongoDB metrics exporter is enabled"
      echo "2. ServiceMonitor selectors match service labels"
      echo "3. Prometheus is configured to discover the ServiceMonitor"
      echo "==============================================="
    EOT
  }
}

# Create ConfigMap for MongoDB Dashboard using an external file
resource "kubernetes_config_map" "mongodb_dashboard" {
  metadata {
    name      = "mongodb-performance-dashboard"
    namespace = var.create_namespace ? kubernetes_namespace.monitoring[0].metadata[0].name : var.monitoring_namespace
    labels = {
      # These labels are important for Grafana to discover dashboards
      grafana_dashboard = "1"
    }
  }

  data = {
    "mongodb-performance-dashboard.json" = file("${path.module}/mongodb-performance-dashboard.json")
  }

  depends_on = [helm_release.kube_prometheus_stack]
}