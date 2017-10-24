require 'aws-sdk'
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

    mattr_reader :client do
      ::Aws::CloudFormation::Stack.new(name)
    end

    def self.resource(logical_id: Instance.logical_id)
      client.resource(logical_id)
    end

  end
end