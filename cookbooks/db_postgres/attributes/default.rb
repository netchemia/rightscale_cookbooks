#
# Cookbook Name:: db_postgres
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

# Recommended attributes
set_unless[:db_postgres][:server_usage] = "dedicated"  # or "shared"
set_unless[:db_postgres][:previous_master] = nil

# Optional attributes
set_unless[:db_postgres][:port] = "5432"

set_unless[:db_postgres][:tmpdir] = "/tmp"
set_unless[:db_postgres][:ident_file] = ""
set_unless[:db_postgres][:pid_file] = ""
set_unless[:db_postgres][:bind_address] = cloud[:private_ips][0]

# Platform specific attributes
case platform
when "centos", "redhat"
  set_unless[:db_postgres][:packages_uninstall] = ""
  set_unless[:db_postgres][:log] = ""
  set_unless[:db_postgres][:log_error] = ""
end
