require_relative '../aws/instance'

module MongoCluster

  Configuration =
      ::Aws::Instance
          .all_resources
          .find {|instance_resource| instance_resource.metadata_with_cast.fetch(:Configuration, false)}
          .metadata_with_cast
          .fetch(:Configuration)

end