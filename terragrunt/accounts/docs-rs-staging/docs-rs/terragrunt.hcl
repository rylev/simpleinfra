terraform {
  source = "../../../modules//docs-rs"
}

include {
  path           = find_in_parent_folders()
  merge_strategy = "deep"
}

dependency "dns_zone" {
  config_path = "../dns-zone"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "cluster" {
  config_path = "../ecs-cluster"
}

inputs = {
  zone_id            = dependency.dns_zone.outputs.id
  cluster_config     = dependency.cluster.outputs.config
  private_subnet_ids = dependency.vpc.outputs.private_subnets
  domain             = "docs-rs-staging.rust-lang.net"
}
