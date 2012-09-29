#
# Cookbook Name:: folsom-f17
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
template "/etc/yum.repos.d/fedora-folsom.repo" do
  source "fedora-folsom.repo.erb"
end

package "yum-plugin-fastestmirror" do
  action :install
end

%w{qemu-kvm libvirt virt-manager}.each do |package_name|
  package package_name do
    action :install
  end
end

file "/etc/libvirt/qemu/networks/default.xml" do
  action :delete
end

link "/etc/libvirt/qemu/networks/autostart/default.xml" do
  action :delete
end

