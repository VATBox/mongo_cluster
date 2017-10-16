require 'aws-sdk'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'instance'

module Aws::Stack

  mattr_reader :name do
    ::Aws::Instance.stack_name
  end

  mattr_reader :id do
    ::Aws::Instance.stack_id
  end

  mattr_reader :client do
    Aws::CloudFormation::Stack.new(name)
  end

  def self.resource(logical_id: ::Aws::Instance.logical_id)
    client.resource(logical_id)
  end

  def self.instance_logical_ids
    client
        .resource_summaries
        .select {|resource_summary| resource_summary.resource_type == 'AWS::EC2::Instance'}
        .map!(&:logical_id)
  end

end