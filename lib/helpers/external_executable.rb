require 'open3'

module ExternalExecutable

  private

  def run(command, log_file: nil)
    Open3.popen2e(command) do |stdin, stdout_and_stderr, thread|
      stdin.close
      puts command
      stdout_and_stderr
          .each_line
          .map {|line| parse_std_line(line, log_file)}
          .join("\n")
          .tap {|stdout_and_stderr| raise stdout_and_stderr unless thread.value.success?}
    end
  end

  private

  def parse_std_line(line, log_file)
    line
        .tap {|line | write_to_log_file(line, log_file)}
        .chomp!
        .tap(&method(:puts))
  end

  def write_to_log_file(line, log_file)
    File.write(log_file, line, mode: 'a') unless log_file.nil?
  end

end