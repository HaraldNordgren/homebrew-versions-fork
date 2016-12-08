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
    /arangodb[@]?[0-9]+/,
    /android-ndk/,
    /bazel[@]?[0-9]+/,
    /boost[@]?[0-9]+/,
    /bootst-python[@]?[0-9]+/,
    /duplicity[@]?06/,
    /erlang(@|\-)?r[0-9]+/,
    /ffmpeg[@]?[0-9]+/,
    /cloog-ppl[@]?[0-9]+/,

    # To be removed from migrated repo later
    /berkeley-db@4/,

    # Skipping because build fails in migrated form
    /appledoc@22/,

]

# TIMING DATA:
# ansible19, built in 5 minutes
# ansible20, built in 7 minutes
# bison27, built in 2 minutes
# camlp5-606, built in 8 minutes
# cassandra22, built in 5 minutes

cmd = ""

puts "Finding formulas through glob: '#{formula_glob}"
for file_name in Dir[formula_glob]
    #puts "Matched #{file_name}"

    file_without_extension = shorten_formula.call(file_name)
    #puts "Tranformed to: #{file_without_extension}"

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

    package_full_name = "#{tap_author}/#{tap_short_name}/#{file_without_extension}"
    
    cmd += "echo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% && "
    cmd += "echo && "
    cmd += "echo Installing #{file_without_extension} && "

    if file_without_extension =~ /automake/
        cmd += "brew link autoconf && "
    end

    cmd += "brew install --verbose #{package_full_name} && "
    cmd += "brew unlink #{package_full_name} && "
    cmd += "brew uninstall --ignore-dependencies #{package_full_name} && "
    
    if file_without_extension =~ /automake/
        cmd += "brew unlink autoconf && "
    end
end

cmd += "echo ALL BUILDS FINISHED"
successful_exit = system(cmd)

exit successful_exit ? 0 : 1

