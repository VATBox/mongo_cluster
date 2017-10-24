require 'active_support/core_ext/class/attribute_accessors'
require_relative 'helpers/service'

module ControlGroup
  extend Service

  mattr_reader :service_name do
    'cgconfig'
  end

  mattr_reader :conf_path do
    Pathname('/etc/cgconfig.conf')
  end

  def self.init
    set_conf
    set_memory_daemon
    chkconfig_on
    start
  end

  private

  def self.set_memory_daemon
    File.write('/etc/sysconfig/mongod', 'CGROUP_DAEMON="memory:mongod"')
  end

  def self.set_conf
    File.write(conf_path, generate_cgconfig)
  end

  def self.memory_to_allocate
    total_memory - 1000000
  end

  def self.total_memory
    File
        .open('/proc/meminfo', &:readline)
        .split
        .at(1)
        .to_i
  end

  def self.generate_cgconfig
    <<-EOF
mount {
    cpuset  = /cgroup/cpuset;
    cpu     = /cgroup/cpu;
    cpuacct = /cgroup/cpuacct;
    memory  = /cgroup/memory;
    devices = /cgroup/devices;
  }

  group mongod {
    perm {
      admin {
        uid = mongod;
        gid = mongod;
      }
      task {
        uid = mongod;
        gid = mongod;
      }
    }
    memory {
      memory.limit_in_bytes = #{memory_to_allocate};
      }
  }
    EOF
  end

end