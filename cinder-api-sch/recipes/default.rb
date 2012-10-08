#
# Cookbook Name:: cinder-api-sch
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# install cinder
package "openstack-cinder" do
  action :install
end

# bug
file "/etc/tgt/conf.d/cinder.conf" do
  action :delete
end

# put glance's config files
template "/etc/cinder/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "cinder"
  group "cinder"
end

# put glance's config files
template "/etc/cinder/cinder.conf" do
  source "cinder.conf.erb"
  owner "cinder"
  group "cinder"
end


# db_initialize cinder
script "db_initialize_cinder" do
  DONE_FLAG_FILE="/etc/cinder/chef.script.db_sync.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "#{DONE_FLAG_FILE}"
  code <<-EOH
     cinder-manage db sync
     touch #{DONE_FLAG_FILE}
  EOH
end


script "chown_cinder" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
     chown -R cinder:cinder /var/log/cinder /var/lib/cinder
  EOH
end


# disable tgtd
%w{tgtd.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:stop, :disable]
  end
end


# enable & start cinder
%w{openstack-cinder-api.service openstack-cinder-scheduler.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end

