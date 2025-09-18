module "vpc" {
  source = "./modules/vpc"
}

module "eks" {
  source = "./modules/eks"
  private_subnet_ids= module.vpc.app_subnet
  vpc_id = module.vpc.vpc_id 
  vpc_cidr = module.vpc.vpc_cidr
  bastion_host_ip = module.ec2.bastion_host_ip
}

module  "ec2" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
  public_subnet = module.vpc.public_subnet
}

module "dynamodb" {
  source = "./modules/dynamodb"

  tables = [
    # Ticket service tables
    {
      name     = "tickets"
      hash_key = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" },
        { name = "gsi1pk", type = "S" },
        { name = "gsi1sk", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name               = "GSI1"
          hash_key          = "gsi1pk"
          range_key         = "gsi1sk"
          projection_type   = "ALL"
        }
      ]
    },
    {
      name     = "ticket-events"
      hash_key = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" }
      ]
    },
    # Reservation service tables
    {
      name     = "reservation-reservations"
      hash_key = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" },
        { name = "gsi1pk", type = "S" },
        { name = "gsi1sk", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name               = "GSI1"
          hash_key          = "gsi1pk"
          range_key         = "gsi1sk"
          projection_type   = "ALL"
        }
      ]
    },
    {
      name     = "reservation-orders"
      hash_key = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" },
        { name = "gsi1pk", type = "S" },
        { name = "gsi1sk", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name               = "GSI1"
          hash_key          = "gsi1pk"
          range_key         = "gsi1sk"
          projection_type   = "ALL"
        }
      ]
    },
    {
      name          = "reservation-idempotency"
      hash_key      = "pk"
      ttl_enabled   = true
      ttl_attribute = "ttl"
      attributes = [
        { name = "pk", type = "S" }
      ]
    },
    {
      name     = "reservation-outbox"
      hash_key = "pk"
      range_key = "sk"
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" }
      ]
    }
  ]
}

module "eventbridge" {
  source = "./modules/eventbridge"
  dynamodb_table_arns = values(module.dynamodb.table_arns)
}

module "awsgrafana" {
  source        = "./modules/awsgrafana"
  grafana_name  = "tacos-grafana"
}

module "awsprometheus" {
  source = "./modules/awsprometheus"
}# Atlantis 기본 기능 테스트
