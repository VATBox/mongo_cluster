require 'aws-sdk'
require 'ruby_dig'
require_relative 'stack'
require_relative '../helpers/json_helper'


module Aws::Metadata
  extend JsonHelper

  def self.fetch(*keys, **args)
    all(**args).dig(*keys)
  end

  def self.all(**args)
    metadata = ::Aws::Stack.resource(**args).metadata
    json_parse(metadata)
  end

end
