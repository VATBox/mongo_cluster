require 'yaml'
require_relative 'mongo_cluster/dump'
require_relative 'mongo_cluster/security'
require_relative 'mongo_cluster/storage'
require_relative 'mongo_cluster/replica_set'
require_relative 'aws/s3'
require_relative 'helpers/service'

module MongoCluster
  extend Service

  mattr_reader :service_name do
    'mongod'
  end

  mattr_reader :conf_path do
    Pathname('/etc/mongod.conf')
  end

  def self.init
    Storage.init
    Security.init
    set_conf
    restart
    chkconfig_on
  end

  def self.databases
    databases = Shell.eval('db.adminCommand({listDatabases: 1}).databases')
    JSON.parse_with_cast(databases)
  end

  def self.read_conf
    YAML.load_file(conf_path)
  end

  def self.dump_to_s3
    archive_path = Dump.new.as_archive
    Aws::S3.upload!(archive_path)
  ensure
    archive_path.delete if archive_path.is_a?(Pathname) && archive_path.exist?
  end

  private

  def self.set_conf
    File.write(conf_path, generate_conf)
  end

  def self.generate_conf
    <<-EOF
net:
  port: #{ReplicaSet.member.host.split(':').last}

systemLog:
  destination: file
  logAppend: true
  path: #{Storage.mounts.log.path.join('mongod.log')}
  traceAllExceptions: false
  component:
    accessControl:
      verbosity: 0
    command:
      verbosity: 0
    control:
      verbosity: 0
    ftdc:
      verbosity: 0
    geo:
      verbosity: 0
    index:
      verbosity: 1
    network:
      verbosity: 0
    query:
      verbosity: 1
    replication:
      verbosity: 0
    sharding:
      verbosity: 0
    storage:
      verbosity: 0
    write:
      verbosity: 1

storage:
  directoryPerDB: true
  dbPath: #{Storage.mounts.data.path}
  journal:
    enabled: true

security:
  keyFile: #{Security.settings.keyFile.fetch(:path)}
  transitionToAuth: #{Security.allow_anonymous?}

processManagement:
  fork: true
  pidFilePath: #{Storage.run_path.join('mongod.pid')}

replication:
  replSetName: #{ReplicaSet.settings.name}
    EOF
  end

end
