#
# Cookbook Name:: fedora-openstack-repo
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
# put repogitory file
template "/etc/yum.repos.d/fedora-folsom.repo" do
  source "fedora-folsom.repo.erb"
end

# install fastestmirror and tools
%w{yum-plugin-fastestmirror lvm2 less vim openssh-clients}.each do |package_name|
  package package_name do
    action :install
  end
end
