#
# Cookbook Name:: horizon
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# install horizon
package "httpd" do
  action :install
end

%w{openstack-dashboard python-django-horizon}.each do |package_name|
  package package_name do
    action :install
  end
end

template "/etc/openstack-dashboard/local_settings" do
  source "local_settings.erb"
  owner "root"
  group "root"
  mode  "0644"
end

# start httpd
%w{httpd.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :restart]
  end
end
