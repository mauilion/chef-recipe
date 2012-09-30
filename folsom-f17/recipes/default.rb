#
# Cookbook Name:: folsom-f17
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

# install fastestmirror
package "yum-plugin-fastestmirror" do
  action :install
end

# install kvm & libvirt
%w{qemu-kvm libvirt virt-manager}.each do |package_name|
  package package_name do
    action :install
  end
end

# delete default netowrk in libvirt
file "/etc/libvirt/qemu/networks/default.xml" do
  action :delete
end

link "/etc/libvirt/qemu/networks/autostart/default.xml" do
  action :delete
end

# install extra packages
# install kvm & libvirt
%w{openssh-clients}.each do |package_name|
  package package_name do
    action :install
  end
end

# install mysql & qpid
%w{mysql-server qpid-cpp-server}.each do |package_name|
  package package_name do
    action :install
  end
end

# enable & start
%w{mysqld.service qpidd.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end


# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#                          keystone
# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

# create mysql's schema for openstack
script "create_mysql_schema_for_keystone" do
  DONE_FLAG_FILE="init.script.db_user_add.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/keystone/#{DONE_FLAG_FILE}"
  code <<-EOH
     mysql -uroot -e"grant all privileges on keystone.* to keystone@'#{node[:mysql][:access_network]}' identified by '#{node[:mysql][:pass][:keystone]}';"
     mysql -uroot -e"create database keystone;"
     touch /etc/keystone/#{DONE_FLAG_FILE}
  EOH
end

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

# enable & start keystone
service "openstack-keystone.service" do
  provider Chef::Provider::Service::Systemd
  action [:enable, :start]
end

# db_initialize keystone
script "db_initialize_keystone" do
  DONE_FLAG_FILE="init.script.db_sync.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/keystone/#{DONE_FLAG_FILE}"
  code <<-EOH
     export SERVICE_ENDPOINT=http://#{node[:keystone][:identity_api_address][:adminURL]}:35357/v2.0
     export SERVICE_TOKEN=$(grep ^admin_token /etc/keystone/keystone.conf | awk '{ print $NF }')
     keystone-manage db_sync
     touch /etc/keystone/#{DONE_FLAG_FILE}
  EOH
end

# create user, role and tenant in keystone
script "keystone_user_role_tenant_add" do
  DONE_FLAG_FILE="init.script.initial_user_add.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/keystone/#{DONE_FLAG_FILE}"
  code <<-EOH
     export SERVICE_ENDPOINT=http://#{node[:keystone][:identity_api_address][:adminURL]}:35357/v2.0
     export SERVICE_TOKEN=$(grep ^admin_token /etc/keystone/keystone.conf | awk '{ print $NF }')

     function get_id () { echo `"$@" | grep ' id ' | awk '{ print $4 }'`;}

     export ADMIN_PASSWORD="#{node[:keystone][:password][:admin]}"
     export SERVICE_PASSWORD="#{node[:keystone][:password][:service]}"
     export DEMO_PASSWORD="#{node[:keystone][:password][:demo]}"

     export ADMIN_TENANT=$(get_id   keystone tenant-create --name "admin")
     export SERVICE_TENANT=$(get_id keystone tenant-create --name "service")
     export DEMO_TENANT=$(get_id    keystone tenant-create --name "demo")

     export ADMIN_USER=$(get_id   keystone user-create --name "admin"   --pass "$ADMIN_PASSWORD"   --tenant-id "$ADMIN_TENANT"   --email "root@localhost.localdomain")
     export NOVA_USER=$(get_id    keystone user-create --name "nova"    --pass "$SERVICE_PASSWORD" --tenant-id "$SERVICE_TENANT" --email "root@localhost.localdomain")
     export GLANCE_USER=$(get_id  keystone user-create --name "glance"  --pass "$SERVICE_PASSWORD" --tenant-id "$SERVICE_TENANT" --email "root@localhost.localdomain")
     export SWIFT_USER=$(get_id   keystone user-create --name "swift"   --pass "$SERVICE_PASSWORD" --tenant-id "$SERVICE_TENANT" --email "root@localhost.localdomain")
     export CINDER_USER=$(get_id  keystone user-create --name "cinder"  --pass "$SERVICE_PASSWORD" --tenant-id "$SERVICE_TENANT" --email "root@localhost.localdomain")
     export QUANTUM_USER=$(get_id keystone user-create --name "quantum" --pass "$SERVICE_PASSWORD" --tenant-id "$SERVICE_TENANT" --email "root@localhost.localdomain")
     export DEMO_USER=$(get_id    keystone user-create --name "demo"    --pass "$DEMO_PASSWORD"    --tenant-id "$DEMO_TENANT"    --email "root@localhost.localdomain")

     export ADMIN_ROLE=$(get_id           keystone role-create --name "admin")
     export MEMBER_ROLE=$(get_id          keystone role-create --name "Member")
     export KEYSTONEADMIN_ROLE=$(get_id   keystone role-create --name "KeystoneAdmin")
     export KEYSTONESERVICE_ROLE=$(get_id keystone role-create --name "KeystoneServiceAdmin")

     keystone user-role-add --user-id "$ADMIN_USER" --role-id "$ADMIN_ROLE"           --tenant-id "$ADMIN_TENANT"
     keystone user-role-add --user-id "$ADMIN_USER" --role-id "$KEYSTONEADMIN_ROLE"   --tenant-id "$ADMIN_TENANT"
     keystone user-role-add --user-id "$ADMIN_USER" --role-id "$KEYSTONESERVICE_ROLE" --tenant-id "$ADMIN_TENANT"
     keystone user-role-add --user-id "$ADMIN_USER" --role-id "$ADMIN_ROLE"           --tenant-id "$DEMO_TENANT"
     keystone user-role-add --user-id "$DEMO_USER"  --role-id "$MEMBER_ROLE"          --tenant-id "$DEMO_TENANT"

     keystone user-role-add --tenant-id "$SERVICE_TENANT" --role-id "$ADMIN_ROLE" --user-id "$NOVA_USER"
     keystone user-role-add --tenant-id "$SERVICE_TENANT" --role-id "$ADMIN_ROLE" --user-id "$GLANCE_USER"
     keystone user-role-add --tenant-id "$SERVICE_TENANT" --role-id "$ADMIN_ROLE" --user-id "$SWIFT_USER"
     keystone user-role-add --tenant-id "$SERVICE_TENANT" --role-id "$ADMIN_ROLE" --user-id "$QUANTUM_USER"
     keystone user-role-add --tenant-id "$SERVICE_TENANT" --role-id "$ADMIN_ROLE" --user-id "$CINDER_USER"

     keystone ec2-credentials-create --tenant-id "$ADMIN_TENANT" --user-id "$ADMIN_USER"
     keystone ec2-credentials-create --tenant-id "$DEMO_TENANT"  --user-id "$DEMO_USER"

     touch /etc/keystone/#{DONE_FLAG_FILE}
  EOH
end


# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#                            swift
# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

# install swift
%w{openstack-swift-account openstack-swift-container openstack-swift-object openstack-swift-proxy openstack-swift-plugin-swift3 python-swiftclient}.each do |package_name|
  package package_name do
    action :install
  end
end

# install dependency package
%w{memcached xinetd rsync}.each do |package_name|
  package package_name do
    action :install
  end
end

# create swift dir & image_files
script "create_swift_images" do
  DONE_FLAG_FILE="init.script.swift_images.done"

  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/swift/#{DONE_FLAG_FILE}"
  code <<-EOH
     export IMAGE_PATH=#{node[:swift][:data_image_path]}
     export SWIFT_DISK_PATH=#{node[:swift][:device_mount_dir]}

     mkdir -p $IMAGE_PATH
     mkdir -p $SWIFT_DISK_PATH/disk{0..4}

     for i in {0..4}; do dd if=/dev/zero of=$IMAGE_PATH/image$i bs=1024k count=1 seek=2047; done
     for i in {0..4}; do mkfs.ext4 -I 512 -F $IMAGE_PATH/image$i; done
     for i in {0..4}; do echo $IMAGE_PATH/image$i $SWIFT_DISK_PATH/disk$i ext4 defaults,user_xattr 0 0 >> /etc/fstab; done
     for i in {0..4}; do mount $SWIFT_DISK_PATH/disk$i; done

     chown -R swift:swift $SWIFT_DISK_PATH

     touch /etc/swift/#{DONE_FLAG_FILE}

  EOH
end


# enable rsync
script "rsync enable" do
  DONE_FLAG_FILE="init.script.db_sync.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
    sed -i "s/disable\t*= yes/disable = no/g" /etc/xinetd.d/rsync
    sed -i "s/\t*flags\t*= IPv6/#       flags = IPv6/g" /etc/xinetd.d/rsync
  EOH
end

template "/etc/rsyncd.conf" do
  source "rsyncd.conf.erb"
end

# start rsync & memcached
%w{memcached.service xinetd.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :restart]
  end
end

# put conf files
template "/etc/swift/account-server.conf" do
  source "account-server.conf.erb"
  owner "swift"
  group "swift"
end

template "/etc/swift/container-server.conf" do
  source "container-server.conf.erb"
  owner "swift"
  group "swift"
end

template "/etc/swift/object-server.conf" do
  source "object-server.conf.erb"
  owner "swift"
  group "swift"
end

template "/etc/swift/proxy-server.conf" do
  source "proxy-server.conf.erb"
  owner "swift"
  group "swift"
end

template "/etc/swift/swift.conf" do
  source "swift.conf.erb"
  owner "swift"
  group "swift"
end

# create RING
script "create_swift_ring" do
  DONE_FLAG_FILE="init.script.ring.done"

  interpreter "bash"
  user "root"
  cwd "/etc/swift"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/swift/#{DONE_FLAG_FILE}"
  code <<-EOH
     for i in {account,container,object}; do swift-ring-builder $i.builder create 10 3 1; done
     for i in {0..4}; do swift-ring-builder account.builder add z$i-127.0.0.1:6002/disk$i 100; done
     for i in {0..4}; do swift-ring-builder container.builder add z$i-127.0.0.1:6001/disk$i 100; done
     for i in {0..4}; do swift-ring-builder object.builder add z$i-127.0.0.1:6000/disk$i 100; done
     for i in {account,container,object}; do swift-ring-builder $i.builder rebalance; done

     touch /etc/swift/#{DONE_FLAG_FILE}
  EOH
end

# start swift
%w{openstack-swift-account.service openstack-swift-container.service openstack-swift-object.service openstack-swift-proxy.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end
