require 'fileutils'


package_full_name = ARGV[0]
puts "INSTALLING #{package_full_name}"

cmd_list = []
cmd_list.push("brew install --verbose #{package_full_name}")
cmd_list.push("echo DONE")

log_file = "#{File.basename(package_full_name)}.log"
logging_cmds = []
for cmd in cmd_list
    logging_cmds.push("echo [#{cmd}] >> #{log_file}")
    logging_cmds.push("#{cmd} >> #{log_file} 2>&1")
end

concatenated_cmd = logging_cmds.join(" && ")
successful_exit = system(concatenated_cmd)

if successful_exit
    puts "INSTALLED #{package_full_name} SUCCESSFULLY"
    puts open(log_file) {
        |f| f.grep(/built in/)
    }
    exit 0
end

puts "FAILED TO INSTALL #{package_full_name}"
puts

log_output = File.read(log_file)

if log_output.grep(Regexp.quote("https://git.io/brew-troubleshooting")).size > 0
    system("brew gist-logs #{package_full_name}")
end

puts log_output
exit 1
