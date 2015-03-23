#
# Cookbook Name:: golang
# Recipe:: default
#
# Copyright 2013, Alexander Rozhnov
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#

bash "install-golang" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    rm -rf go
    rm -rf #{node['go']['install_dir']}/go
    tar -C #{node['go']['install_dir']} -xzf #{node["go"]["filename"]}
  EOH
  action :nothing
end

remote_file File.join(Chef::Config[:file_cache_path], node['go']['filename']) do
  source node['go']['url']
  owner 'root'
  mode 0644
  notifies :run, 'bash[install-golang]', :immediately
  not_if "#{node['go']['install_dir']}/go/bin/go version | grep \"go#{node['go']['version']} \""
end

directory node['go']['gopath'] do
  action :create
  recursive true
  owner node['go']['owner']
  group node['go']['group']
  mode node['go']['mode']
end

directory node['go']['gobin'] do
  action :create
  recursive true
  owner node['go']['owner']
  group node['go']['group']
  mode node['go']['mode']
end

if node['go']['systemwide'] 
    envfile = Chef::Util::FileEdit.initialize("/etc/environment")
    envfile.insert_line_if_no_match(/^GOPATH/, "GOPATH=<%= node['go']['gopath'] %>")
    envfile.insert_line_if_no_match(/^GOBIN/, "GOBIN=<%= node['go']['gobin'] %>")    
    envfile.insert_line_if_no_match(/\/go\/bin/, "PATH=$PATH:<%= node['go']['install_dir'] %>/go/bin:<%= node['go']['gobin'] %>")
    envfile.write_file
else
    template "/etc/profile.d/golang.sh" do
      source "golang.sh.erb"
      owner 'root'
      group 'root'
      mode 0755
    end
end

if node['go']['scm']
  %w(git mercurial bzr).each do |scm|
    package scm
  end
end
