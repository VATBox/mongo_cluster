require 'active_support/core_ext/class/attribute_accessors'
require_relative 'configuration'
require_relative 'storage'
require_relative 'replica_set'
require_relative 'backup/policy'
require_relative '../helpers/service'

module MongoCluster
  module Backup
    extend Service

    mattr_reader :service_name do
      'backup_scheduler'
    end

    mattr_reader :log_path do
      Storage
          .mounts
          .log
          .path
    end

    def self.init
      append_chkconfig
      link_daemon_to_init_d
      chkconfig_add
      start
    end

    def self.data_volume
      find_data_volume.backup
    end

    def self.apply_retention_policy
      find_data_volume
          .snapshots
          .sort_by(&:start_time)
          .tap(&Policy.method(:keep_minutely_snapshots))
          .tap(&Policy.method(:keep_retention_snapshots))
          .each(&:delete)
    end

    def self.member_sync!
      ReplicaSet
          .status
          .fetch(:members)
          .find {|member| member.fetch(:self, false)}
          .tap do |member|
        raise_member_not_sync(member) if member.fetch(:optimeDate) < 1.minute.ago
      end
    end

    private

    def self.link_daemon_to_init_d
      FileUtils.ln_s(daemon_path, '/etc/init.d/', force: true)
    end

    def self.append_chkconfig
      daemon_path
          .readlines
          .each(&:chomp!)
          .delete_if {|line| line =~ /chkconfig/}
          .tap {|lines| lines.first.concat(chkconfig_parameters)}
          .join("\n")
          .tap {|daemon_string| File.write(daemon_path, daemon_string)}
    end

    def self.daemon_path
      Pathname('/usr/local/bin').join(service_name)
    end

    def self.chkconfig_parameters
      "\n# chkconfig: 2345 20 80"
    end

    def self.find_data_volume
      ::Aws::Instance
          .volumes
          .find{ |volume| volume.device == Storage.mounts.data.device}
    end

    def self.raise_member_not_sync(member)
      raise format('Now: %s, Last Sync: %s, Message: %s', Time.now, *member.values_at(:optimeDate, :infoMessage))
    end

  end
end