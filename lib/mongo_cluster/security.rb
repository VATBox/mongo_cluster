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

    def self.authorization?
      settings.authorization == 'enabled'
    end

    def self.create_key_file
      settings.keyFile.values_at(:path, :value).tap do |path, value|
        path.dirname.mkpath
        FileUtils.touch(path)
        File.write(path, value)
        FileUtils.chmod(0400, path)
        FileUtils.chown_R('mongod', 'mongod', path.dirname)
      end
    end

  end
end