require_relative 'security'
require_relative 'storage'
require_relative '../aws/stack'
require_relative '../aws/s3'
require_relative '../aws/efs'

module MongoCluster
  class Restore
    include ExternalExecutable

    %i[path host port input_flag].each(&method(:attr_reader))

    def initialize(restore_path, host: 'localhost', port: ReplicaSet.settings.port)
      @path, @host, @port = restore_path, host, port
    end

    def preform(*flags, **args)
      shell_command = generate_shell_command(host, port)
      concat_flags(shell_command, flags) unless flags.empty?
      Security.concat_login_flags(shell_command)
      run_in_background(shell_command, **args)
    end

    private

    def generate_shell_command(host, port)
      format('mongorestore --host %s --port %s --verbose=5 --gzip %s',host, port, input_flag)
    end

    def input_flag
      path.file? ? " --archive=#{path}" : " --dir=#{path}"
    end

    def concat_flags(shell_command, flags)
      flags
          .join(' --')
          .prepend(' --')
          .tap {|flags_string| shell_command.concat(flags_string)}
    end

  end
end