require 'active_support/core_ext/module/delegation'

module Aws
  module S3
    class MultiPartFile

      delegate :basename, :eof?, :read, :rewind, :size, to: :@object

      MEGA_BYTE = 1024 * 1024

      %i[object object_key part_numbers_queue part_size total_parts].each do |attr|
        attr_reader attr
      end

      def initialize(path, part_size)
        @object = path.open
        @object_key = path.basename.to_s
        @part_size = part_size * MEGA_BYTE
        @total_parts = (size.to_f / @part_size).ceil
        @part_numbers_queue = Queue.new
        Range.new(1, total_parts).each {|part_number| part_numbers_queue.push(part_number)}
      end

      def next_part
        queue_and_read_synced!
        return if part_numbers_queue.empty? && eof?
        part_number = part_numbers_queue.shift
        body = read(part_size)
        {
            part_number: part_number,
            body: body,
            content_md5: Digest::MD5.base64digest(body),
        }
      end

      private

      def queue_and_read_synced!
        raise format('Part Queue: %s, EOF?: %s', part_numbers_queue, eof?) unless part_numbers_queue.empty? == eof?
      end

    end
  end
end