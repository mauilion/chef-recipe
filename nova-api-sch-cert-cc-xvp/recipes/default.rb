#
# Cookbook Name:: nova-api-sch-cert-cc-xvp
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# install nova
package "openstack-nova" do
  action :install
end

file "/etc/tgt/conf.d/nova.conf" do
  action :delete
end

# delete default netowrk in libvirt
file "/etc/libvirt/qemu/networks/default.xml" do
  action :delete
end

link "/etc/libvirt/qemu/networks/autostart/default.xml" do
  action :delete
end


# put nova's config files
template "/etc/nova/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "nova"
  group "nova"
end

template "/etc/nova/nova.conf" do
  source "nova.conf.erb"
  owner "nova"
  group "nova"
end


# db_initialize nova
script "db_initialize_nova" do
  DONE_FLAG_FILE="/etc/nova/chef.script.db_sync.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "#{DONE_FLAG_FILE}"
  code <<-EOH
     nova-manage db sync
     touch #{DONE_FLAG_FILE}
  EOH
end

script "chown_nova" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
     chown -R nova:nova /var/log/nova /var/lib/nova
  EOH
end


# enable & start nova
%w{openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-cert.service openstack-nova-console.service openstack-nova-consoleauth.service openstack-nova-xvpvncproxy.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end

