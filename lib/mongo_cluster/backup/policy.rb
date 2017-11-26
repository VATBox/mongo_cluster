require 'active_support/core_ext/class/attribute_accessors'
require_relative '../configuration'

module MongoCluster
  module Backup
    module Policy

      mattr_reader :retention_expiration do
        OpenStruct.new(Configuration.fetch(:backup).fetch(:retention_expiration))
      end

      mattr_reader :snapshot_interval do
        Configuration.fetch(:backup).fetch(:snapshot_interval)
      end

      def self.keep_minutely_snapshots(snapshots)
        minutely_expiration = self.minutely_expiration
        snapshots.delete_if {|snapshot| snapshot.start_time > minutely_expiration}
      end

      def self.keep_retention_snapshots(snapshots)
        retention_dates = hourly_retention_dates | daily_retention_dates
        snapshots.tap do |snapshots|
          snapshots
              .keep_if
              .with_index do |snapshot, index|
            next_snapshot = snapshots.fetch(index + 1, OpenStruct.new(start_time: snapshot.start_time.dup.end_of_hour))
            date_range = Range.new(snapshot.start_time, next_snapshot.start_time)
            retention_dates.none? {|retention_date| date_range.cover?(retention_date)}
          end
        end
      end

      private

      def self.minutely_expiration
        retention_expiration
            .minutely
            .days
            .ago
      end

      def self.hourly_expiration
        retention_expiration
            .hourly
            .days
            .ago
      end

      def self.daily_expiration
        retention_expiration
            .daily
            .days
            .ago
      end

      def self.hourly_retention_dates
        Range
            .new(hourly_expiration.to_i, minutely_expiration.to_i)
            .step(1.hour)
            .map(&Time.method(:at))
      end

      def self.daily_retention_dates
        Range
            .new(daily_expiration.to_i, hourly_expiration.to_i)
            .step(1.day)
            .map(&Time.method(:at))
      end

    end
  end
end