require 'fileutils'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'configuration'
require_relative '../aws/kms'
require_relative '../helpers/external_executable'

module MongoCluster
  module Storage
    extend ExternalExecutable

    mattr_reader :mounts do
      OpenStruct.new(
          Configuration
              .fetch(:storage)
              .transform_values(&OpenStruct.method(:new))
      )
    end

    mattr_reader :paths do
      Configuration
          .fetch(:storage)
          .values
          .map! {|mount| mount[:path]}
    end

    mattr_reader :devices do
      Configuration
          .fetch(:storage)
          .values
          .map! {|mount| mount[:device]}
    end

    mattr_reader :devices_regexp do
      Regexp.union(devices.map(&:to_s))
    end

    mattr_reader :fstab_path do
      Pathname('/etc/fstab')
    end

    mattr_reader :run_path do
      Pathname('/var/run/mongod')
    end

    mattr_reader :limits_path do
      Pathname('/etc/security/limits.conf')
    end

    def self.init
      set_udev
      set_limits
      create_mongo_run_path
      create_mounts_paths
      devices_to_xfs
      append_mounts
      mount
      link_journal_to_data
    end

    def self.mount
      run('mount -a')
    end

    private

    def self.set_udev
      run("blockdev --setra 32 #{mounts.data.device}")
      File.write('/etc/udev/rules.d/85-ebs.rules', udev_rule(mounts.data.device))
    end

    def self.udev_rule(device)
      format('ACTION=="add", KERNEL=="%s", ATTR{bdi/read_ahead_kb}="16"', device.basename)
    end

    def self.set_limits
      File.write(limits_path, limits_parameters)
    end

    def self.limits_parameters
      <<-EOF
* soft nofile 64000
* hard nofile 64000
* soft nproc 32000
* hard nproc 32000
      EOF
    end

    def self.create_mongo_run_path
      run_path.mkpath
      FileUtils.chown_R('mongod', 'mongod', run_path)
    end

    def self.create_mounts_paths
      paths
          .each(&:mkpath)
          .tap {|paths| FileUtils.chown_R('mongod', 'mongod', paths)}
    end

    def self.link_journal_to_data
      FileUtils.ln_s(mounts.journal.path, mounts.data.path, force: true)
    end

    def self.devices_to_xfs
      devices.each(&method(:mkfs_xfs))
    end

    def self.append_mounts
      fstab_path.open('r+') do |fstab|
        fstab
            .readlines
            .each(&:chomp!)
            .delete_if {|line| line.match(devices_regexp)}
            .push(mounts_string)
            .join("\n")
            .tap do |fstab_string|
          fstab.truncate(0)
          fstab.write(fstab_string)
        end
      end
    end

    def self.mounts_string
      mounts
          .each_pair
          .map {|key, mount| generate_mount_string(mount)}
          .join("\n")
    end

    def self.generate_mount_string(mount)
      format('%s %s xfs defaults,auto,noatime,noexec 0 0', mount.device, mount.path)
    end

    def self.mkfs_xfs(device)
      run("mkfs.xfs -f #{device}") unless xfs?(device)
    end

    def self.xfs?(device)
      run("blkid -o value -s TYPE #{device}") == 'xfs'
    end

  end
end