require_relative 'external_executable'

module Service
  include ExternalExecutable


  %i[start stop restart].each do |action|
    define_method(action) {run("service #{service_name} #{action}")}
  end

  %i[on off].each do |state|
    define_method("chkconfig_#{state}") {run("chkconfig #{service_name} #{state}")}
  end

  def chkconfig_add
    run("chkconfig --add #{service_name}")
  end


  def link_daemon_to_init_d
    FileUtils.ln_s(daemon_path, '/etc/init.d/', force: true)
  end

  def append_chkconfig
    daemon_path
        .readlines
        .each(&:chomp!)
        .delete_if {|line| line =~ /chkconfig/}
        .tap {|lines| lines.first.concat(chkconfig_parameters)}
        .join("\n")
        .tap {|daemon_string| File.write(daemon_path, daemon_string)}
  end

  def daemon_path
    Pathname('/usr/local/bin').join(service_name)
  end

  def chkconfig_parameters
    "\n# chkconfig: 2345 20 80"
  end

  def service_name
    raise 'Missing service name'
  end

end