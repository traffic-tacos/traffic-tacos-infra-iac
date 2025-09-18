terraform {
  backend "s3" {
    bucket       = "tfstate-bucket-137406935518" 
    key          = "ticketing/terraform.tfstate"
    region       = "ap-northeast-2" 
    use_lockfile = true
  }
}