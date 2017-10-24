require 'aws-sdk'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'stack'

module Aws
  module Kms

    mattr_reader :client do
      ::Aws::KMS::Client.new()
    end

    mattr_reader :key_id do
      Stack
          .client
          .resource_summaries
          .find {|resource_summary| resource_summary.resource_type == 'AWS::KMS::Key'}
          .physical_resource_id
    end

    def self.to_chipertext(plaintext)
      chipertext_blob = to_ciphertext_blob(plaintext)
      Base64.encode64(chipertext_blob)
    end

    def self.to_plaintext(ciphertext)
      ciphertext_blob = Base64.decode64(ciphertext)
      decrypt(ciphertext_blob).plaintext
    end

    def self.to_ciphertext_blob(plaintext)
      encrypt(plaintext).ciphertext_blob
    end

    private

    def self.encrypt(plaintext)
      client.encrypt(key_id: key_id, plaintext: plaintext)
    end

    def self.decrypt(ciphertext_blob)
      client.decrypt(ciphertext_blob: ciphertext_blob)
    end

  end
end
