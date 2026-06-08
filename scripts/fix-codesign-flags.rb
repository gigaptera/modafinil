#!/usr/bin/env ruby
# Make codesign flags self-contained in the project so build.sh no longer needs to
# pass OTHER_CODE_SIGN_FLAGS on the command line (which clobbers per-target flags).
# The helper needs an explicit --identifier because codesign strips the ".helper"
# suffix from the executable name and would otherwise reuse the app's identifier.
require 'xcodeproj'

project_path = File.expand_path('../../Modafinil.xcodeproj', __FILE__)
project = Xcodeproj::Project.open(project_path)

app    = project.targets.find { |t| t.name == 'Modafinil' }       or abort 'app target missing'
helper = project.targets.find { |t| t.name == 'ModafinilHelper' } or abort 'helper target missing'

app.build_configurations.each do |c|
  c.build_settings['OTHER_CODE_SIGN_FLAGS'] = '$(inherited) --timestamp'
end

helper.build_configurations.each do |c|
  c.build_settings['OTHER_CODE_SIGN_FLAGS'] =
    '$(inherited) --timestamp --identifier com.gigaptera.modafinil.helper'
end

project.save
puts 'Set OTHER_CODE_SIGN_FLAGS on both targets'
