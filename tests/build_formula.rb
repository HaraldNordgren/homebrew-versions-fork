require 'fileutils'


start_time = Time.now

package_full_name = ARGV[0]
puts "INSTALLING #{package_full_name}"

cmd_list = []

if file_without_extension =~ /automake/
    cmd_list.push("brew link autoconf")
elsif file_without_extension =~ /influxdb[@]?08|ledger[@]?26|llvm[@]?35|thrift[@]?090|riak[@]?132|rebar[@]?3|rabbitmq[@]?30|erlang/
    cmd_list.push("brew link autoconf automake")
elsif file_without_extension =~ /gdal[@]?111/
    cmd_list.push("brew link autoconf automake")
    cmd_list.push("brew unlink gdal")
elsif file_without_extension =~ /gnupg[@]?21/
    cmd_list.push("brew unlink gnupg2 gpg-agent dirmngr")
elsif file_without_extension =~ /go[@]?15/
    cmd_list.push("brew unlink go")
elsif file_without_extension =~ /jpeg[@]?gb|jpeg[@]?6b/
    cmd_list.push("brew unlink jpeg")
elsif file_without_extension =~ /ruby[@]?192/
    cmd_list.push("brew unlink ruby")
elsif file_without_extension =~ /subversion[@]?18/
    cmd_list.push("brew unlink subversion")
elsif file_without_extension =~ /povray[@]?36/
    cmd_list.push("brew unlink libpng")
elsif file_without_extension =~ /postgresql[@]?[0-9]+/
    cmd_list.push("brew unlink postgresql")
elsif file_without_extension =~ /lz4[@]?r117/
    cmd_list.push("brew unlink lz4")
elsif file_without_extension =~ /appledoc/
    cmd_list.push("brew install gcc")
elsif file_without_extension =~ /duplicity/
    cmd_list.push("pip install testrepository")
elsif file_without_extension =~ /gcc[@]?6/
    cmd_list.push("rm /usr/local/include/c++")
end

cmd_list.push("brew install --verbose #{package_full_name}")
cmd_list.push("echo DONE")


log_file = "#{file_without_extension}.log"
logging_cmds = []
for cmd in cmd_list
    logging_cmds.push("echo [#{cmd}] >> #{log_file}")
    logging_cmds.push("#{cmd} >> #{log_file} 2>&1")

end

concatenated_cmd = logging_cmds.join(" && ")
successful_exit = system(concatenated_cmd)

if successful_exit
    puts "INSTALLED #{file_without_extension} SUCCESSFULLY"
    puts open(log_file) {
        |f| f.grep(/built in/)
    }
    exit 0
else
    puts "FAILED TO INSTALL #{file_without_extension}"
    puts
    puts File.read(log_file)
    exit 1
end
