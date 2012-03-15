#
# Cookbook Name:: memcache
# Recipe:: default
#
# Copyright 2009, Example Com
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

include_recipe "mysql::client"

connection_info = {:host => node[:controller_ip], :username => "root", :password => node['mysql']['server_root_password']}
mysql_database "create glance database" do
  connection connection_info
  database_name node[:glance][:db]
  action :create
end

mysql_database_user node[:glance][:db_user] do
  connection connection_info
  password node[:glance][:db_passwd]
  action :create
end

mysql_database_user node[:glance][:db_user] do
  connection connection_info
  password node[:glance][:db_passwd]
  database_name node[:glance][:db]
  host '%'
  privileges [:all]
  action :grant 
end

package "curl" do
  action :install
end

package "python-mysqldb" do
  action :install
end

# Supposedly Resolved
# Fixes issue https://bugs.launchpad.net/ubuntu/+source/glance/+bug/943748
#package "python-dateutil" do
#  action :install
#end

package "glance" do
  action :upgrade
end

service "glance-registry" do
  supports :status => true, :restart => true
  action :enable
end

execute "glance-manage db_sync" do
        command "glance-manage db_sync"
        action :nothing
        notifies :restart, resources(:service => "glance-registry"), :immediately
end

file "/var/lib/glance/glance.sqlite" do
    action :delete
end

# Register Service Tenant
keystone_register "Register Service Tenant" do
  auth_host node[:controller_ipaddress]
  auth_port node[:keystone][:admin_port]
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token node[:keystone][:admin_token]
  tenant_name node[:glance][:service_tenant_name]
  tenant_description "Service Tenant"
  tenant_enabled "true" # Not required as this is the default
  action :create_tenant
end

# Register Service User
keystone_register "Register Service User" do
  auth_host node[:controller_ipaddress]
  auth_port node[:keystone][:admin_port]
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token node[:keystone][:admin_token]
  tenant_name node[:glance][:service_tenant_name]
  user_name node[:glance][:service_user]
  user_pass node[:glance][:service_pass]
  user_enabled "true" # Not required as this is the default
  action :create_user
end

## Grant Admin role to Service User for Service Tenant ##
keystone_register "Grant 'admin' Role to Service User for Service Tenant" do
  auth_host node[:controller_ipaddress]
  auth_port node[:keystone][:admin_port]
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token node[:keystone][:admin_token]
  tenant_name node[:glance][:service_tenant_name]
  user_name node[:glance][:service_user]
  role_name node[:glance][:service_role]
  action :grant_role
end

template "/etc/glance/glance-registry.conf" do
  source "glance-registry.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :registry_port => node[:glance][:registry_port],
    :user => node[:glance][:db_user],
    :passwd => node[:glance][:db_passwd],
    :ip_address => node[:controller_ipaddress],
    :db_name => node[:glance][:db],
    :service_port => node[:keystone][:service_port],
    :admin_port => node[:keystone][:admin_port],
    :admin_token => node[:keystone][:admin_token],
    :service_tenant_name => node[:glance][:service_tenant_name],
    :service_user => node[:glance][:service_user],
    :service_pass => node[:glance][:service_pass]
  )
  notifies :run, resources(:execute => "glance-manage db_sync"), :immediately
end

template "/etc/glance/glance-registry-paste.ini" do
  source "glance-registry-paste.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :ip_address => node[:controller_ipaddress],
    :service_port => node[:keystone][:service_port],
    :admin_port => node[:keystone][:admin_port],
    :admin_token => node[:keystone][:admin_token],
    :service_tenant_name => node[:glance][:service_tenant_name],
    :service_user => node[:glance][:service_user],
    :service_pass => node[:glance][:service_pass]
  )
  notifies :restart, resources(:service => "glance-registry"), :immediately
end