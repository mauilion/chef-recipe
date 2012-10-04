#
# Cookbook Name:: folsom-f17
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# disable iptables & selinux
script "disable_iptables_and_selinux" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  code <<-EOH
     systemctl stop iptables.service
     systemctl disable iptables.service
     systemctl stop ip6tables.service
     systemctl disable ip6tables.service
     setenforce 0
     sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
  EOH
end


# put repogitory file
template "/etc/yum.repos.d/fedora-folsom.repo" do
  source "fedora-folsom.repo.erb"
end

# install fastestmirror
%w{yum-plugin-fastestmirror lvm2 less vim euca2ools }.each do |package_name|
  package package_name do
    action :install
  end
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

# install keystone
package "openstack-keystone" do
  action :install
end


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

# put keystone's config files
template "/etc/keystone/keystone.conf" do
  source "keystone/keystone.conf.erb"
  owner "keystone"
  group "keystone"
end

template "/etc/keystone/default_catalog.templates" do
  source "keystone/default_catalog.templates.erb"
  owner "keystone"
  group "keystone"
end

template "/etc/keystone/logging.conf" do
  source "keystone/logging.conf.erb"
  owner "keystone"
  group "keystone"
end

script "chown_keystone" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
     chown -R keystone:keystone /var/log/keystone
  EOH
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
  source "swift/rsyncd.conf.erb"
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
  source "swift/account-server.conf.erb"
  owner "swift"
  group "swift"
end

template "/etc/swift/container-server.conf" do
  source "swift/container-server.conf.erb"
  owner "swift"
  group "swift"
end

template "/etc/swift/object-server.conf" do
  source "swift/object-server.conf.erb"
  owner "swift"
  group "swift"
end

template "/etc/swift/proxy-server.conf" do
  source "swift/proxy-server.conf.erb"
  owner "swift"
  group "swift"
end

template "/etc/swift/swift.conf" do
  source "swift/swift.conf.erb"
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


# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#                            glance
# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

# install glance
package "openstack-glance" do
  action :install
end

# create mysql's schema for glance
script "create_mysql_schema_for_glance" do
  DONE_FLAG_FILE="init.script.db_user_add.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/glance/#{DONE_FLAG_FILE}"
  code <<-EOH
     mysql -uroot -e"grant all privileges on glance.* to glance@'#{node[:mysql][:access_network]}' identified by '#{node[:mysql][:pass][:glance]}';"
     mysql -uroot -e"create database glance;"
     touch /etc/glance/#{DONE_FLAG_FILE}
  EOH
end


# put glance's config files
template "/etc/glance/glance-api.conf" do
  source "glance/glance-api.conf.erb"
  owner "glance"
  group "glance"
end

template "/etc/glance/glance-api-paste.ini" do
  source "glance/glance-api-paste.ini.erb"
  owner "glance"
  group "glance"
end


# put glance's config files
template "/etc/glance/glance-registry.conf" do
  source "glance/glance-registry.conf.erb"
  owner "glance"
  group "glance"
end

template "/etc/glance/glance-registry-paste.ini" do
  source "glance/glance-registry-paste.ini.erb"
  owner "glance"
  group "glance"
end

# db_initialize glance
script "db_initialize_cinder" do
  DONE_FLAG_FILE="init.script.db_sync.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/glance/#{DONE_FLAG_FILE}"
  code <<-EOH
     glance-manage db_sync
     touch /etc/glance/#{DONE_FLAG_FILE}
  EOH
end

script "chown_glance" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
     chown -R glance:glance /var/log/glance /var/lib/glance
  EOH
end


# enable & start glance
%w{openstack-glance-api.service openstack-glance-registry.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end




# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#                            cinder
# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

# install cinder
package "openstack-cinder" do
  action :install
end

# create mysql's schema for cinder
script "create_mysql_schema_for_cinder" do
  DONE_FLAG_FILE="init.script.db_user_add.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/cinder/#{DONE_FLAG_FILE}"
  code <<-EOH
     mysql -uroot -e"grant all privileges on cinder.* to cinder@'#{node[:mysql][:access_network]}' identified by '#{node[:mysql][:pass][:cinder]}';"
     mysql -uroot -e"create database cinder;"

     touch /etc/cinder/#{DONE_FLAG_FILE}
  EOH
end


# put glance's config files
template "/etc/cinder/api-paste.ini" do
  source "cinder/api-paste.ini.erb"
  owner "cinder"
  group "cinder"
end

# put glance's config files
template "/etc/cinder/cinder.conf" do
  source "cinder/cinder.conf.erb"
  owner "cinder"
  group "cinder"
end

# db_initialize cinder
script "db_initialize_cinder" do
  DONE_FLAG_FILE="init.script.db_sync.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/cinder/#{DONE_FLAG_FILE}"
  code <<-EOH
     cinder-manage db sync
     touch /etc/cinder/#{DONE_FLAG_FILE}
  EOH
end

script "chown_cinder" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
     chown -R cinder:cinder /var/log/cinder /var/lib/cinder
  EOH
end

file "/etc/tgt/conf.d/cinder.conf" do
  action :delete
end

script "cinder_tgtd_bug_fix" do
  DONE_FLAG_FILE="init.script.bug_fix.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  creates "/etc/cinder/#{DONE_FLAG_FILE}"
  code <<-EOH
     sed -i '1iinclude /etc/cinder/volumes/*' /etc/tgt/targets.conf
     touch /etc/cinder/#{DONE_FLAG_FILE}
  EOH
end


%w{tgtd.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end


# enable & start cinder
%w{openstack-cinder-api.service openstack-cinder-scheduler.service openstack-cinder-volume.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :start]
  end
end


# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#                            nova
# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

# install nova
package "openstack-nova" do
  action :install
end

file "/etc/tgt/conf.d/nova.conf" do
  action :delete
end

# create mysql's schema for nova
script "create_mysql_schema_for_nova" do
  DONE_FLAG_FILE="init.script.db_user_add.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/nova/#{DONE_FLAG_FILE}"
  code <<-EOH
     mysql -uroot -e"grant all privileges on nova.* to nova@'#{node[:mysql][:access_network]}' identified by '#{node[:mysql][:pass][:nova]}';"
     mysql -uroot -e"create database nova;"

     touch /etc/nova/#{DONE_FLAG_FILE}
  EOH
end

# put nova's config files
template "/etc/nova/api-paste.ini" do
  source "nova/api-paste.ini.erb"
  owner "nova"
  group "nova"
end

template "/etc/nova/nova.conf" do
  source "nova/nova.conf.erb"
  owner "nova"
  group "nova"
end

# db_initialize nova
script "db_initialize_nova" do
  DONE_FLAG_FILE="init.script.db_sync.done"
  interpreter "bash"
  user "root"
  cwd "/tmp"
  # this file is flag. if the file exist, the following script dont run.
  creates "/etc/nova/#{DONE_FLAG_FILE}"
  code <<-EOH
     nova-manage db sync
     touch /etc/nova/#{DONE_FLAG_FILE}
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


%w{libvirt-guests.service libvirtd.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :restart]
  end
end


# enable & start nova
%w{openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-cert.service openstack-nova-console.service openstack-nova-consoleauth.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :restart]
  end
end

%w{openstack-nova-compute.service openstack-nova-network.service openstack-nova-xvpvncproxy.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :restart]
  end
end


# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#                            horizon
# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

# install horizon
package "httpd" do
  action :install
end

%w{openstack-dashboard python-django-horizon}.each do |package_name|
  package package_name do
    action :install
  end
end

template "/etc/openstack-dashboard/local_settings" do
  source "horizon/local_settings.erb"
  owner "root"
  group "root"
  mode  "0644"
end

# start httpd
%w{httpd.service}.each do |service_name|
  service service_name do
    provider Chef::Provider::Service::Systemd
    action [:enable, :restart]
  end
end



# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#                            quantum
# _/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

