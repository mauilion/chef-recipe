#
# Cookbook Name:: qpid-single
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# install qpid
%w{qpid-cpp-server qpid-tools}.each do |package_name|
  package package_name do
    action :install
  end
end

# enable & start
%w{qpidd.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end
