require 'aws-sdk'

module Aws
  module Instance
    class Volume

      attr_reader :object
      attr_reader :device

      def initialize(object)
        @object = object
        @device = object.attachments.first.device
      end

      def tag(name)
        tags.fetch(name)
      end

      def tags
        Hash[object.tags.map(&:to_a)]
      end

      def backup
        create_snapshot
      end

      private

      def create_snapshot
        object
            .create_snapshot(description: Time.now.to_formatted_s(:db))
            .create_tags(snapshot_tag)
      end

      def snapshot_tag
        {
            tags:
                [
                    Key: 'Name',
                    Value: tag('Name')
                ]
        }
      end

      def delete_past_retention_snapshots
        retention = self.retention
        object
            .snapshots
            .select {|snapshot| snapshot.start_time < retention}
            .each(&:delete)
      end

      def retention
        MongoCluser::Configuration
            .fetch(:backup)
            .fetch(:retention)
            .days
            .ago
      end

    end
  end
end