require_relative '../helpers/executable_helper'

module MongoCluster::Shell
  extend ExecutableHelper

  def self.eval(cmd)
    shell_command = format('mongo %s --eval \'%s\'', flags, cmd)
    shell_command.concat(login_flags) if ::MongoCluster.auth?
    run(shell_command)
  end

  private

  def self.flags
    format('--host %s --port %s --quiet', ::MongoCluster.replica_set.host, ::MongoCluster.replica_set.port)
  end

  def self.login_flags
    format(' --username %s --password %s --authenticationDatabase admin', ::MongoCluster.replica_set.username, ::MongoCluster.replica_set.password)
  end

end