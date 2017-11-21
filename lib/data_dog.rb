require 'datadog/statsd'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'helpers/service'
require_relative 'aws/stack'
require_relative 'aws/kms'
require_relative 'mongo_cluster/replica_set'

module DataDog
  extend Service

  mattr_reader :api_key do
    MongoCluster::Configuration
        .fetch(:monitor)
        .fetch(:api_key)
        .tap {|api_key| api_key.replace(::Aws::Kms.to_plaintext(api_key)) unless api_key.blank?}
  end

  mattr_reader :service_name do
    'datadog-agent'
  end

  mattr_reader :conf_path do
    Pathname('/etc/dd-agent/datadog.conf')
  end

  mattr_reader :statsd do
    Datadog::Statsd.new('localhost', 8125)
  end

  def self.enabled?
    !api_key.blank?
  end

  def self.init
    return unless enabled?
    set_conf
    set_mongo_conf
    chkconfig_on
    restart
  end

  def self.event_exception(skip: false)
    yield
  rescue => exception
    statsd.event(exception.message, exception.backtrace, alert_type: 'error')
    raise exception unless skip
  end

  private

  def self.set_conf
    File.write(conf_path, generate_conf)
  end

  def self.set_mongo_conf
    conf_path
        .dirname
        .join('conf.d/mongo.yaml')
        .tap {|mongo_conf| File.write(mongo_conf, generate_mongo_conf)}
  end

  def self.generate_conf
    <<-EOF
[Main]
dd_url: https://app.datadoghq.com
api_key: #{api_key}
gce_updated_hostname: yes

[trace.sampler]
extra_sample_rate=1
max_traces_per_second=10

[trace.receiver]
receiver_port=8126
connection_limit=2000

[trace.ignore]
resource="GET|POST /healthcheck","GET /V1"
    EOF
  end

  def self.generate_mongo_conf
    <<-EOF
init_config:
instances:
  - server: mongodb://datadog:#{api_key}@#{MongoCluster::ReplicaSet.member.host}
    tags:
      - #{Aws::Stack.name}
    EOF
  end

end