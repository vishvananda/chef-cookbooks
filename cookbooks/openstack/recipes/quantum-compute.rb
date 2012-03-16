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

include_recipe "openstack::quantum-common"

# again, we're assuming openvswitch.  this should really go in a separate cookbook

# we need to find out what kernel we're running so we can get the right headers for dkms

[ "linux-headers-#{`uname -r`.chomp}", "dkms", "openvswitch-datapath-dkms" ].each do |pkg|
  package pkg do
    action :install
    options "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef' --force-yes"
  end
end

# some module hackery, please...
execute "build openvswitch-datapath modules" do
  command "dkms build -m openvswitch -v $(ls -d /usr/src/openvswitch-* | head -n1 | cut -d- -f2)"
  action :run
  not_if "[ -e /var/lib/dkms/openvswitch/$(ls -d /usr/src/openvswitch-* | head -n1 | cut -d- -f2)/$(uname -r)/$(uname -m)/module/openvswitch_mod.ko ]"
end

execute "install openvswitch-datapath modules" do
  command "dkms install -m openvswitch -v $(ls -d /usr/src/openvswitch-* | head -n1 | cut -d- -f2)"
  action :run
  not_if "[ -e /lib/modules/$(uname -r)/updates/dkms/openvswitch_mod.ko ]"
end

execute "modprobe openvswitch-datapath modules" do
  command "modprobe openvswitch_mod"
  action :run
  not_if "lsmod | grep -q \"openvswitch_mod\""
end

[ "openvswitch-switch", "openvswitch-brcompat", "quantum-plugin-openvswitch-agent" ].each do |pkg|
  package pkg do
    action :install
    options "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef' --force-yes"
  end
end

service "quantum-plugin-openvswitch-agent" do
  supports :status => true, :restart => true
  action [:enable, :start]
  subscribes :restart, resources(:template => "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini")
end




