require_relative '../helpers/external_executable'

module Aws
  module Metadata
    extend ExternalExecutable

    def self.fetch(name)
      run("ec2-metadata --#{name}")
          .split(': ')
          .last
    end

  end
end
