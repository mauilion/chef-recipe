#
# Cookbook Name:: qpid-cluster
# Recipe:: default
#
# Copyright 2012, Your Company, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
%w{qpid-cpp-server-cluster qpid-tools}.each do |package_name|
  package package_name do
     action :install
  end
end


template "/etc/qpidd.conf" do
   action :create
   owner "root"
   group "root"
   mode  "0644"
end

template "/etc/corosync/corosync.conf" do
   action :create
   owner "root"
   group "root"
   mode  "0644"
end

template "/etc/sysconfig/qpidd" do
   action :create
   owner "root"
   group "root"
   mode  "0644"
end


script "corosync_auto_start_and_start_process" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  export RETVAL=0
  iptables -nvL INPUT |grep "state NEW multiport dports 5404,5405"
  export RETVAL=$?
  if [ $RETVAL != 0 ]; then
     iptables -I INPUT -p udp -m state --state NEW -m multiport --dports 5404,5405 -j ACCEPT
     /etc/init.d/iptables save
  fi
  chkconfig corosync on
  export RETVAL=0
  /etc/init.d/corosync status
  export RETVAL=$?
  if [ $RETVAL != 0 ]; then
     /etc/init.d/corosync start
  else
     /etc/init.d/corosync restart
  fi
  exit $?
  EOH
end

script "qpidd_auto_start_and_start_process" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  export RETVAL=0
  chkconfig qpidd on
  export RETVAL=0
  /etc/init.d/qpidd status
  export RETVAL=$?
  if [ $RETVAL != 0 ]; then
     /etc/init.d/qpidd start
  else
     /etc/init.d/qpidd restart
  fi
  exit $?
  EOH
end
