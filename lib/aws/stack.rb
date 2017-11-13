require 'aws-sdk-cloudformation'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'instance'
require_relative '../helpers/aws_cloudformation_stack_resource'

module Aws
  module Stack

    mattr_reader :name do
      Instance.tag('aws:cloudformation:stack-name')
    end

    mattr_reader :id do
      Instance.tag('aws:cloudformation:stack-id')
    end

    mattr_reader :object do
      ::Aws::CloudFormation::Stack.new(name)
    end

    mattr_reader :client do
      object.client
    end

    def self.signal_resource(logical_resource_id, unique_id, status)
      Stack.client.signal_resource(stack_name: name, logical_resource_id: logical_resource_id, unique_id: unique_id, status: status)
    end

    def self.resource(logical_id: Instance.logical_id)
      object.resource(logical_id)
    end

  end
end