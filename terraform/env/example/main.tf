module "source" {
  source          = "../../module/source"
  replica_s3_arn  = module.replica.replica_s3_arn
  replica_s3_name = module.replica.replica_s3_name
}

module "replica" {
  source = "../../module/replica"
}
