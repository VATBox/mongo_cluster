require 'net/http'
require 'active_support/core_ext/class/attribute_accessors'
require_relative '../../helpers/json'

module Aws
  class Instance
    module Document

      mattr_reader :uri do
        URI.parse('http://169.254.169.254/latest/dynamic/instance-identity/document')
      end

      mattr_reader :object do
        JSON
            .parse_with_cast(Net::HTTP.get(uri))
            .transform_keys!(&:underscore)
            .tap {|document| ENV['AWS_REGION'] = document.fetch(:region)}
      end

      def self.fetch(key)
        object.fetch(key)
      end

    end

  end
end