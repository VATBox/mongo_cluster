require 'fileutils'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'helpers/service'

module MuninNode
  extend Service

  mattr_reader :service_name do
    'munin-node'
  end

  mattr_reader :plugin_path do
    Pathname('/etc/munin/plugins')
  end

  mattr_reader :iostat_ios_state_path do
    Pathname('/var/lib/munin/plugin-state/iostat-ios.state')
  end

  def self.init
    link_iostat_to_plugin
    create_iostat_state
    chkconfig_on
    start
  end

  private

  def self.link_iostat_to_plugin
    FileUtils.ln_s('/usr/share/munin/plugins/iostat', plugin_path, force: true)
    FileUtils.ln_s('/usr/share/munin/plugins/iostat_ios', plugin_path, force: true)
  end

  def self.create_iostat_state
    FileUtils.touch(iostat_ios_state_path)
    FileUtils.chown_R('munin', 'munin', iostat_ios_state_path)
  end

end