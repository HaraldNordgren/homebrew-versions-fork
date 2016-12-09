require 'fileutils'


debug_skip = false

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

tap_cmd = "brew tap #{tap_author}/#{tap_short_name}"
successful_exit = system(tap_cmd)
if not successful_exit
    puts "Cannot tap with cmd: '#{tap_cmd}'"
    exit 1
end

skip_packages = skip_packages_string.split(" ")

skip_regexes = [
    /allegro[@]?[0-9]+/,
    /ansible[@]?[0-9]+/, # 5 mins, x2
    /arangodb[@]?[0-9]+/,
    /android-ndk/,
    /bazel[@]?[0-9]+/,
    /boost[@]?[0-9]+/,
    /boost-python[@]?[0-9]+/,
    /camlp5-606/,
    /camlp5@606/, # 9 mins
    /cassandra[@]?22/, # 6 mins (cassandra@21 in seconds!)
    /duplicity[@]?06/,
    /erlang(@|\-)?r[0-9]+/,
    /ffmpeg[@]?[0-9]+/,
    /cloog-ppl[@]?[0-9]+/,

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

build_job_failed = false
puts "Finding formulae through glob: '#{formula_glob}"

for file_name in Dir[formula_glob]
    file_without_extension = shorten_formula.call(file_name)

    #if file_without_extension == 'ffmpeg28'
    #    debug_skip = false
    #end

    #if debug_skip
    #    puts "SKIPPING AHEAD OVER #{file_without_extension}"
    #    next
    #end

    puts "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

    if skip_packages.include?(file_without_extension)
        puts "SKIPPING #{file_without_extension}"
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
    end

    cmd_list.push("brew install --verbose #{package_full_name}")
    cmd_list.push("brew unlink #{package_full_name}")
    cmd_list.push("brew uninstall --ignore-dependencies #{package_full_name}")

    if file_without_extension =~ /automake/
        cmd_list.push("brew unlink autoconf")
    end

    concatenated_cmd = ""
    for cmd in cmd_list
        concatenated_cmd += "#{cmd} >> #{log_file} && "
    end
    concatenated_cmd += "true"

    successful_exit = system(concatenated_cmd)
    if successful_exit
        puts "Installed #{file_without_extension}"
        puts open(log_file) {
            |f| f.grep(/built in/)
        }
    else
        build_job_failed = true
        puts File.read(log_file)
    end

end

exit build_job_failed ? 1 : 0

