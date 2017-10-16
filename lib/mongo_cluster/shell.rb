require 'mongo'

class MongoCluster::Client

  attr_reader :client

  def initialize(host, port = 27017)
    seed = format('%s:%s', host, port)
    monitor = Mongo::Monitoring.new(:monitoring => true)
    @client = Mongo::Cluster.new([seed], monitor)
  end

  def options
    client.options
  end

end