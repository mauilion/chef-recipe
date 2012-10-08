#
# Cookbook Name:: keystone
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# install keystone
package "openstack-keystone" do
  action :install
end

# put keystone's config files
template "/etc/keystone/keystone.conf" do
  source "keystone.conf.erb"
  owner "keystone"
  group "keystone"
end

template "/etc/keystone/default_catalog.templates" do
  source "default_catalog.templates.erb"
  owner "keystone"
  group "keystone"
end

template "/etc/keystone/logging.conf" do
  source "logging.conf.erb"
  owner "keystone"
  group "keystone"
end

script "chown_keystone" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
     mkdir -p /var/log/keystone
     chown -R keystone:keystone /var/log/keystone
  EOH
end


# db_initialize keystone
script "db_initialize_keystone" do
  DONE_FLAG_FILE="/etc/keystone/chef.script.db_sync.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "#{DONE_FLAG_FILE}"
  code <<-EOH
     touch #{DONE_FLAG_FILE}
     keystone-manage db_sync
  EOH
end


# enable & start keystone
service "openstack-keystone.service" do
  provider Chef::Provider::Service::Systemd
  action [:enable, :start]
end


# create user, role and tenant in keystone
script "keystone_user_role_tenant_add" do
  DONE_FLAG_FILE="/etc/keystone/chef.script.initial_user_add.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "#{DONE_FLAG_FILE}"
  code <<-EOH
     export SERVICE_ENDPOINT="http://#{node[:keystone][:identity_api_address][:adminURL]}:35357/v2.0"
     export SERVICE_TOKEN="#{node[:keystone][:admin_token]}"

     function get_id () { echo `"$@" | grep ' id ' | awk '{ print $4 }'`;}

     export USER_ADMIN="#{node[:keystone][:user][:admin][:name]}"
     export USER_NOVA="#{node[:keystone][:user][:nova][:name]}"
     export USER_GLANCE="#{node[:keystone][:user][:glance][:name]}"
     export USER_SWIFT="#{node[:keystone][:user][:swift][:name]}"
     export USER_CINDER="#{node[:keystone][:user][:cinder][:name]}"
     export USER_QUANTUM="#{node[:keystone][:user][:quantum][:name]}"
     export USER_DEMO="#{node[:keystone][:user][:demo][:name]}"

     export PASS_ADMIN="#{node[:keystone][:user][:admin][:pass]}"
     export PASS_NOVA="#{node[:keystone][:user][:nova][:pass]}"
     export PASS_GLANCE="#{node[:keystone][:user][:glance][:pass]}"
     export PASS_SWIFT="#{node[:keystone][:user][:swift][:pass]}"
     export PASS_CINDER="#{node[:keystone][:user][:cinder][:pass]}"
     export PASS_QUANTUM="#{node[:keystone][:user][:quantum][:pass]}"
     export PASS_DEMO="#{node[:keystone][:user][:demo][:pass]}"

     export TENANT_ADMIN="#{node[:keystone][:tenant][:admin][:name]}"
     export TENANT_SERVICE="#{node[:keystone][:tenant][:service][:name]}"
     export TENANT_DEMO="#{node[:keystone][:tenant][:demo][:name]}"

     export UUID_ADMIN_TENANT=$(get_id   keystone tenant-create --name "$TENANT_ADMIN")
     export UUID_SERVICE_TENANT=$(get_id keystone tenant-create --name "$TENANT_SERVICE")
     export UUID_DEMO_TENANT=$(get_id    keystone tenant-create --name "$TENANT_DEMO")

     export UUID_ADMIN_USER=$(get_id   keystone user-create --name "$USER_ADMIN"   --pass "$PASS_ADMIN"   --tenant-id "$UUID_ADMIN_TENANT"   --email "root@localhost.localdomain")
     export UUID_NOVA_USER=$(get_id    keystone user-create --name "$USER_NOVA"    --pass "$PASS_NOVA"    --tenant-id "$UUID_SERVICE_TENANT" --email "root@localhost.localdomain")
     export UUID_GLANCE_USER=$(get_id  keystone user-create --name "$USER_GLANCE"  --pass "$PASS_GLANCE"  --tenant-id "$UUID_SERVICE_TENANT" --email "root@localhost.localdomain")
     export UUID_SWIFT_USER=$(get_id   keystone user-create --name "$USER_SWIFT"   --pass "$PASS_SWIFT"   --tenant-id "$UUID_SERVICE_TENANT" --email "root@localhost.localdomain")
     export UUID_CINDER_USER=$(get_id  keystone user-create --name "$USER_CINDER"  --pass "$PASS_CINDER"  --tenant-id "$UUID_SERVICE_TENANT" --email "root@localhost.localdomain")
     export UUID_QUANTUM_USER=$(get_id keystone user-create --name "$USER_QUANTUM" --pass "$PASS_QUANTUM" --tenant-id "$UUID_SERVICE_TENANT" --email "root@localhost.localdomain")
     export UUID_DEMO_USER=$(get_id    keystone user-create --name "$USER_DEMO"    --pass "$PASS_DEMO"    --tenant-id "$UUID_DEMO_TENANT"    --email "root@localhost.localdomain")

     export UUID_ADMIN_ROLE=$(get_id           keystone role-create --name "admin")
     export UUID_MEMBER_ROLE=$(get_id          keystone role-create --name "Member")
     export UUID_KEYSTONEADMIN_ROLE=$(get_id   keystone role-create --name "KeystoneAdmin")
     export UUID_KEYSTONESERVICE_ROLE=$(get_id keystone role-create --name "KeystoneServiceAdmin")

     keystone user-role-add --user-id "$UUID_ADMIN_USER" --role-id "$UUID_ADMIN_ROLE"           --tenant-id "$UUID_ADMIN_TENANT"
     keystone user-role-add --user-id "$UUID_ADMIN_USER" --role-id "$UUID_KEYSTONEADMIN_ROLE"   --tenant-id "$UUID_ADMIN_TENANT"
     keystone user-role-add --user-id "$UUID_ADMIN_USER" --role-id "$UUID_KEYSTONESERVICE_ROLE" --tenant-id "$UUID_ADMIN_TENANT"
     keystone user-role-add --user-id "$UUID_ADMIN_USER" --role-id "$UUID_ADMIN_ROLE"           --tenant-id "$UUID_DEMO_TENANT"
     keystone user-role-add --user-id "$UUID_DEMO_USER"  --role-id "$UUID_MEMBER_ROLE"          --tenant-id "$UUID_DEMO_TENANT"

     keystone user-role-add --tenant-id "$UUID_SERVICE_TENANT" --role-id "$UUID_ADMIN_ROLE" --user-id "$UUID_NOVA_USER"
     keystone user-role-add --tenant-id "$UUID_SERVICE_TENANT" --role-id "$UUID_ADMIN_ROLE" --user-id "$UUID_GLANCE_USER"
     keystone user-role-add --tenant-id "$UUID_SERVICE_TENANT" --role-id "$UUID_ADMIN_ROLE" --user-id "$UUID_SWIFT_USER"
     keystone user-role-add --tenant-id "$UUID_SERVICE_TENANT" --role-id "$UUID_ADMIN_ROLE" --user-id "$UUID_QUANTUM_USER"
     keystone user-role-add --tenant-id "$UUID_SERVICE_TENANT" --role-id "$UUID_ADMIN_ROLE" --user-id "$UUID_CINDER_USER"

     keystone ec2-credentials-create --tenant-id "$UUID_ADMIN_TENANT" --user-id "$UUID_ADMIN_USER"
     keystone ec2-credentials-create --tenant-id "$UUID_DEMO_TENANT"  --user-id "$UUID_DEMO_USER"

     touch #{DONE_FLAG_FILE}

     keystone tenant-list
     keystone user-list
     keystone role-list
  EOH
end
