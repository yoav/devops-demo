#
# Cookbook Name:: tomcat7
# Attributes:: default
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default[:tomcat7][:version] = "7.0.37"
default[:tomcat7][:user] = "bt-int"
default[:tomcat7][:group] = "bt-int"
default[:tomcat7][:target] = "/usr/share"
default[:tomcat7][:port] = 8080
default[:tomcat7][:ssl_port] = 8443
default[:tomcat7][:ajp_port] = 8009
default['tomcat7']['java_args'] = {'-Xmx512M'=>nil, '-Dajva.awt.headless'=>'true', '-Dgrails.env'=>'dev', '-XX:MaxPermSize'=>'256M', '-XX:+UseG1GC'=>nil, '-XX:MaxGCPauseMillis'=>'1000'}
default[:tomcat7][:use_security_manager] = "no"
default["tarball_checksum"] = "1f65e0806cc2a3fc7a93017ef2252b76"
default["aprtarball_checksum"] = "ed350524d7b18e02853f97727bff9c976aaab53fa1a491e317ee729b42a3d605"

##
set[:tomcat7][:url]  = "http://192.168.1.127 :8081/artifactory/devops-repo/tomcat/apache-tomcat-#{node[:tomcat7][:version]}.tar.gz"
set[:tomcat7][:home] = "#{tomcat7['target']}/tomcat"
set[:tomcat7][:base] = "#{tomcat7['target']}/tomcat"
set[:tomcat7][:config_dir] = "#{tomcat7['target']}/tomcat/conf"
set[:tomcat7][:log_dir] = "#{tomcat7['target']}/tomcat/logs"
set[:logrotate][:services] = "tomcat"
