#
# Cookbook Name:: logging_rsyslog
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

define :configure_stunnel, :accept => "514", :connect => "515", :client => nil do

  raise "  ERROR: Input SSL Certificate to establish secure connection." if node[:logging][:certificate].nil?

  # Installing stunnel
  package "stunnel"

  certificate = "/etc/stunnel/stunnel.pem"

  # Saving certificate if provided by user
  template certificate do
    source "stunnel.pem.erb"
    cookbook "logging_rsyslog"
  end

  owner = value_for_platform(
    ["ubuntu"] => { "default" => "stunnel4" },
    ["centos", "redhat"] => { "default" => "nobody" }
  )
  group = value_for_platform(
    ["ubuntu"] => { "default" => "stunnel4" },
    ["centos", "redhat"] => { "default" => "nobody" }
  )

  # Restricting access to the certificate
  file certificate do
    owner owner
    group group
    mode "0400"
    action :touch
  end

  # Writing stunnel configuration file
  template "/etc/stunnel/stunnel.conf" do
    source "stunnel.conf.erb"
    cookbook "logging_rsyslog"
    owner "root"
    group "root"
    mode "0644"
    variables(
      :certificate => certificate,
      :client => params[:client],
      :chroot => value_for_platform(
        ["ubuntu"] => { "default" => "/var/lib/stunnel4/" },
        ["centos", "redhat"] => { "default" => "/var/run/stunnel/" }
      ),
      :owner => owner,
      :group => group,
      :pid => value_for_platform(
        ["ubuntu"] => { "default" => "/stunnel4.pid" },
        ["centos", "redhat"] => { "default" => "/stunnel.pid" }
      ),
      :accept => params[:accept],
      :connect => params[:connect]
    )
  end

  # Adding init script for CentOS and Redhat
  template "/etc/init.d/stunnel" do
    source "stunnel.sh.erb"
    cookbook "logging_rsyslog"
    owner "root"
    group "root"
    mode "0755"
    backup false
    variables(
      :daemon => value_for_platform(
        ["centos", "redhat"] => { "5.8" => "\"/usr/sbin/stunnel\"", "default" => "\"/usr/bin/stunnel\"" }
      )
    )
    not_if { node[:platform] == "ubuntu" }
  end

  execute "Enabling stunnel for CentOS and Redhat" do
    command "/sbin/chkconfig --add stunnel"
    not_if { node[:platform] == "ubuntu" }
  end

  execute "Enabling stunnel for Ubuntu" do
    command "ruby -pi -e \"gsub(/ENABLED=0/,'ENABLED=1')\" /etc/default/stunnel4"
    only_if { node[:platform] == "ubuntu" }
  end

  # Enabling stunnel to start on system boot and restarting to apply new settings
  service value_for_platform(
    ["ubuntu"] => { "default" => "stunnel4" },
    ["centos", "redhat"] => { "default" => "stunnel" }
  ) do
    supports :reload => true, :restart => true, :start => true, :stop => true
    action [:enable, :restart]
  end

end
