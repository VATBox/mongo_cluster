require 'aws-sdk'
require 'net/http'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'stack'
require_relative '../helpers/json'

module Aws
  module Instance

    mattr_reader :document do
      document_uri = URI.parse('http://169.254.169.254/latest/dynamic/instance-identity/document')
      document = Net::HTTP.get(document_uri)
      JSON.parse_with_cast(document)
    end

    mattr_reader :id do
      document.fetch(:instanceId)
    end

    mattr_reader :region do
      ENV['AWS_REGION'] = document.fetch(:region)
    end

    mattr_reader :client do
      ::Aws::EC2::Instance.new(id)
    end

    mattr_reader :tags do
      Hash[client.tags.map(&:to_a)]
    end

    def self.metadata
      Stack.resource.metadata_with_cast
    end

    def self.logical_id
      tag('aws:cloudformation:logical-id')
    end

    def self.all_resources
      Stack
          .client
          .resource_summaries
          .select {|resource_summary| resource_summary.resource_type == 'AWS::EC2::Instance'}
          .map!(&:resource)
    end

    def self.private_ip
      client.private_ip_address
    end

    def self.tag(name)
      tags.fetch(name)
    end

  end
end