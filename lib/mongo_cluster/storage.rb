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
      Pathname('/etc/security/limits.d/90-mongodb.conf')
    end

    def self.init
      set_udev
      set_limits
      create_mongo_run_path
      create_mounts_paths
      devices_to_xfs
      append_mounts
      mount_paths
      link_journal_to_data
      chown_paths
    end

    def self.mount_paths
      paths.each(&method(:mount))
    end

    def self.mount(path)
      run("mount #{path}")
    end

    private

    def self.set_udev
      devices
          .each {|device| run("blockdev --setra 0 #{device}")}
          .map {|device| format('ACTION=="add|change", KERNEL=="%s", ATTR{bdi/read_ahead_kb}="0"', device.basename)}
          .join("\n")
          .tap {|udev_rules_string| File.write('/etc/udev/rules.d/85-ebs.rules', udev_rules_string)}
    end

    def self.set_limits
      File.write(limits_path, limits_parameters)
    end

    def self.limits_parameters
      <<-EOF
* soft nofile 64000
* hard nofile 64000
* soft nproc 64000
* hard nproc 64000
      EOF
    end

    def self.create_mongo_run_path
      run_path.mkpath
      FileUtils.chown_R('mongod', 'mongod', run_path)
    end

    def self.create_mounts_paths
      paths.each(&:mkpath)
    end

    def self.chown_paths
      FileUtils.chown_R('mongod', 'mongod', paths.map(&:to_s))
    end

    def self.link_journal_to_data
      FileUtils.ln_s(mounts.journal.path, mounts.data.path, force: true)
    end

    def self.devices_to_xfs
      devices.each(&method(:mkfs_xfs))
    end

    def self.append_mounts
      fstab_path
          .readlines
          .each(&:chomp!)
          .delete_if {|line| line.match(devices_regexp)}
          .push(mounts_string)
          .join("\n")
          .tap {|fstab_string| File.write(fstab_path, fstab_string)}
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
      run("lsblk --raw --noheadings --output FSTYPE #{device}") == 'xfs'
    end

  end
end