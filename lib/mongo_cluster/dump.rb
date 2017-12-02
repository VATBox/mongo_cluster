require_relative 'shell'
require_relative 'dump/files'
require_relative 'dump/tar'
require_relative '../aws/stack'
require_relative '../aws/s3'
require_relative '../aws/glacier'

module MongoCluster
  module Dump
    extend ExternalExecutable

    def self.to_efs(host: 'localhost', port: ReplicaSet.settings.port, database_name: nil)
      Files.clear
      shell_command = generate_shell_command(host, port, Files.path)
      database_name ? concat_database_flag(shell_command, database_name) : concat_oplog_flag(shell_command)
      Shell.concat_login_flags(shell_command) if Shell.login?
      run(shell_command, log_file: Files.path.join('dump.log'))
    end

    def self.to_tar(host: 'localhost', port: ReplicaSet.settings.port, database_name: nil)
      to_efs(host: host, port: port, database_name: database_name)
      Tar.write!
    end

    def self.to_s3(host: 'localhost', port: ReplicaSet.settings.port, database_name: nil)
      to_tar(host: host, port: port, database_name: database_name)
      Aws::S3.upload!(Tar.path)
    ensure
      Files.clear
      Tar.clear
    end

    def self.to_glacier(host: 'localhost', port: ReplicaSet.settings.port, database_name: nil)
      to_tar(host: host, port: port, database_name: database_name)
      Aws::Glacier.upload_archive(Tar.path)
    ensure
      Files.clear
      Tar.clear
    end

    private

    def self.concat_database_flag(shell_command, database_name)
      shell_command.concat(" --db #{database_name}")
    end

    def self.concat_oplog_flag(shell_command)
      shell_command.concat(' --oplog')
    end


    def self.generate_shell_command(host, port, path)
      format('mongodump --host %s --port %s --verbose=5 --numParallelCollections 8 --gzip --out=%s',host, port, path)
    end

  end
end