bucket         = "terraform-state-multicloud-k8s"
key            = "multicloud-k8s/dev/terraform.tfstate"
region         = "us-west-2"
encrypt        = true
dynamodb_table = "terraform-locks"