#
# Cookbook Name:: mysql-single
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# install mysql
%w{mysql-server}.each do |package_name|
  package package_name do
    action :install
  end
end


# put my.cnf
template "/etc/my.cnf" do
  source "my.cnf.erb"
  owner "root"
  group "root"
end


# enable & start
%w{mysqld.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end
