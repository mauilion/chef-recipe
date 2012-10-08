#
# Cookbook Name:: disable-iptables-selinux
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

script "disable__selinux" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
     setenforce 0
     sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
  EOH
end

# enable & start
%w{
iptables.service
ip6tables.service
}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:stop, :disable]
  end
end
