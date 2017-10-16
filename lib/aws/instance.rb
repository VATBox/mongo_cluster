require 'aws-sdk'
require 'net/http'
require 'active_support/core_ext/class/attribute_accessors'

module Aws::Instance

  mattr_reader :id do
    Net::HTTP.get('http://169.254.169.254/latest/meta-data/instance-id')
  end

  mattr_reader :client do
    Aws::EC2::Instance.new(id)
  end

  def self.logical_id
    tag('aws:cloudformation:logical-id')
  end

  def self.stack_name
    tag('aws:cloudformation:stack-name')
  end

  def self.stack_id
    tag('aws:cloudformation:stack-id')
  end

  def self.private_ip
    client.private_ip_address
  end

  def self.tag(name)
    tags.fetch(name)
  end

  def self.tags
    Hash[client.tags.map(&:to_a)]
  end

end