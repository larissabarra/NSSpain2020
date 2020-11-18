fastlane_require "yaml"
fastlane_version "2.166.0"

default_platform :ios
xcode_version = "12.1"

app_identifier_internal = "com.app.internal"
app_identifier_release = "com.app"
app_identifier_dev = "com.app.dev"

platform :ios do

  #===  Environment lanes   ===#
  desc "Install the Xcode version used"
  lane :install_xcode do
    xcode_install(version: xcode_version)
  end

  desc "Clean builds and simulators"
  lane :clean do
    reset_simulators
    xcclean(workspace: "App.xcworkspace", scheme: "AppDev")
    xcclean(workspace: "App.xcworkspace", scheme: "AppStaging")
    xcclean(workspace: "App.xcworkspace", scheme: "AppInternalRelease")
    xcclean(workspace: "App.xcworkspace", scheme: "AppRelease")
    clean_build_artifacts
  end

  #===    Testing lanes     ===#
  desc "Run lint on the whole codebase"
  lane :lint do
    sh "mkdir -p lint_output"
    sh "touch lint_output/lint_output.json"
    swiftlint(
      mode: :lint,
      output_file: "fastlane/lint_output/lint_output.json"
    )
    sh "cat lint_output/lint_output.json"
  end

  desc "Run all Unit Tests"
  lane :unit_test do
    scan(workspace: "App.xcworkspace", scheme: "AppUnitTests")
    xcov(scheme: "AppUnitTests", skip_slack: true, minimum_coverage_percentage: 85.00)
  end

  desc "Run all UI Tests"
  lane :ui_test do
    scan(scheme: "AppUITests", reset_simulator: true, disable_concurrent_testing: true)
    xcov(scheme: "AppUITests", skip_slack: true, minimum_coverage_percentage: 70.00)
  end

  desc "Run Integration Tests"
  lane :integration_test do
    scan(scheme: "AppIntegrationTests")
  end

  # NOTE: this is based on using commit tags for version management
  # NOTE: should always point to production code, not testflight
  desc "Run Retro Compatibility Tests for past N versions (Default=1)"
  lane :retro_compatibility_test do
    number_of_previous_versions = ENV["PREVIOUS_VERSIONS"] || 1
    raise "You need to set the PREVIOUS_VERSIONS environment variable" unless !number_of_previous_versions.nil?
    
    (1..number_of_previous_versions.to_i).each do |version|
      `osascript -e "tell application "Simulator" to quit"`
      `xcrun simctl shutdown all`
      `xcrun simctl erase all`
      `git checkout $(git tag --sort=creatordate | grep -o "release-appstore-[0-9\.]*" | tail -n#{number_of_previous_versions} | sed -n #{version}p)`
      
      scan(scheme: "AppRetroCompatibilityTests")
      `git checkout master`
    end
  end


  #===  Certificates lanes   ===#
  desc "Fetch the Development, AdHoc certificates and Distribution certificates"
  lane :fetch_certificates do
    match(app_identifier: app_identifier_dev, readonly: true)
    match(app_identifier: app_identifier_release, readonly: true, type: "appstore")
  end

  desc "Generate new certificates"
    lane :new_certificates_and_provisioning_profiles do
    match(app_identifier: app_identifier_internal, readonly: false, force: true)
    match(app_identifier: app_identifier_internal, readonly: false, force: true, type: "adhoc")
    match(app_identifier: app_identifier_release, readonly: false, force: true, type: "appstore")
    match(app_identifier: app_identifier_dev, readonly: false, force: true)
  end

  #===    Build lanes     ===#
  desc "Build the IPA for a Scheme"
  lane :build_ipa do |options|
    pre_build(configuration: options[:configuration])
    build(scheme: options[:scheme])
  end

  private_lane :build do |options|
    gen_plist(options[:scheme])
    update_app_identifier(
      app_identifier: config_settings(options[:scheme])[:app_identifier],
      plist_path: "App/Release.plist"
    )
    gym(scheme: options[:scheme])
  end

  #===    Release lanes     ===#
  desc "Release to TestFlight"
  lane :release_testflight do
    ensure_git_status_clean

    pre_release
    testflight(app_identifier: app_identifier_release, distribute_external: false)
    post_release(tag: "testflight_release")

    clean_build_artifacts
  end

  desc "Generate a new Alpha Release on TestFlight"
  lane :release_alpha do
    git_pull(only_tags: true)
    build_number = next_build_number
    increment_build_number(build_number: build_number)

    tag_name = "release-alpha-#{version_number}.#{build_number}"
    add_git_tag(tag: tag_name)
    push_git_tags(tag: tag_name)

    send_build_to_testflight
    reset_git_repo(force: true)
  end

  desc "Send build to TestFlight"
  private_lane :send_build_to_testflight do |options|
    match(type: "appstore", app_identifier: app_identifier_release, readonly: true)
    build(scheme: "AppRelease")

    testflight(
      app_identifier: app_identifier_release,
      distribute_external: false,
      skip_submission: true,
      skip_waiting_for_build_processing: true
    )
  end

  desc "Generate a new Release Candidate on TestFlight"
  lane :new_swimlane_testflight do |options|
    git_pull(only_tags: true)
    rc_version = increment_version_number(bump_type: "patch")
    rc_build = increment_build_number(build_number: next_build_number)

    commit_version_bump(
      force: true, 
      xcodeproj: "App.xcodeproj", 
      message:"[ci-skip] Create Release Candidate #{rc_version}"
    )
    send_build_to_testflight

    tag_name = "release-alpha-#{rc_version}.#{rc_build}"
    add_git_tag(tag: tag_name)
    push_git_tags(tag: tag_name)

    reset_git_repo(force: true)

    push_to_git_remote(
      remote: "origin",
      local_branch: "HEAD",
      remote_branch: "master",
      tags: true
    )
  end

  #===    Utilitary lanes     ===#
  private_lane :update_version do |options|
    increment_build_number(build_number: next_build_number)
    mod_settings_plist(options[:configurationScheme])
  end

  private_lane :tag_commit do |options|
    `git tag #{options[:tag]}_#{build_number}`
    `git push --tags`
  end

  private_lane :pre_release do |options|
    update_version(configurationScheme: "Release")
    match(type: "appstore", app_identifier: app_identifier_release, readonly: true)
    build(scheme: "AppRelease")
  end

  private_lane :post_release do |options|
    tag_commit(tag: options[:tag])
    clean_build_artifacts
  end

  private_lane :pre_build do |options|
    match(type: options[:configuration], app_identifier: app_identifier_internal, force_for_new_devices: true)
    update_version(configurationScheme: "InternalRelease")
    version = get_version_number(xcodeproj: "App.xcodeproj", configuration: "InternalRelease")
  end

  #===    Variables     ===#
  def config_settings(scheme)
    config = YAML.load(open(File.join(File.dirname(__FILE__), "config.yml")))
    settings = OpenStruct.new(config)
    settings[scheme.slice(5..-1).downcase.to_sym]
  end

  def next_build_number
    `git tag --list "release-alpha-*" | cut -d . -f 4 | sort -rn | head -n 1 | xargs expr 1 +`.strip!
  end

  def version_number
    get_info_plist_value(path: "App/Release.plist", key: "CFBundleShortVersionString")
  end

  #===    Functions     ===#
  def mod_plist(config_file, key, value, type)
    `/usr/libexec/plistbuddy -c "delete :#{key}" #{config_file}`
    `/usr/libexec/plistbuddy -c "add :#{key} #{type} #{value}" #{config_file}`
  end

  def mod_settings_plist(configurationScheme)
    version = get_version_number(xcodeproj: "App.xcodeproj", configuration: "#{configurationScheme}")
    mod_plist(
      'App/Plist.plist', 
      'PreferenceSpecifiers:0:DefaultValue', 
      "#{version} (#{next_build_number})", 
      "string"
    )
  end

  def gen_plist(scheme)
    config = config_settings(scheme)

    ["Dev.plist", "Release.plist"].each do |plist_name|
      mod_plist(
        "App/#{plist_name}", 
        "SomeKey", 
        config[:some_key], 
        "string"
      )
    end
  end