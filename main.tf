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