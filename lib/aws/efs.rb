require 'aws-sdk-efs'
require_relative 'stack'

module Aws
  module Efs

    mattr_reader :type do
      'AWS::EFS::FileSystem'
    end

    mattr_reader :id do
      Stack
          .object
          .resource_summaries
          .find {|resource_summary| resource_summary.resource_type == type}
          .physical_resource_id
    end

    mattr_reader :object do
      Aws::EFS::Client.new
    end

    mattr_reader :path do
      Pathname('/efs')
    end

    def self.mount_string
      format('%s:/ %s nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0', dns, path)
    end

    private

    def self.dns
      format('%s.efs.%s.amazonaws.com', id, Instance::Document.fetch(:region))
    end

  end
end