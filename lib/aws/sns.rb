require 'aws-sdk-sns'
require_relative 'stack'

module Aws
  module Sns

    mattr_reader :arn do
      Stack
          .object
          .resource_summaries
          .find {|resource_summary| resource_summary.resource_type == 'AWS::SNS::Topic'}
          .physical_resource_id
    end

    mattr_reader :object do
      Aws::SNS::Topic.new(arn)
    end

    def self.publish(message)
      object.publish(message: message)
    end

    def self.publish_exception(skip: false)
      yield
    rescue => exception
      publish(generate_exception_message(exception))
      raise exception unless skip
    end

    private

    def self.generate_exception_message(exception)
      format("Message:\n%s\n\nBacktrace:\n%s",exception.message, exception.backtrace.join("\n"))
    end

  end
end
