require 'open3'

module ExternalExecutable

  private

  def run(command)
    stdout_and_stderr, status = Open3.capture2e(command)
    raise stdout_and_stderr unless status.success?
    stdout_and_stderr.chomp!
  end

end