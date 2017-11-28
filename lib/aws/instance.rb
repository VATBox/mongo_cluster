require 'aws-sdk-ec2'
require 'net/http'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'stack'
require_relative 'instance/volume'
require_relative 'instance/document'
require_relative '../helpers/json'

module Aws
  module Instance

    mattr_reader :id do
      Document.fetch(:instance_id)
    end

    mattr_reader :client do
      ::Aws::EC2::Instance.new(id, region: Document.fetch(:region))
    end

    mattr_reader :type do
      'AWS::EC2::Instance'
    end

    mattr_reader :tags do
      HashWithIndifferentAccess[client.tags.map(&:entries)]
    end

    def self.all
      all_resources
          .map(&:physical_resource_id)
          .map!(&Aws::EC2::Instance.method(:new))
    end

    def self.metadata
      Stack.resource.metadata_with_cast
    end

    def self.logical_id
      tag('aws:cloudformation:logical-id')
    end

    def self.volumes
      client
          .volumes
          .map(&Volume.method(:new))
    end

    def self.signal(status)
      Stack.signal_resource(logical_id, id, status)
    end

    def self.all_resources
      Stack
          .object
          .resource_summaries
          .select(&method(:instance_type?))
          .map!(&:resource)
    end

    def self.wait_for_all_to_complete(instance_count)
      Stack.object.wait_until(max_attempts: 10, delay: 30) do |stack|
        stack
            .resource_summaries
            .count {|resource_summary| instance_type?(resource_summary) && status_complete?(resource_summary)}
            .eql?(instance_count)
      end
    end

    def self.tag(name)
      tags.fetch(name)
    end

    private

    def self.instance_type?(resource_summary)
      resource_summary.resource_type == type
    end

    def self.status_complete?(resource_summary)
      resource_summary.resource_status =~ /COMPLETE$/
    end

  end
end