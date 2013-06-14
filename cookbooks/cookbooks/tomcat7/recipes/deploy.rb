include_recipe "tomcat7"

my_env = node.my_env

if node.my_env == 'production'
 propFilter	= "aol.prod+=true"
elsif node.my_env == 'staging'
 propFilter	= "aol.staging+=true"
end


ruby_block "deploy latest version: #{my_env}" do
 block do
name =  "frockyIII-#{my_env}.war"
fname = "workspace-1.0-SNAPSHOT.war"
base_url   = "http://192.168.1.127:8081/artifactory/cloud-deploy-local/frockyIII/workspace/1.0-SNAPSHOT"
search_url = "http://192.168.1.127:8081/artifactory/cloud-deploy-local/frockyIII/workspace/1.0-SNAPSHOT/#{fname};#{propFilter}"
headers_file = "/tmp/headers.txt"
dest_file = "/tmp/#{name}"

get_headers_cmd = "curl -sI \"#{search_url}\" > #{headers_file}"
%x[ #{get_headers_cmd} ]

last_fname = %x( grep 'X-Artifactory-Filename:' #{headers_file} | awk '{print $2}' ).chomp
last_chks = %x( grep 'X-Checksum-Sha1:' #{headers_file} | awk '{print $2}' ).chomp
cur_chks = %x(sha1sum #{node[:tomcat7][:base]}/webapps/#{name} | awk '{print $1}').chomp

if last_chks == cur_chks
 puts "INFO: No new version was found. Skipping upgrade."
else
download_url = "#{base_url}/#{last_fname}"


puts "INFO: Downloading from Artifactory server #{download_url}"
f = Chef::Resource::RemoteFile.new(dest_file, run_context)
f.source download_url
f.run_action :create
f.retries 3

FileUtils.rm_rf("#{node[:tomcat7][:base]}/webapps/frockyIII-#{my_env}")
FileUtils.cp(dest_file, "#{node[:tomcat7][:base]}/webapps/")
FileUtils.chown 'bt-int', 'bt-int', "#{node[:tomcat7][:base]}/webapps/#{name}"
%x(service tomcat7 restart)
end
 end
 action :create
end

