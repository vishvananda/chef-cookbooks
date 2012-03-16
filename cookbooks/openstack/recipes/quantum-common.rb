#
# Cookbook Name:: openstack
# Recipe:: quantum-common
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

# stuff that needs to be done on both compute and infrastructure nodes

package "quantum-common" do
  action :upgrade
  options "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef' --force-yes"

end

[ "/etc/quantum", "/etc/quantum/plugins", "/etc/quantum/plugins/openvswitch" ]. each do |dir|
  directory dir do
    owner "quantum"
    group "root"
    mode "0750"
  end
end

# the db should already be set up
template "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" do
  source "ovs_quantum_plugin.ini.erb"
  owner "quantum"
  group "root"
  mode "0640"
end


