require 'aws-sdk'

module Aws::Metadata

  def self.fetch(resource_name, *keys)
    resource_metadata(resource_name).dig(*keys)
  end

  def self.resource_metadata(resource_name)
    JSON.parse(resource(resource_name).metadata)
  end

  def self.resource(name)
    cluster_stack.resource(name)
  end

  def self.cluster_stack(name = 'MongoCluster')
    Aws::CloudFormation::Resource
        .new
        .stack(name)
  end

end
