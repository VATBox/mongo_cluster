require_relative 'json'

module Aws
  module CloudFormation
    class StackResource

      def metadata_with_cast
        JSON.parse_with_cast(metadata)
      end

    end
  end
end