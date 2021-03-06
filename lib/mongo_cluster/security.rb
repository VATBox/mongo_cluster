require 'active_support/core_ext/class/attribute_accessors'
require_relative '../aws/kms'
require_relative 'configuration'

module MongoCluster
  module Security

    mattr_reader :settings do
      OpenStruct.new(Configuration.fetch(:security)).tap do |settings|
        settings.username = ::Aws::Kms.to_plaintext(settings.username)
        settings.password = ::Aws::Kms.to_plaintext(settings.password)
        key_file_plain_text = ::Aws::Kms.to_plaintext(settings.keyFile.fetch(:value))
        settings.keyFile[:value] = Base64.encode64(key_file_plain_text)
      end
    end

    def self.init
      create_key_file
    end

    def self.allow_anonymous?
      settings.authorization == 'disabled'
    end

    def self.create_key_file
      settings
          .keyFile
          .values_at(:path, :value)
          .tap do |path, value|
        path.dirname.mkpath
        FileUtils.touch(path)
        File.write(path, value)
        FileUtils.chmod(0400, path)
        FileUtils.chown_R('mongod', 'mongod', path.dirname)
      end
    end

    def self.concat_login_flags(shell_command)
      shell_command.concat(login_flags) unless allow_anonymous?
    end

    private

    def self.login_flags
      format(' --username %s --password %s --authenticationDatabase admin', settings.username, settings.password)
    end

  end
end