require 'active_support/core_ext/class/attribute_accessors'
require_relative 'configuration'
require_relative 'shell'
require_relative 'user'
require_relative '../helpers/json'

module MongoCluster
  module ReplicaSet

    mattr_reader :settings do
      OpenStruct.new(Configuration.fetch(:replication)).tap do |settings|
        settings.size += 1 if Configuration.fetch(:backup).fetch(:enabled)
      end
    end

    mattr_reader :member do
      OpenStruct.new(::Aws::Instance.metadata.fetch(:ReplicaMember))
    end

    def self.init
      initiate
      wait_to_become_primary
      User.create_root unless Shell.login?
      User.create_data_dog
      status
    rescue Exception => exception
      raise exception unless exception.message == 'AlreadyInitialized'
      reconfig
      status
    end

    def self.initiate
      result = Shell.eval("rs.initiate(#{rs_default_initiate.to_json})")
      confirm_result(result)
    end

    def self.reconfig
      result = Shell.eval("conf = rs.conf(); conf._id = #{settings.name.to_json}; conf.members = #{generate_members.to_json}; rs.reconfig(conf, {force: true})")
      confirm_result(result)
    end

    def self.conf
      conf = Shell.eval('JSON.stringify(rs.conf())')
      JSON.parse_with_cast(conf)
    end

    def self.status
      status = Shell.eval('JSON.stringify(rs.status())')
      JSON.parse_with_cast(status)
    end

    def self.primary?
      is_master.fetch(:ismaster)
    end

    def self.is_master
      is_master = Shell.eval('JSON.stringify(db.isMaster())')
      JSON.parse_with_cast(is_master)
    end

    def self.primary_step_down(duration)
      primary_host.split(':').tap do |host, port|
        begin
          result = Shell.eval("rs.stepDown(#{duration})", host: host, port: port)
          confirm_result(result)
        rescue => exception
          raise exception unless exception.message.match("network error while attempting to run command 'replSetStepDown' on host '#{host}:#{port}'")
        end
      end
    end

    def self.primary_instance
      primary_host
          .split(':')
          .first
          .tap do |primary_ip|
        return Aws::Instance.all.find {|instance| instance.private_ip_address == primary_ip}
      end
    end

    def self.primary_host
      status
          .fetch(:members)
          .find {|member| member.fetch(:state) == 1}
          .fetch(:name)
    end

    private

    def self.rs_default_initiate
      {
          _id: settings.name,
          members: generate_members
      }
    end

    def self.generate_members
      ::Aws::Instance
          .all_resources
          .map! {|instance_resource| instance_resource.metadata_with_cast.fetch(:ReplicaMember)}
          .each {|member| member[:_id] = member.delete(:id)}
    end

    def self.wait_to_become_primary
      Timeout::timeout(60) do
        until primary?
          sleep(5)
        end
      end
    end

    def self.confirm_result(result)
      JSON
          .parse_with_cast(result)
          .tap {|result| raise result.fetch(:codeName) if result.fetch(:ok).zero?}
    end

  end
end