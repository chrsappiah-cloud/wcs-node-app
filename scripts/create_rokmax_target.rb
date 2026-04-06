require 'xcodeproj'

project_path = '/Applications/GeoWCS/GeoWCS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

geo_target = project.targets.find { |t| t.name == 'GeoWCS' }
abort('GeoWCS target not found') unless geo_target

rok_target = project.targets.find { |t| t.name == 'RokMax' }
rok_target ||= project.new_target(:application, 'RokMax', :ios, geo_target.deployment_target || '26.0')

root_group = project.main_group['GeoWCS']

if rok_target.file_system_synchronized_groups.empty?
  rok_target.file_system_synchronized_groups << root_group
end

unless root_group.exceptions.any? { |e| e.respond_to?(:target) && e.target == rok_target }
  exception_set = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
  exception_set.target = rok_target
  exception_set.membership_exceptions = ['Info.plist', 'GeoWCSApp.swift', 'ContentView.swift', 'Item.swift']
  root_group.exceptions << exception_set
end

geo_exception_set = root_group.exceptions.find { |e| e.respond_to?(:target) && e.target == geo_target }
if geo_exception_set.nil?
  geo_exception_set = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
  geo_exception_set.target = geo_target
  geo_exception_set.membership_exceptions = ['Info.plist', 'RokMaxCreative']
  root_group.exceptions << geo_exception_set
else
  exceptions = Array(geo_exception_set.membership_exceptions)
  exceptions << 'Info.plist' unless exceptions.include?('Info.plist')
  exceptions << 'RokMaxCreative' unless exceptions.include?('RokMaxCreative')
  geo_exception_set.membership_exceptions = exceptions
end

rok_exception_set = root_group.exceptions.find { |e| e.respond_to?(:target) && e.target == rok_target }
unless rok_exception_set.nil?
  exceptions = Array(rok_exception_set.membership_exceptions)
  ['Info.plist', 'GeoWCSApp.swift', 'ContentView.swift', 'Item.swift'].each do |entry|
    exceptions << entry unless exceptions.include?(entry)
  end
  rok_exception_set.membership_exceptions = exceptions
end

geo_cfg_by_name = geo_target.build_configurations.each_with_object({}) { |cfg, h| h[cfg.name] = cfg }

geo_target.build_configurations.each do |cfg|
  excluded = Array(cfg.build_settings['EXCLUDED_SOURCE_FILE_NAMES'])
  excluded << 'RokMaxCreative/*.swift' unless excluded.include?('RokMaxCreative/*.swift')
  cfg.build_settings['EXCLUDED_SOURCE_FILE_NAMES'] = excluded
end

rok_target.build_configurations.each do |cfg|
  geo_cfg = geo_cfg_by_name[cfg.name] || geo_target.build_configurations.first

  cfg.build_settings['PRODUCT_NAME'] = 'DeArtsWCS'
  cfg.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.wcs.RokMax'
  cfg.build_settings.delete('INFOPLIST_FILE')
  cfg.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  cfg.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  cfg.build_settings['TARGETED_DEVICE_FAMILY'] = geo_cfg.build_settings['TARGETED_DEVICE_FAMILY'] || '1,2'
  cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = geo_cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] || geo_target.deployment_target || '26.0'
  cfg.build_settings['SWIFT_VERSION'] = geo_cfg.build_settings['SWIFT_VERSION'] || '5.0'
  cfg.build_settings['CODE_SIGN_STYLE'] = geo_cfg.build_settings['CODE_SIGN_STYLE'] || 'Automatic'
  cfg.build_settings['DEVELOPMENT_TEAM'] = geo_cfg.build_settings['DEVELOPMENT_TEAM'] if geo_cfg.build_settings['DEVELOPMENT_TEAM']

  conditions = cfg.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS']
  normalized_conditions =
    case conditions
    when String then conditions.split(/\s+/)
    when Array then conditions.flat_map { |entry| entry.to_s.split(/\s+/) }
    else ['$(inherited)']
    end
  normalized_conditions << 'ROKMAX_APP' unless normalized_conditions.include?('ROKMAX_APP')
  cfg.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = normalized_conditions

  cfg.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'DeArtsWCS'
  cfg.build_settings['INFOPLIST_KEY_NSCameraUsageDescription'] = 'DeArtsWCS uses the camera to capture creative photos and videos.'
  cfg.build_settings['INFOPLIST_KEY_NSMicrophoneUsageDescription'] = 'DeArtsWCS uses the microphone when recording videos and audio memories.'
  cfg.build_settings['INFOPLIST_KEY_NSPhotoLibraryUsageDescription'] = 'DeArtsWCS lets you pick photos for memories and creative prompts.'
  cfg.build_settings['INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription'] = 'DeArtsWCS saves your generated art and recordings to your photo library.'
  cfg.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  cfg.build_settings['EXCLUDED_SOURCE_FILE_NAMES'] = ['GeoWCSApp.swift', 'ContentView.swift']
  cfg.build_settings['INCLUDED_SOURCE_FILE_NAMES'] = ['RokMaxCreative/*.swift']
end

shared_data = '/Applications/GeoWCS/GeoWCS.xcodeproj/xcshareddata'
schemes_dir = "#{shared_data}/xcschemes"
Dir.mkdir(shared_data) unless Dir.exist?(shared_data)
Dir.mkdir(schemes_dir) unless Dir.exist?(schemes_dir)

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(rok_target)
scheme.set_launch_target(rok_target)
scheme.save_as('/Applications/GeoWCS/GeoWCS.xcodeproj', 'RokMax', true)

project.save
puts 'Created/updated RokMax target and scheme.'
