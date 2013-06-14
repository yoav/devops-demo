#
# Cookbook Name:: tomcat7
# Recipe:: default
#
# Copyright 2011,
#
# All rights reserved - Do Not Redistribute
#
include_recipe "java"


tc7ver = node["tomcat7"]["version"]
tc7tarball = "apache-tomcat-#{tc7ver}.tar.gz"
tc7url = node[:tomcat7][:url]
tc7target = node["tomcat7"]["target"]
tc7user = node["tomcat7"]["user"]
tc7group = node["tomcat7"]["group"]

service "iptables" do
  action :stop
end

service "ip6tables" do
  action :stop
end

if File.exists?("#{tc7target}/apache-tomcat-#{tc7ver}/bin")
    return
end


#FileUtils.rm_rf("#{tc7target}/apache-tomcat-#{tc7ver}")
#FileUtils.rm_rf("#{tc7target}/tomcat")

java_args_hash = node['tomcat7']['java_args']

# Build java_args string from hash
java_args = ''
java_args_hash.each do |key, value|
    if value != nil
        java_args = java_args + key + '=' + value + ' '
    else
        java_args = java_args + key + ' '
    end
end

bash "download_tomcat" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  wget --auth-no-challenge --no-check-certificate #{tc7url} -O /tmp/#{tc7tarball}
  checksum=`md5sum -b /tmp/#{tc7tarball} | awk '{print $1}'`
  if [ $checksum != #{node["tarball_checksum"]} ];
  then
    echo "Unexpected download checksum: $checksum"
    exit 1
  fi
  EOH
  #not_if {File.exists?("/tmp/#{tc7tarball}")}
end

# Create group
group "#{tc7group}" do
    action :create
end

# Create user
user "#{tc7user}" do
    comment "Tomcat7 user"
    gid "#{tc7group}"
    home "#{tc7target}"
    shell "/bin/false"
    system true
    action :create
    not_if "grep #{tc7user} /etc/passwd"
end

# Create base folder
directory "#{tc7target}/apache-tomcat-#{tc7ver}" do
    owner "#{tc7user}"
    group "#{tc7group}"
    mode "0755"
    action :create
end

# Create PID folder
directory "/var/run/tomcat" do
    owner "#{tc7user}"
    group "#{tc7group}"
    mode "0755"
    action :create
end

# Create TMP folder
directory "/data/tomcat/temp" do
    owner "#{tc7user}"
    group "#{tc7group}"
    mode "0755"
    action :create
    recursive true 
end

# Extract
execute "tar" do
    user "#{tc7user}"
    group "#{tc7group}"
    installation_dir = "#{tc7target}"
    cwd installation_dir
    command "tar zxf /tmp/#{tc7tarball}"
    action :run
end

# Set the symlink
link "#{tc7target}/tomcat" do
    to "apache-tomcat-#{tc7ver}"
    link_type :symbolic
end

# Set the symlink to TMP directory
execute "remove temp folder" do
    command "/bin/rm -rf #{tc7target}/apache-tomcat-#{tc7ver}/temp"
    action :run
end
link "#{tc7target}/apache-tomcat-#{tc7ver}/temp" do
    to "/data/tomcat/temp"
    link_type :symbolic
end

# Add the init-script
case node["platform"]
when "debian","ubuntu"
    template "/etc/init.d/tomcat7" do
		source "init-debian.erb"
		owner "root"
		group "root"
		mode "0755"
    end
	execute "init-deb" do
		user "root"
		group "root"
		command "update-rc.d tomcat7 defaults"
		action :run
    end
else
    template "/etc/init.d/tomcat7" do
		source "init-rh.erb"
        variables ({:args => java_args})
		owner "root"
		group "root"
		mode "0755"
    end
    execute "init-rh" do
		user "root"
		group "root"
		command "chkconfig --add tomcat7"
		action :run
    end
end

# Config from template
template "#{tc7target}/tomcat/conf/server.xml" do
    source "server.xml.erb"
    owner "#{tc7user}"
    group "#{tc7group}"
    mode "0644"
end

# Start service
service "tomcat7" do
    service_name "tomcat7"
    action :start
end
