require "mongo_cluster/version"
require 'yaml'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'aws/metadata'
require_relative 'aws/kms'
require_relative 'aws/instance'
require_relative 'aws/stack'
require_relative 'helpers/json_helper'
require_relative 'helpers/executable_helper'

module MongoCluster
  extend ::JsonHelper, ExecutableHelper

  mattr_reader :replica_set do
    OpenStruct.new(::Aws::Metadata.fetch('ReplicaSet')).tap do |replica_set|
      replica_set.username = ::Aws::Kms.to_plaintext(replica_set.username)
      replica_set.password = ::Aws::Kms.to_plaintext(replica_set.password)
    end
  end

  def self.restart
    run('sudo service mongod restart')
  end

  def self.create_key_file
    File.write('/mongo_auth/mongodb.key', generate_key_file_string)
  end

  def self.create_mongod_conf
    File.write('/etc/mongod.conf', conf_template.to_yaml)
  end

  def self.create_root_user
      result = Shell.eval("db.getSiblingDB(\"admin\").createUser(#{generate_root_user})")
      raise "Root user creation fail:\n #{result}" unless users.one?
  end

  def self.rs_initiate
    result = Shell.eval("rs.initiate(#{rs_default_initiate.to_json})")
    raise "ReplicaSet initiate fail:\n #{result}" unless json_parse(result).fetch(:ok) == 1
  end

  def self.rs_reconfig
    result = Shell.eval("conf = rs.conf(); conf._id = #{replica_set.name.to_json}; conf.members = #{generate_members.to_json}; rs.reconfig(conf, {force: true})")
    raise "ReplicaSet reconfig fail:\n #{result}" unless json_parse(result).fetch(:ok) == 1
  end

  def self.rs_conf
    conf = Shell.eval('JSON.stringify(rs.conf())')
    json_parse(conf)
  end

  def self.rs_status
    status = Shell.eval('JSON.stringify(rs.status())')
    json_parse(status)
  end

  def self.mongod_conf
    YAML.load_file('/etc/mongod.conf')
  end

  def self.primary?
    cast_value(Shell.eval('db.isMaster().ismaster'))
  end

  def self.auth?
    mongod_conf.dig('security','authorization') == 'enable'
  end

  def self.users
    users = Shell.eval("users = db.getSiblingDB(\"admin\").getUsers(); JSON.stringify(users)")
    json_parse(users)
  end

  private

  def self.generate_key_file_string
    ::Aws::KMS.to_ciphertext(::Aws::Stack.id)
  end

  def self.conf_template
    YAML.load_file('../assets/mongod_template.conf').tap do |template|
      template['replication']['replSetName'] = replica_set.name
      template['net']['port'] = replica_set.port
    end
  end

  def self.generate_root_user
    {
        user: replica_set.username,
        pwd: replica_set.password,
        roles: [{role: "root", db: "admin"}]
    }
  end

  def self.rs_default_initiate
    {
        _id: replica_set.name,
        members: generate_members
    }
  end

  def self.generate_members
    ::Aws::Stack.instance_logical_ids.map! do |instance_logical_id|
      ::Aws::Metadata.fetch('ReplicaSet', logical_id: instance_logical_id).tap do |member|
        member[:host].concat ":#{member.delete(:port)}"
        member[:_id] = member.delete(:id)
        member.slice!(:_id, :host, :priority, :votes, :hidden)
      end
    end
  end

end
