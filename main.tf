terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }
  }
  backend "s3" {
    bucket  = "dev-abyaz-tf-state"
    key     = "state.tf"
    region  = "ap-south-2"
    encrypt = true

    dynamodb_table         = "dev-abyaz-tf-state-locking"
    skip_region_validation = true
  }
}

provider "aws" {
  region = "ap-south-2"
}

data "aws_availability_zones" "available" {
}

locals {
  vpc_cidr        = "171.23.0.0/16"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]

  instances = {
    master = {
      availability_zone = element(local.azs, 0)
      subnets           = module.network.public_subnets
      instance_name     = "master"
      instance_type     = "t3.medium",
      instance_count    = 1,
      environment       = "dev",
      key_name          = module.keypair.key_name
      volume_size       = 30
      volume_type       = "gp3"
    },
    worker = {
      availability_zone = element(local.azs, 0)
      subnets           = module.network.public_subnets
      instance_name     = "worker"
      instance_type     = "t3.medium",
      instance_count    = 2,
      environment       = "dev",
      key_name          = module.keypair.key_name
      volume_size       = 50
      volume_type       = "gp3"
    },
    ansible = {
      availability_zone = element(local.azs, 0)
      subnets           = module.network.public_subnets
      instance_name     = "ansible"
      instance_type     = "t3.medium",
      instance_count    = 1,
      environment       = "dev",
      key_name          = module.keypair.key_name
      volume_size       = 10
      volume_type       = "gp3"
    }
  }

  sg_config = {
    "master" = {
      ports = [
        {
          from        = 7777
          to          = 7777
          source      = "0.0.0.0/0"
          protocol    = "tcp"
          description = "ssh"
        },
        {
          from        = -1
          to          = -1
          source      = module.network.vpc_cidr
          protocol    = "icmp"
          description = "ping"
        },
        {
          from        = 6783
          to          = 6783
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "weavenet"
        },
        {
          from        = 6443
          to          = 6443
          source      = "0.0.0.0/0"
          protocol    = "tcp"
          description = "api server"
        },
        {
          from        = 10250
          to          = 10250
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "kubelet"
        },
        {
          from        = 10257
          to          = 10257
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "controller manager"
        },
        {
          from        = 10259
          to          = 10259
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "scheduler"
        },
        {
          from        = 2379
          to          = 2380
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "etcd client api"
        },
        {
          from        = 9090
          to          = 9100
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "prometheus"
        }
      ]
    },
    "worker" = {
      ports = [
        {
          from        = 7777
          to          = 7777
          source      = "0.0.0.0/0"
          protocol    = "tcp"
          description = "ssh"
        },
        {
          from        = -1
          to          = -1
          source      = module.network.vpc_cidr
          protocol    = "icmp"
          description = "ping"
        },
        {
          from        = 10250
          to          = 10250
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "kubelet"
        },
        {
          from        = 6783
          to          = 6783
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "WeaveNet"
        },
        {
          from        = 30000
          to          = 32767
          source      = "0.0.0.0/0"
          protocol    = "tcp"
          description = "NodePort"
        },
        {
          from        = 9090
          to          = 9100
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "prometheus"
        },
        {
          from        = 2049
          to          = 2049
          source      = "0.0.0.0/0"
          protocol    = "tcp"
          description = "EFS"
        }
      ]
    },
    "ansible" = {
      ports = [
        {
          from        = 7777
          to          = 7777
          source      = "0.0.0.0/0"
          protocol    = "tcp"
          description = "ssh"
        },
        {
          from        = -1
          to          = -1
          source      = module.network.vpc_cidr
          protocol    = "icmp"
          description = "ping"
        },
        {
          from        = 9090
          to          = 9100
          source      = module.network.vpc_cidr
          protocol    = "tcp"
          description = "prometheus"
        }
      ]
    },
  }

  common_tags = {
    company = "abyaz.in"
    country = "canada"
  }
}

module "keypair" {
  source   = "./modules/keypair"
  key_name = "dev"
  tags     = local.common_tags
}

module "compute" {
  source         = "./modules/compute"
  for_each       = local.instances
  instance_count = each.value.instance_count
  instance_name  = each.value.instance_name

  tags = local.common_tags
}

module "network" {
  source          = "./modules/network"
  name            = "dev-vpc"
  vpc_cidr        = local.vpc_cidr
  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  tags            = local.common_tags
}

module "security" {
  source = "./modules/security"
  config = local.sg_config
  tags   = local.common_tags
}

module "elastic" {
  source = "./modules/elastic"
  access_points = {
    root_example = {
      root_directory = {
        path = "/example"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
    }
  }
  tags = local.common_tags
}
