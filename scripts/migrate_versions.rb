require 'fileutils'


def replace_brew_class (file_name, regex_captures)
    package = regex_captures[0]
    version = regex_captures[1]

    classname = ""
    for word in package.split("-")
        classname += word.capitalize
    end

    classname_with_version = classname
    for word in version.split("-")
        classname_with_version += word.capitalize
    end

    text = File.read(file_name)

    text.sub!(
        /(^class )#{classname_with_version}( < Formula$)/,
        '\1' + classname + '\2'
    )

    text.gsub!(
        /^  conflicts_with "#{package}",( |\n).*\n\n/,
        ''
    )

    if not text.match("^  version ")
        text.sub!(
            /(\n\n)/,
            "\n" + '  version "' + version + '"' + '\1'
        )
    end

    File.write(file_name, text)
    #puts "Replaced names in #{file_name}"

    package_at_version = package + "@" + version
    $handled_packages.push({
        #'package' => package,
        #'version' => version,
        'classname_with_version' => classname_with_version,
        'package_at_version' => package_at_version,
        'file_without_extension' => File.basename(file_name, File.extname(file_name)),
        'original_filename' => file_name,
        #'migrated_filename' => package_at_version + ".rb",
        'migrated_filename' => package + ".rb",
    })
end

project_root = File.dirname(__FILE__) + "/.."
#project_root = File.dirname(__FILE__) + "/sandbox"
Dir.chdir project_root

aliases_dir = "Aliases"
formula_dir = "Formula"

for dirname in [aliases_dir, formula_dir]
    unless File.directory?(dirname)
        puts "Creating " + dirname
        FileUtils.mkdir_p(dirname)
    end
end
puts

$handled_packages = []

for filename in Dir["*.rb"]
    version = filename.match(/(^.*?)([0-9]-lts).rb$/)
    if version
        replace_brew_class(filename, version.captures)
        next
    end
    
    version = filename.match(/(^.*?)-(lts|legacy|r[0-9]+[a-z]?).rb$/)
    if version
        replace_brew_class(filename, version.captures)
        next
    end

    version = filename.match(/(^.*?)[-]?([0-9\.]+[a-z]?).rb$/)
    if version
        replace_brew_class(filename, version.captures)
        next
    end

    migrated_path = File.join(formula_dir, filename)
    system("git mv #{filename} #{migrated_path}")
    system("git add #{migrated_path}")
end

puts "STEP 1 DONE"
puts

for file_name in Dir["*.rb"]
    text = File.read(file_name)
    for handled_package in $handled_packages
        file_without_extension = handled_package['file_without_extension']
        #puts "Replacing #{file_without_extension} in #{file_name}"
        text.gsub!(
            /#{file_without_extension}/,
            handled_package['package_at_version']
        )
    end

    File.write(file_name, text)
    #puts "Replaced all references in #{file_name}"
end

puts "STEP 2 DONE"
puts

for handled_package in $handled_packages
    original_filename = handled_package['original_filename']
    package_at_version = handled_package['package_at_version']

    formula_subdir = File.join(formula_dir, package_at_version)
    FileUtils.mkdir_p(formula_subdir)

    migrated_path = File.join(formula_subdir, handled_package['migrated_filename'])
    system("git mv #{original_filename} #{migrated_path}")
    system("git add #{migrated_path}")

    symlink_dest = File.join("..", migrated_path)
    symlink_location = File.join(aliases_dir, package_at_version)
    FileUtils.ln_s(symlink_dest, symlink_location)
end

system("git add #{aliases_dir}")

puts "STEP 3 DONE"
puts
puts "ALL DONE"
