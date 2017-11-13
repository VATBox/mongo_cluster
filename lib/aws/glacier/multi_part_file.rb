require 'treehash'
require 'active_support/core_ext/module/delegation'

module Aws
  module Glacier
    class MultiPartFile

      delegate :eof?, :read, :rewind, :size, to: :@object

      MEGA_BYTE = 1024 * 1024

      %i[object checksum part_numbers_queue part_size total_parts].each do |attr|
        attr_reader attr
      end

      def initialize(path, part_size)
        @object = path.open
        @checksum = Treehash::calculate_tree_hash(object)
        rewind
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
            body: body,
            checksum: Treehash::calculate_tree_hash(body),
            range: part_range(part_number, body.size)
        }
      end

      private

      def part_range(part_number, body_size)
        range_begin = (part_number - 1) * part_size
        range_end = range_begin + body_size - 1
        format('bytes %s-%s/*', range_begin, range_end)
      end

      def queue_and_read_synced!
        raise format('Part Queue: %s, EOF?: %s', part_numbers_queue, eof?) unless part_numbers_queue.empty? == eof?
      end

    end
  end
end