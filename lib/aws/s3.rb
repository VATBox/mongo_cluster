require 'aws-sdk-s3'
require 'parallel'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'stack'
require_relative 's3/multi_part_file'

module Aws
  module S3

    mattr_reader :bucket_name do
      #todo Find in stack
      'steb-test'
    end

    mattr_reader :object do
      Aws::S3::Client.new
    end

    def self.upload_multi_part_file(path, part_size: 16, threads: 10)
      multi_part_file = MultiPartFile.new(path, part_size)
      multi_part_upload = multi_part_upload(multi_part_file.object_key)
      parts = Parallel.map( -> {multi_part_file.next_part || Parallel::Stop}, in_threads: threads) do |part|
        part.tap do |part|
          begin
            multi_part_upload
                .part(part.fetch(:part_number))
                .upload(part.extract!(:body, :content_md5))
                .tap {|upload_response| part.store(:etag, upload_response.etag)}
          rescue => exception
            multi_part_upload.abort
            raise exception
          end
        end
      end
      multi_part_upload.complete(multipart_upload: {parts: parts})
    end

    private

    def self.multi_part_upload(object_key)
      object
          .create_multipart_upload(bucket: bucket_name, key: object_key)
          .upload_id
          .tap {|upload_id| return Aws::S3::MultipartUpload.new(bucket_name, object_key, upload_id)}
    end

  end
end