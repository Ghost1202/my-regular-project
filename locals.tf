locals {
  project = "myapp"
  env     = terraform.workspace
  name    = "${local.project}-${local.env}"

  base = {
    aws_region = "eu-central-1"

    zone_name = "kbnby.online"
    fqdn      = "app.kbnby.online"

    key_name          = "my-new-key"
    ssh_allowed_cidrs = ["0.0.0.0/32"]

    ec2_ami_override           = null
    ec2_instance_type_override = null
    ec2_allocate_eip_override  = null

    db_name     = "app"
    db_user     = "app"
    db_password = "change-me"
    db_host     = "127.0.0.1"
    db_port     = 5432

    vpc_cidr       = "10.0.0.0/16"
    azs            = ["eu-central-1a", "eu-central-1b"]
    public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

    backup_bucket_name = "myapp-default-db-backups"
    backup_prefix      = "backups/"
  }

  envs = {
    dev   = {}
    stage = {}
    main  = {}
  }

  current_env_config = merge(
    local.base,
    lookup(local.envs, local.env, local.envs["dev"])
  )

  user_data = templatefile("${path.root}/assets/userdata.tpl", {
    fqdn               = local.current_env_config.fqdn
    db_name            = local.current_env_config.db_name
    db_user            = local.current_env_config.db_user
    db_password        = local.current_env_config.db_password
    db_host            = local.current_env_config.db_host
    db_port            = local.current_env_config.db_port
    backup_bucket_name = local.current_env_config.backup_bucket_name
    aws_region         = local.current_env_config.aws_region
  })
}
