require 'open3'

module ExternalExecutable

  private

  def run(command, verbose: false, log_file: nil)
    Open3.popen2e(command) do |stdin, stdout_and_stderr, thread|
      begin
        stdin.close
        puts command if verbose
        stdout_and_stderr
            .each_line
            .map {|line| parse_std_line(line, verbose, log_file)}
            .join("\n")
            .tap {|stdout_and_stderr| raise stdout_and_stderr unless thread.value.success?}
      ensure
        thread.kill
      end
    end
  end

  def run_in_background(command, verbose: false, log_file: nil)
    Open3.popen2e(command) do |stdin, stdout_and_stderr, thread|
      begin
        stdin.close
        puts command if verbose
        stdout_and_stderr.each_line do |line|
          puts line if verbose
          write_to_log_file(line, log_file)
        end
        raise stdout_and_stderr unless thread.value.success?
      ensure
        thread.kill
      end
    end
  end

  private

  def parse_std_line(line, verbose, log_file)
    line
        .tap {|line| write_to_log_file(line, log_file)}
        .chomp!
        .tap {|chomp_line| puts chomp_line if verbose}
  end

  def write_to_log_file(line, log_file)
    File.write(log_file, line, mode: 'a') unless log_file.nil?
  end

end