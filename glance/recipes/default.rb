#
# Cookbook Name:: glance
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# install glance
package "openstack-glance" do
  action :install
end


# put glance's config files
template "/etc/glance/glance-api.conf" do
  source "glance-api.conf.erb"
  owner "glance"
  group "glance"
end

template "/etc/glance/glance-api-paste.ini" do
  source "glance-api-paste.ini.erb"
  owner "glance"
  group "glance"
end


# put glance's config files
template "/etc/glance/glance-registry.conf" do
  source "glance-registry.conf.erb"
  owner "glance"
  group "glance"
end

template "/etc/glance/glance-registry-paste.ini" do
  source "glance-registry-paste.ini.erb"
  owner "glance"
  group "glance"
end


# db_initialize glance
script "db_initialize_glance" do
  DONE_FLAG_FILE="/etc/glance/chef.script.db_sync.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "#{DONE_FLAG_FILE}"
  code <<-EOH
     glance-manage db_sync
     touch #{DONE_FLAG_FILE}
  EOH
end


script "chown_glance" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
     chown -R glance:glance /var/log/glance /var/lib/glance
  EOH
end


# enable & start glance
%w{openstack-glance-api.service openstack-glance-registry.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end

