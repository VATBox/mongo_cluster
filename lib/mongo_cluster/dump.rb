require_relative 'shell'
require_relative '../aws/stack'
require_relative '../aws/s3'

module MongoCluster
  module Dump
    extend ExternalExecutable

    mattr_reader :path do
      #todo Add EFS path
      Pathname('/dump')
    end

    def self.to_file(host: 'localhost', port: ReplicaSet.settings.port, database_name: nil)
      shell_command = generate_shell_command(host, port, file_path(database_name))
      database_name ? concat_database_flag(shell_command, database_name) : concat_oplog_flag(shell_command)
      Shell.concat_login_flags(shell_command) if Shell.login?
      run(shell_command, log_file: log_path(database_name))
    end

    def self.to_s3(host: 'localhost', port: ReplicaSet.settings.port, database_name: nil)
      to_file(host: host, port: port, database_name: database_name)
      Aws::S3.upload_multi_part_file(path, part_size: 100, threads: 20)
    end

    private

    def self.file_path(database_name)
      file_name = database_name || 'dump'
      path
          .join(file_name)
          .sub_ext('.gz')
    end

    def self.log_path(database_name)
      file_name = database_name || 'dump'
      Storage
          .mounts
          .log
          .path
          .join(file_name)
          .sub_ext('.gz')
    end

    def self.concat_database_flag(shell_command, database_name)
      shell_command.concat(" --db #{database_name}")
    end

    def self.concat_oplog_flag(shell_command)
      shell_command.concat(' --oplog')
    end

    def self.generate_database_path(database_name)
      path
          .dirname
          .join(database_name)
          .sub_ext('.gz')
    end

    def self.generate_shell_command(host, port, path)
      format('mongodump --host %s --port %s --verbose=5 --gzip --archive=%s',host, port, path)
    end

  end
end