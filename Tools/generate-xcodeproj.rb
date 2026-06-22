# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 Steve Clarke <stephenlclarke@mac.com> - https://xyzzy.tools

require "xcodeproj"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
PROJECT_PATH = File.join(ROOT, "MyTimeBuddy.xcodeproj")
APP_NAME = "MyTimeBuddy"
TEST_NAME = "MyTimeBuddyTests"

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)

app_target = project.new_target(:application, APP_NAME, :ios, "17.0")
test_target = project.new_target(:unit_test_bundle, TEST_NAME, :ios, "17.0")
test_target.add_dependency(app_target)

app_group = project.main_group.new_group(APP_NAME, APP_NAME)
test_group = project.main_group.new_group(TEST_NAME, TEST_NAME)

def add_sources(target, group, relative_root)
  Dir.glob(File.join(ROOT, relative_root, "**", "*.swift")).sort.each do |path|
    relative_path = path.delete_prefix("#{ROOT}/#{relative_root}/")
    file_ref = group.new_file(relative_path)
    target.add_file_references([file_ref])
  end
end

add_sources(app_target, app_group, APP_NAME)
add_sources(test_target, test_group, TEST_NAME)

project.targets.each do |target|
  target.build_configurations.each do |config|
    settings = config.build_settings
    settings["CLANG_ANALYZER_NONNULL"] = "YES"
    settings["CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION"] = "YES_AGGRESSIVE"
    settings["CLANG_CXX_LANGUAGE_STANDARD"] = "gnu++20"
    settings["CLANG_ENABLE_MODULES"] = "YES"
    settings["CLANG_ENABLE_OBJC_ARC"] = "YES"
    settings["CLANG_ENABLE_OBJC_WEAK"] = "YES"
    settings["CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING"] = "YES"
    settings["CLANG_WARN_BOOL_CONVERSION"] = "YES"
    settings["CLANG_WARN_COMMA"] = "YES"
    settings["CLANG_WARN_CONSTANT_CONVERSION"] = "YES"
    settings["CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS"] = "YES"
    settings["CLANG_WARN_DIRECT_OBJC_ISA_USAGE"] = "YES_ERROR"
    settings["CLANG_WARN_DOCUMENTATION_COMMENTS"] = "YES"
    settings["CLANG_WARN_EMPTY_BODY"] = "YES"
    settings["CLANG_WARN_ENUM_CONVERSION"] = "YES"
    settings["CLANG_WARN_INFINITE_RECURSION"] = "YES"
    settings["CLANG_WARN_INT_CONVERSION"] = "YES"
    settings["CLANG_WARN_NON_LITERAL_NULL_CONVERSION"] = "YES"
    settings["CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF"] = "YES"
    settings["CLANG_WARN_OBJC_LITERAL_CONVERSION"] = "YES"
    settings["CLANG_WARN_OBJC_ROOT_CLASS"] = "YES_ERROR"
    settings["CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER"] = "YES"
    settings["CLANG_WARN_RANGE_LOOP_ANALYSIS"] = "YES"
    settings["CLANG_WARN_STRICT_PROTOTYPES"] = "YES"
    settings["CLANG_WARN_SUSPICIOUS_MOVE"] = "YES"
    settings["CLANG_WARN_UNGUARDED_AVAILABILITY"] = "YES_AGGRESSIVE"
    settings["CLANG_WARN_UNREACHABLE_CODE"] = "YES"
    settings["CLANG_WARN__DUPLICATE_METHOD_MATCH"] = "YES"
    settings["COPY_PHASE_STRIP"] = "NO"
    settings["DEBUG_INFORMATION_FORMAT"] = "dwarf"
    settings["ENABLE_STRICT_OBJC_MSGSEND"] = "YES"
    settings["ENABLE_TESTABILITY"] = config.name == "Debug" ? "YES" : "NO"
    settings["GCC_C_LANGUAGE_STANDARD"] = "gnu17"
    settings["GCC_NO_COMMON_BLOCKS"] = "YES"
    settings["GCC_WARN_64_TO_32_BIT_CONVERSION"] = "YES"
    settings["GCC_WARN_ABOUT_RETURN_TYPE"] = "YES_ERROR"
    settings["GCC_WARN_UNDECLARED_SELECTOR"] = "YES"
    settings["GCC_WARN_UNINITIALIZED_AUTOS"] = "YES_AGGRESSIVE"
    settings["GCC_WARN_UNUSED_FUNCTION"] = "YES"
    settings["GCC_WARN_UNUSED_VARIABLE"] = "YES"
    settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
    settings["SWIFT_VERSION"] = "6.0"
    settings["TARGETED_DEVICE_FAMILY"] = "1"
  end
end

app_target.build_configurations.each do |config|
  settings = config.build_settings
  settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = ""
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["CURRENT_PROJECT_VERSION"] = "1"
  settings["DEVELOPMENT_TEAM"] = ""
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["INFOPLIST_KEY_CFBundleDisplayName"] = "My Time Buddy"
  settings["INFOPLIST_KEY_LSApplicationCategoryType"] = "public.app-category.productivity"
  settings["INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents"] = "YES"
  settings["INFOPLIST_KEY_UILaunchScreen_Generation"] = "YES"
  settings["INFOPLIST_KEY_UISupportedInterfaceOrientations"] = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
  settings["MARKETING_VERSION"] = "0.1.0"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "tools.xyzzy.mytimebuddy"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator"
  settings["SUPPORTS_MACCATALYST"] = "NO"
  settings["SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD"] = "NO"
end

test_target.build_configurations.each do |config|
  settings = config.build_settings
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "tools.xyzzy.mytimebuddy.tests"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["SUPPORTED_PLATFORMS"] = "iphonesimulator iphoneos"
  settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/MyTimeBuddy.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/MyTimeBuddy"
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.add_build_target(test_target)
scheme.set_launch_target(app_target)
scheme.add_test_target(test_target)
scheme.save_as(project.path, APP_NAME, true)

project.save
