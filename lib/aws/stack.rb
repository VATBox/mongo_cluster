require 'aws-sdk-ec2'
require 'aws-sdk-cloudformation'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'instance/document'
require_relative '../helpers/aws_cloudformation_stack_resource'

module Aws
  module Stack

    %w[name id].tap do |attrs|
      cloudformation_prefix = 'aws:cloudformation:stack-'
      Aws::EC2::Client
              .new(region: Instance::Document.fetch(:region))
              .describe_tags(
                  filters:
                      [
                          {name: 'key', values: attrs.map {|attr| cloudformation_prefix + attr}},
                          {name: 'resource-id', values: [Instance::Document.fetch(:instance_id)]}
                      ]
              )
              .tags
              .each do |tag|
        mattr_reader(tag.key.sub(cloudformation_prefix, '').to_sym) {tag.value}
      end
    end

    mattr_reader :object do
      ::Aws::CloudFormation::Stack.new(name)
    end

    mattr_reader :client do
      object.client
    end

    def self.resource(logical_id: Instance.logical_id)
      object.resource(logical_id)
    end

    def self.fetch_parameter(parameter_key)
      object
          .parameters
          .find {|parameter| parameter.fetch('parameter_key') == parameter_key}
          .parameter_value
    end

  end
end