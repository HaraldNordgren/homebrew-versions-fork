require 'fileutils'


start_time = Time.now

REPO_SLUG = ENV['TRAVIS_REPO_SLUG']
puts "REPO_SLUG: #{REPO_SLUG}"
repo_author, repo_name = REPO_SLUG.split("/")

tap_short_name = 'versions'

skip_packages_string = ARGV[0]

if repo_name == 'homebrew-versions-reference'
    tap_author = 'homebrew'
    tap_dir = "/usr/local/Homebrew/Library/Taps/#{tap_author}/homebrew-#{tap_short_name}"
    puts tap_dir

    skip_packages_string = ARGV[0].gsub("-@", "-").gsub("@", "")
    formula_glob = "#{tap_dir}/*.rb"
    shorten_formula = lambda { |file_name|
        return File.basename(file_name, File.extname(file_name))
    }
elsif repo_name == 'homebrew-versions'
    tap_author = 'haraldnordgren'
    tap_dir = "/usr/local/Homebrew/Library/Taps/#{tap_author}/homebrew-#{tap_short_name}"
    puts tap_dir

    skip_packages_string = ARGV[0].gsub("-@", "@")
    formula_glob = "#{tap_dir}/Aliases/*"
    shorten_formula = lambda { |file_name|
        return File.basename(file_name)
    }
end

tap_log_file = "tap.log"
tap_cmd = "brew tap #{tap_author}/#{tap_short_name} > #{tap_log_file} 2>&1"
successful_exit = system(tap_cmd)
puts

if not successful_exit
    puts "Cannot tap with cmd: '#{tap_cmd}'"
    puts File.read(tap_log_file)
    exit 1
end

skip_packages = skip_packages_string.split(" ")

skip_regexes = [
    /^allegro[@]?[0-9]+$/,
    /^ansible[@]?[0-9]+$/, # 5 mins, x2
    /^arangodb[@]?[0-9]+$/,
    /^android-ndk/,
    /^bazel[@]?[0-9]+$/,
    /^boost[@]?[0-9]+$/,
    /^boost-python[@]?[0-9]+$/,
    /^cloog[@]?[0-9]+$/, # 6 mins
    /^cloog-ppl[@]?[0-9]+$/,
    /^camlp5(-|@)606/, # 9 mins
    /^cassandra[@]?22/, # 6 mins (cassandra@21 in seconds!)
    /^duplicity[@]?06/,
    /^erlang(@|\-)?r[0-9]+$/,
    /^ffmpeg[@]?[0-9]+$/,
    /^gcc[@]?[0-9]+$/,
    /^gecode[@]?[0-9]+$/, # 5 mins
    /^gegl[@]?[0-9]+$/, # 3 mins
    /^gmp[@]?[0-9]+$/, # 7 mins
    /^gnuplot[@]?[0-9]+$/, # 2.5 mins
    /^gsl[@]?[0-9]+$/,
    /^gst-ffmpeg[@]?[0-9]+$/, # 7.5 mins
    /^gst-plugins-bad[@]?[0-9]+$/, # 4 mins
    /^gst-plugins-good[@]?[0-9]+$/, # 5 mins
    /^imagemagick-ruby[@]?[0-9]+$/, # 4.5 mins
    /^kafka[@]?[0-9]+$/,
    /^nu[@]?0/,

    # To be removed from migrated repo later
    /berkeley-db@4/,

    # Skipping because build fails in migrated form
    #/appledoc@22/,
]

# TIMING DATA:
# ansible19, built in 5 minutes
# ansible20, built in 7 minutes
# bison27, built in 2 minutes
# camlp5-606, built in 8 minutes
# cassandra22, built in 5 minutes

debug_skip = true

failed_jobs = []

puts "Finding formulae through glob: '#{formula_glob}"
puts

strf_string = '%-M min %S sec'

for file_name in Dir[formula_glob]
    puts "Total elapsed time: " + Time.at(Time.now - start_time).utc.strftime(strf_string)
    puts "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

    file_without_extension = shorten_formula.call(file_name)

    if file_without_extension =~ /gcc/
        debug_skip = false
    end

    if debug_skip
        puts "SKIPPING AHEAD OVER #{file_without_extension}"
        next
    end

    if skip_packages.include?(file_without_extension)
        puts "SKIPPING #{file_without_extension}, incompatible Xcode verson"
        next
    end

    matched_regex = false
    for regex in skip_regexes
        if file_without_extension =~ regex
            puts "SKIPPING #{file_without_extension} after matching #{regex}"
            matched_regex = true
            break
        end
    end

    if matched_regex
        next
    end

    puts "INSTALLING #{file_without_extension}"

    package_full_name = "#{tap_author}/#{tap_short_name}/#{file_without_extension}"

    log_file = "#{file_without_extension}.log"
    cmd_list = []

    if file_without_extension =~ /automake/
        cmd_list.push("brew link autoconf")
    elsif file_without_extension =~ /influxdb[@]?08|ledger[@]?26|llvm[@]?35|thrift[@]?090|riak[@]?132|rebar[@]?3|rabbitmq[@]?30/
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
    end

    cmd_list.push("brew install --verbose #{package_full_name}")
    cmd_list.push("brew unlink #{package_full_name}")
    cmd_list.push("brew uninstall --ignore-dependencies #{package_full_name}")

    if file_without_extension =~ /automake/
        cmd_list.push("brew unlink autoconf")
    elsif file_without_extension =~ /influxdb[@]?08|ledger[@]?26|llvm[@]?35|thrift[@]?090|riak[@]?132|rebar[@]?3|rabbitmq[@]?30/
        cmd_list.push("brew unlink autoconf automake")
    elsif file_without_extension =~ /gdal[@]?111/
        cmd_list.push("brew unlink autoconf automake")
    end

    concatenated_cmd = ""
    for cmd in cmd_list
        concatenated_cmd += "#{cmd} >> #{log_file} 2>&1 && "
    end
    concatenated_cmd += "true"

    successful_exit = system(concatenated_cmd)
    if successful_exit
        puts "INSTALLED #{file_without_extension} SUCCESSFULLY"
        puts open(log_file) {
            |f| f.grep(/built in/)
        }
    else
        puts "FAILED ON INSTALLING #{file_without_extension}"
        failed_jobs.push(file_without_extension)
    end
end

puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

if failed_jobs.empty?
    exit 0
else
    puts "FAILED JOBS:"
    for job in failed_jobs
        puts job
        puts File.read(log_file)
        puts "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    end
    exit 1
end

