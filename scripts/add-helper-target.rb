#!/usr/bin/env ruby
# One-shot project surgery: add the privileged helper (LaunchDaemon) target,
# wire shared sources, embed the executable + launchd plist into the app bundle.
# Idempotent: re-running is a no-op once the target exists.
require 'xcodeproj'

project_path = File.expand_path('../../Modafinil.xcodeproj', __FILE__)
project = Xcodeproj::Project.open(project_path)

app = project.targets.find { |t| t.name == 'Modafinil' } or abort 'Modafinil target missing'

if project.targets.any? { |t| t.name == 'ModafinilHelper' }
  puts 'ModafinilHelper already exists — nothing to do'
  exit 0
end

main_group = project.main_group

shared_group = main_group.find_subpath('Shared', true)
shared_group.set_source_tree('<group>'); shared_group.set_path('Shared')
helper_group = main_group.find_subpath('Helper', true)
helper_group.set_source_tree('<group>'); helper_group.set_path('Helper')
mod_group = main_group.find_subpath('Modafinil', true)

# Helper target (command line tool → root LaunchDaemon)
helper = project.new_target(:command_line_tool, 'ModafinilHelper', :osx, '14.0', nil, :swift)

shared_proto     = shared_group.new_reference('HelperProtocol.swift')
helper_main      = helper_group.new_reference('main.swift')
helper_tool      = helper_group.new_reference('HelperTool.swift')
helper_plist_ref = helper_group.new_reference('com.gigaptera.modafinil.helper.plist')
app_helper_mgr   = mod_group.new_reference('HelperManager.swift')

helper.add_file_references([helper_main, helper_tool, shared_proto])
app.add_file_references([app_helper_mgr, shared_proto])

helper.build_configurations.each do |c|
  bs = c.build_settings
  bs['PRODUCT_NAME'] = 'com.gigaptera.modafinil.helper'
  bs['PRODUCT_MODULE_NAME'] = 'ModafinilHelper'
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.gigaptera.modafinil.helper'
  bs['MACOSX_DEPLOYMENT_TARGET'] = '14.0'
  bs['SWIFT_VERSION'] = '5.9'
  bs['ENABLE_HARDENED_RUNTIME'] = 'YES'
  bs['CODE_SIGN_STYLE'] = 'Manual'
  bs['CODE_SIGN_IDENTITY[sdk=macosx*]'] = 'Developer ID Application'
  bs['DEVELOPMENT_TEAM'] = ''
  bs['DEVELOPMENT_TEAM[sdk=macosx*]'] = 'DX295NS6CV'
  bs['SKIP_INSTALL'] = 'YES'
  bs['CODE_SIGN_INJECT_BASE_ENTITLEMENTS'] = 'NO'
end

app.add_dependency(helper)

# Embed helper executable → Contents/MacOS (code-signed on copy)
embed_exe = app.new_copy_files_build_phase('Embed Helper Executable')
embed_exe.symbol_dst_subfolder_spec = :executables
bf = embed_exe.add_file_reference(helper.product_reference)
bf.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy'] }

# Embed launchd plist → Contents/Library/LaunchDaemons
embed_plist = app.new_copy_files_build_phase('Embed Launch Daemon')
embed_plist.dst_subfolder_spec = '1' # wrapper (app bundle root)
embed_plist.dst_path = 'Contents/Library/LaunchDaemons'
embed_plist.add_file_reference(helper_plist_ref)

project.save
puts 'Added ModafinilHelper target + embed phases'
