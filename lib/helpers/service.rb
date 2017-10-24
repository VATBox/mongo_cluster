require_relative 'external_executable'

module Service
  include ExternalExecutable


  %i[start stop restart].each do |action|
    define_method(action) {run("service #{service_name} #{action}")}
  end

  %i[on off].each do |state|
    define_method("chkconfig_#{state}") {run("chkconfig #{service_name} #{state}")}
  end

  def service_name
    raise 'Missing service name'
  end

end