#
# Cookbook Name:: openstack
# Recipe:: quantum-server
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

include_recipe "openstack::apt"
include_recipe "openstack::mysql"
include_recipe "openstack::quantum-common"

# we should really have an attribute for the plugin we are using, not just openvswitch
%w(quantum-server quantum-pythonclient quantum-plugin-openvswitch).each do |pkg|
  package pkg do
    action :upgrade
    options "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef' --force-yes"
  end
end

# again, componentize the plugin
template "/etc/quantum/plugins.ini" do
  source "quantum-plugins.ini.erb"
  owner "quantum"
  group "root"
  mode "0640"
end

service "quantum-server" do
  supports :status => true, :restart => true
  action [ :enable, :start ]
  subscribes :restart, resources(:template => "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini")
  subscribes :restart, resources(:template => "/etc/quantum/plugins.ini")
end





