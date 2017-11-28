require 'aws-sdk-ec2'
require 'active_support/core_ext/module/delegation'

module Aws
  module Instance
    class Volume

      delegate :create_snapshot, :create_tags, :delete, :snapshots, to: :@object

      attr_reader :object
      attr_reader :device

      def initialize(object)
        @object = object
        @device = Pathname(object.attachments.first.device)
      end

      def tag(name)
        tags.fetch(name)
      end

      def tags
        HashWithIndifferentAccess[object.tags.map(&:entries)]
      end

      def backup
        create_snapshot(description: Time.now.to_formatted_s(:db))
            .create_tags(tags: [{key: 'Name', value: tag('Name')}])
      end

    end
  end
end