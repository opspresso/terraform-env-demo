# vpc_endpoints

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  # version = "3.12.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id]

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    monitoring = {
      service             = "monitoring"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = module.vpc.intra_subnets
    },
    # elasticfilesystem = {
    #   service             = "elasticfilesystem"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.intra_subnets
    # },
    # sqs = {
    #   service             = "sqs"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.intra_subnets
    # },
    # sns = {
    #   service             = "sns"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.intra_subnets
    # },
    # lambda = {
    #   service             = "lambda"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.intra_subnets
    # },
    # ecs = {
    #   service             = "ecs"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.intra_subnets
    # },
    # ecs_telemetry = {
    #   service             = "ecs-telemetry"
    #   private_dns_enabled = true
    #   subnet_ids          = module.vpc.intra_subnets
    # },
  }

  tags = local.tags
}

resource "aws_vpc_endpoint_route_table_association" "intra_s3" {
  vpc_endpoint_id = module.vpc_endpoints.endpoints.s3.id
  route_table_id  = module.vpc.intra_route_table_ids.0
}
