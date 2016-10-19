require 'optparse'
require 'tempfile'

# -----------------------
# --- functions
# -----------------------

def fail_with_message(message)
  puts "\e[31m#{message}\e[0m"
  exit(1)
end


def aapt_path
  android_home = ENV['ANDROID_HOME']
  if android_home.nil? || android_home == ''
    fail_with_message('Failed to get ANDROID_HOME env')
  end

  aapt_files = Dir[File.join(android_home, 'build-tools', '/**/aapt')]
  fail_with_message('Failed to find aapt tool') unless aapt_files

  latest_build_tool_version = ''
  latest_aapt_path = ''
  aapt_files.each do |aapt_file|
    path_splits = aapt_file.to_s.split('/')
    build_tool_version = path_splits[path_splits.count - 2]

    latest_build_tool_version = build_tool_version if latest_build_tool_version == ''
    if Gem::Version.new(build_tool_version) >= Gem::Version.new(latest_build_tool_version)
      latest_build_tool_version = build_tool_version
      latest_aapt_path = aapt_file.to_s
    end
  end

  fail_with_message('Failed to find latest aapt tool') if latest_aapt_path == ''
  return latest_aapt_path
end

def filter_package_infos(infos)
  package_name = ''
  version_code = ''
  version_name = ''

  package_name_version_regex = 'package: name=\'(?<package_name>.*)\' versionCode=\'(?<version_code>.*)\' versionName=\'(?<version_name>.*)\' platformBuildVersionName='
  package_name_version_match = infos.match(package_name_version_regex)

  if package_name_version_match && package_name_version_match.captures
    package_name = package_name_version_match.captures[0]
    version_code = package_name_version_match.captures[1]
    version_name = package_name_version_match.captures[2]
  end

  return package_name, version_code, version_name
end

def filter_app_label(infos)
  # application: label='CardsUp' icon='res/mipmap-hdpi-v4/ic_launcher.png'
  app_label_regex = 'application: label=\'(?<label>.+)\' icon='
  app_label_match = infos.match(app_label_regex)

  return app_label_match.captures[0]  if app_label_match && app_label_match.captures

  # application-label:'CardsUp'
  app_label_regex = 'application-label:\'(?<label>.*)\''
  app_label_match = infos.match(app_label_regex)

  return app_label_match.captures[0] if app_label_match && app_label_match.captures

  return ''
end

def filter_app_icon(infos)
  # application: label='CardsUp' icon='res/mipmap-hdpi-v4/ic_launcher.png'
  app_icon_regex = 'application: label=\'(?<label>.+)\' icon=\'(?<icon>.+)\''
  app_icon_match = infos.match(app_icon_regex)

  return app_icon_match.captures[1]  if app_icon_match && app_icon_match.captures

  return ''
end

def filter_min_sdk_version(infos)
  min_sdk = ''

  min_sdk_regex = 'sdkVersion:\'(?<min_sdk_version>.*)\''
  min_sdk_match = infos.match(min_sdk_regex)
  min_sdk = min_sdk_match.captures[0] if min_sdk_match && min_sdk_match.captures

  return min_sdk
end

def get_android_apk_info(apk_path)
  puts
  puts
  puts "# Deploying apk file: #{apk_path}"

  # - Analyze the apk / collect infos from apk
  puts '--> Analyze the apk'

  aapt = aapt_path
  infos = `#{aapt} dump badging #{apk_path}`

  package_name, version_code, version_name = filter_package_infos(infos)
  app_name = filter_app_label(infos)
  min_sdk = filter_min_sdk_version(infos)
  icon_apk_path = filter_app_icon(infos)

  apk_file_size = File.size(apk_path)

  `unzip -p #{apk_path} #{icon_apk_path} > #{File.dirname(apk_path)}/icon.png`

  icon_path = File.dirname(apk_path) + "/icon.png"


  apk_info_hsh = {
    file_size_bytes: apk_file_size,
    app_info: {
      app_name: app_name,
      package_name: package_name,
      version_code: version_code,
      version_name: version_name,
      min_sdk_version: min_sdk,
      icon_path: icon_path
    }
  }



  puts "#{apk_info_hsh}"

  return apk_info_hsh
end

# ----------------------------
# --- Options

options = {
  deploy_path: nil,
}

parser = OptionParser.new do|opts|
  opts.banner = 'Usage: step.rb [options]'
  opts.on('-d', '--deploypath PATH', 'Deploy Path') { |d| options[:deploy_path] = d unless d.to_s == '' }
  opts.on('-h', '--help', 'Displays Help') do
    exit
  end
end
parser.parse!

fail_with_message('No deploy_path provided') unless options[:deploy_path]

options[:deploy_path] = File.absolute_path(options[:deploy_path])

if !Dir.exist?(options[:deploy_path]) && !File.exist?(options[:deploy_path])
  fail_with_message('Deploy source path does not exist at the provided path: ' + options[:deploy_path])
end

puts
puts '========== Configs =========='
puts " * deploy_path: #{options[:deploy_path]}"

# ----------------------------
# --- Main

begin
  apk_info_hsh = ""
  if File.directory?(options[:deploy_path])
      puts
      puts '## Uploading the content of the Deploy directory separately'
      entries = Dir.entries(options[:deploy_path])
      entries.delete('.')
      entries.delete('..')

      entries = entries
        .map { |e| File.join(options[:deploy_path], e) }
        .select { |e| !File.directory?(e) }

      puts
      puts '======= List of files ======='
      puts ' No files found to deploy' if entries.length == 0
      entries.each { |filepth| puts " * #{filepth}" }
      puts '============================='
      puts

      entries.each do |filepth|
        disk_file_path = filepth

        if disk_file_path.match('.*.apk')
          apk_info_hsh = get_android_apk_info(disk_file_path)
        end
      end
  else
    puts
    puts '## Deploying single file'
    if options[:deploy_path].match('.*.apk')
      apk_info_hsh = get_android_apk_info(options[:deploy_path])
    end
  end

  # - Success
  fail 'Failed to export ANDROID_APK_FILE_SIZE' unless system("envman add --key ANDROID_APK_FILE_SIZE --value '#{apk_info_hsh[:file_size_bytes]}'")
  fail 'Failed to export ANDROID_APP_NAME' unless system("envman add --key ANDROID_APP_NAME --value '#{apk_info_hsh[:app_info][:app_name]}'")
  fail 'Failed to export ANDROID_APP_PACKAGE_NAME' unless system("envman add --key ANDROID_APP_PACKAGE_NAME --value '#{apk_info_hsh[:app_info][:package_name]}'")
  fail 'Failed to export ANDROID_APP_VERSION_NAME' unless system("envman add --key ANDROID_APP_VERSION_NAME --value '#{apk_info_hsh[:app_info][:version_name]}'")
  fail 'Failed to export ANDROID_APP_VERSION_CODE' unless system("envman add --key ANDROID_APP_VERSION_CODE --value '#{apk_info_hsh[:app_info][:version_code]}'")
  fail 'Failed to export ANDROID_ICON_PATH' unless system("envman add --key ANDROID_ICON_PATH --value '#{apk_info_hsh[:app_info][:icon_path]}'")
rescue => ex
  fail_with_message(ex)
end

exit 0