require 'aws-sdk-glacier'
require 'parallel'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'stack'
require_relative 'glacier/multi_part_file'

module Aws
  module Glacier

    mattr_reader :account_id do
      #todo find account id
    end

    mattr_reader :vault_name do
      #todo create or find vault
    end

    mattr_reader :object do
      Aws::Glacier::Client.new
    end

    def self.upload_archive(path, part_size: 16, description: Time.now.to_s, threads: 10)
      multi_part_file = MultiPartFile.new(path, part_size)
      multi_part_upload = multi_part_upload(multi_part_file, description)
      Parallel.each( -> {multi_part_file.next_part || Parallel::Stop}, in_threads: threads) do |part|
        multi_part_upload.upload_part(part)
      end
      multi_part_upload.complete(archive_size: multi_part_file.size, checksum: multi_part_file.checksum)
    end

    private

    def self.multi_part_upload(multi_part_file, description)
      object
          .initiate_multipart_upload(account_id: account_id, vault_name: vault_name, part_size: multi_part_file.part_size, archive_description: description)
          .upload_id
          .tap {|upload_id| return Aws::Glacier::MultipartUpload.new(account_id, vault_name, upload_id)}
    end

  end
end