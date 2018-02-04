require 'active_support/core_ext/class/attribute_accessors'
require_relative '../data_dog'
require_relative 'configuration'
require_relative 'storage'
require_relative '../helpers/service'
require_relative '../aws/instance'

module MongoCluster
  module Logs
    extend Service

    mattr_reader :service_name do
      'fluentd_agent'
    end

    mattr_reader :path do
      Storage
          .mounts
          .log
          .path
          .join('mongod.log')
    end

    mattr_reader :delivery_stream do
      Configuration
          .fetch(:logs)
          .fetch(:delivery_stream)
    end

    mattr_reader :conf_path do
      Pathname('/etc/fluent/fluent.conf')
    end

    def self.init
      return unless enabled?
      set_conf
      append_chkconfig
      link_daemon_to_init_d
      chkconfig_add
      DataDog.append_process_conf(service_name) if DataDog.enabled?
      restart
    end

    def self.enabled?
      !delivery_stream.blank?
    end

    private

    def self.set_conf
      conf_path.dirname.mkpath
      File.write(conf_path, generate_conf)
    end

    def self.generate_conf
      <<-EOF
<source>
  @type tail
  path #{path}
  pos_file #{path.to_s.concat('.pos')}
  tag mongodb.log
  <parse>
    @type multiline_grok
    time_key timestamp
    keep_time_key false
    grok_pattern %{MONGO3_LOG}
  </parse>
</source>

<filter mongodb.log>
  @type record_modifier
  <record>
    @metadata ${{index: 'mongodb'}}
    environment #{Aws::Instance.enviornment}
    instance #{Aws::Instance.new.tag('Name')}
  </record>
</filter>

<match mongodb.log>
  @type kinesis_firehose
  region #{Aws::Instance::Document.fetch(:region)}
  delivery_stream_name #{delivery_stream}
  <inject>
    time_key @timestamp
    time_type string
    hostname_key hostname
  </inject>
</match>
      EOF
    end

  end
end