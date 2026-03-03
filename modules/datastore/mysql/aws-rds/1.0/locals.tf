# Local values for computed attributes and password management
locals {
  # Import detection flags
  import_enabled           = lookup(var.instance.spec, "imports", null) != null ? lookup(var.instance.spec.imports, "import_existing", false) : false
  is_db_instance_import    = local.import_enabled && lookup(var.instance.spec.imports, "db_instance_identifier", null) != null
  is_subnet_group_import   = local.import_enabled && lookup(var.instance.spec.imports, "db_subnet_group_name", null) != null
  is_security_group_import = local.import_enabled && lookup(var.instance.spec.imports, "security_group_id", null) != null

  # Resource identifiers - use imported values if available, otherwise generate new names
  db_identifier       = local.is_db_instance_import ? var.instance.spec.imports.db_instance_identifier : "${var.instance_name}-${var.environment.unique_name}"
  subnet_group_name   = local.is_subnet_group_import ? var.instance.spec.imports.db_subnet_group_name : "${var.instance_name}-${var.environment.unique_name}-subnet-group"
  security_group_name = "${var.instance_name}-${var.environment.unique_name}-sg"
  security_group_id   = local.is_security_group_import ? var.instance.spec.imports.security_group_id : null

  # Add suffix to replica names when importing to avoid conflicts with existing replicas
  base_for_import = substr(local.db_identifier, 0, 44)
  base_cleaned    = substr(local.base_for_import, -1, 1) == "-" ? substr(local.base_for_import, 0, 43) : local.base_for_import

  replica_identifier_base = local.is_db_instance_import ? substr("${local.base_cleaned}imp", 0, 47) : substr(local.db_identifier, 0, 52)

  # Database configuration
  is_restore_operation = try(var.instance.spec.restore_config.restore_from_backup, false)

  # When importing, username and password should be same as the original to avoid overriding existing values
  master_username = local.is_restore_operation ? try(var.instance.spec.restore_config.restore_master_username, "admin") : "admin"
  master_password = local.is_restore_operation ? try(var.instance.spec.restore_config.restore_master_password, null) : try(random_password.master_password[0].result, null)

  # Database name - should be same when importing
  database_name = var.instance.spec.version_config.database_name

  # Max allocated storage (0 means disabled)
  max_allocated_storage = var.instance.spec.sizing.max_allocated_storage > 0 ? var.instance.spec.sizing.max_allocated_storage : null

  # Port mapping for MySQL
  mysql_port = 3306

  # Performance Insights support - only supported on certain instance classes
  performance_insights_supported = !contains(["db.t3.micro", "db.t3.small"], var.instance.spec.sizing.instance_class)
}
