#variable "client_id" {}
#variable "client_secret" {}

variable "agent_count" {
  default = 1
}

variable "ssh_public_key" {
  default = "public.key"
}

variable "dns_prefix" {
  default = "k8s"
}

variable cluster_name {
  default = "k8s"
}

variable resource_group_name {
  default = "azure-k8s"
}

variable location {
  default = "UK South"
}

variable controller_location {
  default = "West Europe"
}

resource "random_id" "random-string" {
  byte_length = 4
}
