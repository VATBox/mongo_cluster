require_relative 'security'
require_relative 'storage'

module MongoCluster
  class Dump
    include ExternalExecutable

    %i[path host port database_name log_file].each(&method(:attr_reader))

    def initialize(database_name = nil, host: 'localhost', port: ReplicaSet.settings.port, log_file: nil)
      @path = database_name ? Aws::Efs.path : Aws::Efs.path.join('dump')
      @database_name, @host, @port, @log_file = database_name, host, port, log_file
    end

    def as_folder(**args)
      folder_flag = format(' --out=%s', path)
      to(folder_flag, **args)
      entire_instance? ? path : path.join(database_name)
    end

    def as_archive(**args)
      entire_instance? ? as_archive_all(**args) : as_archive_single(**args)
    end

    private

    def as_archive_all(**args)
      folder_path = as_folder(**args)
      Storage::Archive.new(path).to_tar
    ensure
      FileUtils.rm_r(folder_path, force: true, secure: true) if folder_path.is_a?(Pathname) && folder_path.exist?
    end

    def as_archive_single(**args)
      path.join("#{database_name}.gz").tap do |archive_path|
        archive_flag = format(' --archive=%s', archive_path)
        to(archive_flag, **args)
      end
    end

    def to(output_flag, **args)
      shell_command = generate_shell_command(host, port)
      Security.concat_login_flags(shell_command)
      entire_instance? ? concat_oplog_flag(shell_command): concat_database_flag(shell_command, database_name)
      shell_command.concat(output_flag)
      run_in_background(shell_command, log_file: log_file, **args)
    end

    def entire_instance?
      database_name.nil?
    end

    def concat_database_flag(shell_command, database_name)
      shell_command.concat(" --db #{database_name} --dumpDbUsersAndRoles")
    end

    def concat_oplog_flag(shell_command)
      shell_command.concat(' --oplog')
    end

    def generate_shell_command(host, port)
      format('mongodump --host %s --port %s --verbose=5 --numParallelCollections 2 --gzip', host, port)
    end

  end
end