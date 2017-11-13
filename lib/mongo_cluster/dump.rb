require_relative 'shell'
require_relative '../aws/stack'
require_relative '../aws/s3'

module MongoCluster
  module Dump
    extend ExternalExecutable

    mattr_reader :path do
      #todo Add EFS path
      Pathname('/tmp/dump.tar.gz')
    end

    def self.to_file(host: 'localhost', port: ReplicaSet.settings.port)
      path.delete
      shell_command = generate_shell_command(host, port, path)
      shell_command.concat(login_flags) if Shell.login?
      run(shell_command)
    end

    def self.to_s3(host: 'localhost', port: ReplicaSet.settings.port)
      to_file(host: host, port: port)
      Aws::S3.upload_multi_part_file(path, part_size: 100, threads: 20)
    end

    private

    def self.generate_shell_command(host, port, path)
      format('mongodump --host %s --port %s --verbose --oplog --gzip --archive=%s',host, port, path)
    end

  end
end