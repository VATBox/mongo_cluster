require_relative 'security'
require_relative 'replica_set'
require_relative '../helpers/external_executable'

module MongoCluster
  module Shell
    extend ExternalExecutable

    def self.eval(cmd, host: 'localhost', port: ReplicaSet.settings.port, skip_login: false, **args)
      shell_command = generate_shell_command(host, port, cmd)
      Security.concat_login_flags(shell_command) unless skip_login
      run(shell_command, **args)
    end

    def self.root_login?
      generate_shell_command('localhost', ReplicaSet.settings.port, 'db.getName()').tap do |shell_command|
        shell_command.concat(Security.send(:login_flags))
        run(shell_command)
      end
      true
    rescue
      false
    end

    private

    def self.generate_shell_command(host, port, cmd)
      format('mongo admin --host %s --port %s --quiet --eval \'%s\'',host, port, cmd)
    end

  end
end