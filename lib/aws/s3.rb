require 'aws-sdk-s3'
require 'parallel'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'stack'

module Aws
  module S3

    mattr_reader :type do
      'AWS::S3::Bucket'
    end

    mattr_reader :bucket do
      Aws::S3::Bucket.new(
          Stack
              .object
              .resource_summaries
              .find {|resource_summary| resource_summary.resource_type == type}
              .physical_resource_id
      )
    end

    def self.upload!(path, object_key = '')
      object_key.replace(path.basename.to_s) if object_key.blank?
      bucket.object(object_key).upload_file(path)
    end

  end
end