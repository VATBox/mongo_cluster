require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'

module MongoCluster
  module Storage
    class TarFile

      MEGA_BYTE = 1024 * 1024

      delegate :read, :eof?, to: :@object

      attr_reader :object
      attr_reader :path
      attr_reader :mode
      attr_reader :part_size

      def initialize(file_path, path_to_archive)
        @object = file_path.open('rb')
        @path = file_path.relative_path_from(path_to_archive).to_s
        @mode = file_path.stat.mode
        @part_size = 100 * MEGA_BYTE
      end

      def write(tar)
        tar.add_file_simple(path, mode, object.size) do |tar_file|
          tar_file.write(next_read) until eof?
        end
      end

      def next_read
        read(part_size)
      end

    end
  end
end