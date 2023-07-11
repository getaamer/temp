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
      availability_zone  = element(local.azs, 0)
      subnets            = module.network.public_subnets
      instance_name      = "master"
      instance_type      = "t3.medium"
      instance_count     = 1
      volume_size        = 27
      environment        = "dev"
      key_name           = module.keypair.key_name
      security_group_ids = [module.security.master-sg.id]
      attach_public_ip   = true
    },
    worker = {
      availability_zone  = element(local.azs, 0)
      subnets            = module.network.public_subnets
      instance_name      = "worker"
      instance_type      = "t3.medium"
      instance_count     = 2
      environment        = "dev"
      key_name           = module.keypair.key_name
      volume_size        = 32
      security_group_ids = [module.security.worker-sg.id]
      attach_public_ip   = true
    },
    ansible = {
      availability_zone  = element(local.azs, 0)
      subnets            = module.network.public_subnets
      instance_name      = "ansible"
      instance_type      = "t3.small"
      instance_count     = 1
      environment        = "dev"
      key_name           = module.keypair.key_name
      volume_size        = 11
      security_group_ids = [module.security.ansible-sg.id]
      attach_public_ip   = true
    }
  }

  sg_config = {
    "master" = {
      ports = [
        {
          from        = 22
          to          = 22
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
          from        = 22
          to          = 22
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
          from        = 22
          to          = 22
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
    "efs" = {
      ports = [
        {
          from        = 2049
          to          = 2049
          source      = "0.0.0.0/0"
          protocol    = "tcp"
          description = "efs"
        },
        {
          from        = 22
          to          = 22
          source      = "0.0.0.0/0"
          protocol    = "tcp"
          description = "ssh"
        }
      ]
    }
  }

  common_tags = {
    company = "abyaz.in"
    country = "canada"
  }
}

module "keypair" {
  source   = "./modules/keypair"
  key_name = "id_rsa"
  tags     = local.common_tags
}

module "compute" {
  source   = "./modules/compute"
  for_each = local.instances
  key_name = each.value.key_name

  instance_count     = each.value.instance_count
  instance_name      = each.value.instance_name
  instance_type      = each.value.instance_type
  volume_size        = each.value.volume_size
  attach_public_ip   = each.value.attach_public_ip
  security_group_ids = each.value.security_group_ids

  subnets = each.value.subnets
  tags    = local.common_tags
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
  vpc_id = module.network.vpc_id
  tags   = local.common_tags
}

module "elastic" {
  source    = "./modules/elasticfs"
  subnets   = length(module.network.public_subnets)
  subnet_id = module.network.public_subnets
  efs-sg    = module.security.efs-sg
  tags      = local.common_tags
}
