require 'aws-sdk-glacier'
require 'parallel'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'stack'
require_relative 'glacier/multi_part_file'

module Aws
  module Glacier

    mattr_reader :account_id do
      Instance::Document.fetch(:account_id)
    end

    mattr_reader :object do
      Aws::Glacier::Vault.new(account_id, Stack.name).tap do|object|
        begin
          object.load
        rescue Aws::Glacier::Errors::ResourceNotFoundException
          object.create
        end
      end
    end

    def self.upload_archive(path, part_size: 32, description: Time.now.to_s, threads: 10)
      multi_part_file = MultiPartFile.new(path, part_size)
      multi_part_upload = multi_part_upload(multi_part_file, description)
      Parallel.each( -> {multi_part_file.next_part || Parallel::Stop}, in_threads: threads) do |part|
        begin
          multi_part_upload.upload_part(part)
        rescue => exception
          multi_part_upload.abort
          raise exception
        end
      end
      multi_part_upload.complete(archive_size: multi_part_file.size, checksum: multi_part_file.checksum)
    end

    private

    def self.multi_part_upload(multi_part_file, description)
      object.initiate_multipart_upload(part_size: multi_part_file.part_size, archive_description: description)
    end

  end
end