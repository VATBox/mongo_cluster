require 'active_support/core_ext/class/attribute_accessors'
require_relative 'configuration'
require_relative 'storage'
require_relative 'replica_set'

module MongoCluster
  module Backup

    mattr_reader :policy do
      OpenStruct.new(Configuration.fetch(:backup)).tap do |policy|
        policy.snapshot_interval = policy.snapshot_interval.minutes.to_i
        policy.deletion_interval = policy.deletion_interval.days.to_i
        policy.retention = policy.retention.days.ago
      end
    end

    mattr_reader :log_path do
      Storage
          .mounts
          .log
          .path
    end

    def self.data_volume
      find_data_volume.backup
    end

    def self.apply_retention_policy
      find_data_volume.delete_past_retention_snapshots
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