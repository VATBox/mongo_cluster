require 'aws-sdk-ec2'
require 'net/http'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'stack'
require_relative 'instance/volume'
require_relative 'instance/document'
require_relative '../helpers/json'

module Aws
  class Instance

    cattr_reader :type do
      'AWS::EC2::Instance'
    end

    cattr_reader :environment do
      ::Aws::EC2::Instance.new(Document.fetch(:instance_id), region: Document.fetch(:region))
          .tags
          .find {|tag| tag.key == 'Environment'}
          .value
    end

    delegate :private_ip_address, :tags, to: :@object

    attr_reader :object
    attr_reader :tags_by_key

    def initialize(id = Document.fetch(:instance_id))
      @object = ::Aws::EC2::Instance.new(id, region: Document.fetch(:region))
    end

    def tag(name)
      @tags_by_key ||= HashWithIndifferentAccess[tags.map(&:entries)]
      tags_by_key.fetch(name)
    end

    def metadata
      Stack
          .resource(logical_id: logical_id)
          .metadata_with_cast
    end

    def replica_member
      metadata
          .fetch(:ReplicaMember)
          .tap do |member|
        member[:_id] = member.delete(:id)
        member[:host] = format('%s:%s', private_ip_address, MongoCluster::ReplicaSet.settings.port)
      end
    end

    def logical_id
      tag('aws:cloudformation:logical-id')
    end

    def resource_status
      Stack
          .resource(logical_id: logical_id)
          .resource_status
    end

    def volumes
      object
          .volumes
          .map(&Volume.method(:new))
    end

    def signal(status)
      Stack.signal_resource(logical_id, id, status)
    end

    def self.all
      all_resources
          .map {|resource| new(resource.physical_resource_id)}
          .select {|instance| instance.tag(:Environment) == environment}
    end

    def self.all_resources
      Stack
          .object
          .resource_summaries
          .select(&method(:instance_type?))
          .map!(&:resource)
    end

    def self.wait_for_all_to_complete(instance_count)
      Stack.object.wait_until(max_attempts: 10, delay: 30) do
        all.count {|instance| instance.resource_status =~ /COMPLETE$/} == instance_count
      end
    end

    private

    def self.instance_type?(resource_summary)
      resource_summary.resource_type == type
    end

  end
end