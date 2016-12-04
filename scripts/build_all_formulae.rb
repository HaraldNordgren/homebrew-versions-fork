require 'fileutils'

author = "haraldnordgren"
tap_short_name = "versions-fork"

tap_dir = "/usr/local/Homebrew/Library/Taps/#{author}/homebrew-#{tap_short_name}"

if ARGV.empty?
    skip_packages = []
else
    skip_packages = ARGV[0].split(" ")
end

#timing_out = [
#    'arangodb2',
#    'bazel02',
    #'boost-python159',
    #'boost155',
    #'boost159',
    #'boost160',
#]
#skip_packages += timing_out

timing_out = [
    /arangodb[0-9]+/,
    /bazel[0-9]+/,
    /boost[0-9]+/,
    /bootst-python[0-9]+/,
    /duplicity06/,
    /erlang-r[0-9]+/,
    /ffmpeg[0-9]+/,
]

debug_skip = true

cmd = ""
for file_name in Dir["#{tap_dir}/*.rb"]
    file_without_extension = File.basename(file_name, File.extname(file_name))

    #if file_without_extension == skip_packages.last
    if file_without_extension == 'ffmpeg28'
        debug_skip = false
    end

    if debug_skip
        puts "SKIPPING AHEAD OVER #{file_without_extension}"
        next
    end

    if skip_packages.include?(file_without_extension)
        puts "SKIPPING #{file_without_extension}"
        next
    end

    matched_regex = false
    for regex in timing_out
        if file_without_extension =~ regex
            puts "SKIPPING #{file_without_extension} after matching #{regex}"
            matched_regex = true
            break
        end
    end

    if matched_regex
        next
    end

    package_full_name = "#{author}/#{tap_short_name}/#{file_without_extension}"
    
    cmd += "echo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% && "
    cmd += "echo && "

    if file_without_extension =~ /automake/
        cmd += "brew link autoconf && "
    elsif file_without_extension =~ /erlang-r[0-9]+/
        cmd += "brew link automake autoconf && "
    end

    cmd += "brew install #{package_full_name} && "
    cmd += "brew unlink #{package_full_name} && "
    cmd += "brew uninstall #{package_full_name} && "
    
    if file_without_extension =~ /automake/
        cmd += "brew unlink autoconf && "
    elsif file_without_extension =~ /erlang-r[0-9]+/
        cmd += "brew unlink automake autoconf && "
    end
end

cmd += "echo ALL BUILDS FINISHED"
successful_exit = system(cmd)

exit successful_exit ? 0 : 1

