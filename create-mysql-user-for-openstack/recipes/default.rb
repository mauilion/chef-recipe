#
# Cookbook Name:: create-mysql-user-for-openstack
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# create database for openstack
script "create_mysql_schema" do
  DONE_FLAG_FILE="/etc/chef.script.create_database.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "#{DONE_FLAG_FILE}"
  code <<-EOH
     mysql -uroot -e"drop   database keystone;"
     mysql -uroot -e"create database keystone;"
     mysql -uroot -e"drop   database glance;"
     mysql -uroot -e"create database glance;"
     mysql -uroot -e"drop   database nova;"
     mysql -uroot -e"create database nova;"
     mysql -uroot -e"drop   database cinder;"
     mysql -uroot -e"create database cinder;"
     mysql -uroot -e"drop   database quantum;"
     mysql -uroot -e"create database quantum;"
     touch #{DONE_FLAG_FILE}
  EOH
end


# create database for openstack
script "grant_user_to_mysql" do
  DONE_FLAG_FILE="/etc/chef.script.grant_user.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "#{DONE_FLAG_FILE}"
  code <<-EOH
     mysql -uroot -e"grant all privileges on keystone.* to keystone@'#{node[:mysql][:access_network]}' identified by '#{node[:mysql][:pass][:keystone]}';"
     mysql -uroot -e"grant all privileges on   glance.* to   glance@'#{node[:mysql][:access_network]}' identified by '#{node[:mysql][:pass][:glance]}';"
     mysql -uroot -e"grant all privileges on     nova.* to     nova@'#{node[:mysql][:access_network]}' identified by '#{node[:mysql][:pass][:nova]}';"
     mysql -uroot -e"grant all privileges on   cinder.* to   cinder@'#{node[:mysql][:access_network]}' identified by '#{node[:mysql][:pass][:cinder]}';"
     mysql -uroot -e"grant all privileges on  quantum.* to  quantum@'#{node[:mysql][:access_network]}' identified by '#{node[:mysql][:pass][:quantum]}';"
     mysql -uroot -e"grant all privileges on keystone.* to keystone@'localhost' identified by '#{node[:mysql][:pass][:keystone]}';"
     mysql -uroot -e"grant all privileges on   glance.* to   glance@'localhost' identified by '#{node[:mysql][:pass][:glance]}';"
     mysql -uroot -e"grant all privileges on     nova.* to     nova@'localhost' identified by '#{node[:mysql][:pass][:nova]}';"
     mysql -uroot -e"grant all privileges on   cinder.* to   cinder@'localhost' identified by '#{node[:mysql][:pass][:cinder]}';"
     mysql -uroot -e"grant all privileges on  quantum.* to  quantum@'localhost' identified by '#{node[:mysql][:pass][:quantum]}';"
     mysql -uroot -e"grant all privileges on keystone.* to keystone@'127.0.0.1' identified by '#{node[:mysql][:pass][:keystone]}';"
     mysql -uroot -e"grant all privileges on   glance.* to   glance@'127.0.0.1' identified by '#{node[:mysql][:pass][:glance]}';"
     mysql -uroot -e"grant all privileges on     nova.* to     nova@'127.0.0.1' identified by '#{node[:mysql][:pass][:nova]}';"
     mysql -uroot -e"grant all privileges on   cinder.* to   cinder@'127.0.0.1' identified by '#{node[:mysql][:pass][:cinder]}';"
     mysql -uroot -e"grant all privileges on  quantum.* to  quantum@'127.0.0.1' identified by '#{node[:mysql][:pass][:quantum]}';"
     mysql -uroot -e "select user,host,password from mysql.user order by user,host;"
     touch #{DONE_FLAG_FILE}
  EOH
end

