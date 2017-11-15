require_relative 'shell'
require_relative '../aws/stack'
require_relative '../aws/s3'
require_relative 'storage'

module MongoCluster
  module Restore
    extend ExternalExecutable

    mattr_reader :path do
      #todo Add EFS path
      Pathname('/dump')
    end

    def self.from_file(host: 'localhost', port: ReplicaSet.settings.port, database_name: nil)
      shell_command = generate_shell_command(host, port, file_path(database_name))
      concat_oplog_flag(shell_command) unless database_name
      Shell.concat_login_flags(shell_command) if Shell.login?
      run(shell_command, log_file: log_file(database_name))
    end

    private

    def self.file_path(database_name)
      file_name = database_name || 'dump'
      path
          .join(file_name)
          .sub_ext('.gz')
    end

    def self.log_file(database_name)
      file_name = database_name || 'dump'
      Storage
          .mounts
          .log
          .path
          .join(file_name)
          .sub_ext('.log')
    end

    def self.concat_oplog_flag(shell_command)
      shell_command.concat(' --oplogReplay')
    end

    def self.generate_shell_command(host, port, path)
      format('mongorestore --host %s --port %s --verbose=5 --drop --gzip --archive=%s',host, port, path)
    end

  end
end