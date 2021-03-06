terraform {
  required_providers {
    archive = "1.3.0"
    aws     = "2.54.0"
    null    = "2.1.2"
    tls     = "2.1.1"
    random  = "2.2.1"
    local   = "1.4.0"
  }
}

locals {
  aws_access_key = try(var.provose_config.authentication.aws.access_key, null)
  aws_secret_key = try(var.provose_config.authentication.aws.secret_key, null)
}

# TODO: There are many ways to authenticate to AWS. We should support them all.
provider "aws" {
  region     = var.provose_config.authentication.aws.region
  access_key = local.aws_access_key
  secret_key = local.aws_secret_key
}

# AWS Certificate Manager certifiates for CloudFront are always in us-east-1, no
# matter what AWS region the user is storing all of their other stuff in.
provider "aws" {
  alias      = "acm_lookup"
  region     = "us-east-1"
  access_key = local.aws_access_key
  secret_key = local.aws_secret_key
}

locals {
  AWS_COMMAND = local.aws_access_key != null && local.aws_secret_key != null ? "AWS_ACCESS_KEY_ID='${local.aws_access_key}' AWS_SECRET_ACCESS_KEY_ID='${local.aws_secret_key}' aws --region ${data.aws_region.current.name} " : "aws --region ${data.aws_region.current.name} "
}
