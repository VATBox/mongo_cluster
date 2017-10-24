require 'active_support/core_ext/class/attribute_accessors'
require_relative '../aws/kms'
require_relative 'configuration'

module MongoCluster
  module Security

    mattr_reader :settings do
      OpenStruct.new(Configuration.fetch(:security)).tap do |settings|
        settings.username = ::Aws::Kms.to_plaintext(settings.username)
        settings.password = ::Aws::Kms.to_plaintext(settings.password)
      end
    end

    def self.init
      create_key_file
    end

    def self.authorization?
      settings.authorization == 'enabled'
    end

    def self.create_key_file
      FileUtils.touch(settings.keyFile)
      File.write(settings.keyFile, generate_key_file_string)
    end

    private

    def self.generate_key_file_string
      ::Aws::Kms.to_chipertext(::Aws::Stack.id)
    end

  end
end