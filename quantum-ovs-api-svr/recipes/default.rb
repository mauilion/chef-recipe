#
# Cookbook Name:: quantum-ovs-api-svr
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# install quantum server
%w{openstack-quantum openstack-quantum-openvswitch}.each do |package_name|
  package package_name do
    action :install
  end
end


# put quantum config files
template "/etc/quantum/quantum.conf" do
  source "quantum.conf.erb"
  owner "quantum"
  group "quantum"
end

template "/etc/quantum/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "quantum"
  group "quantum"
end


template "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" do
  source "plugins/openvswitch/ovs_quantum_plugin.ini.erb"
  owner "quantum"
  group "quantum"
end

link "/etc/quantum/plugin.ini" do
  to "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini"
end


script "chown_quantum" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
     chown -R quantum:quantum /var/log/quantum /var/lib/quantum
  EOH
end


# enable & start
%w{quantum-server.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end
