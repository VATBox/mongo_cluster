require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require_relative 'files'

module MongoCluster
  module Dump
    class TarFile

      MEGA_BYTE = 1024 * 1024

      delegate :read, :eof?, to: :@object

      attr_reader :object
      attr_reader :path
      attr_reader :mode
      attr_reader :part_size

      def initialize(file_path)
        @object = file_path.open('rb')
        @path = file_path.relative_path_from(Files.path).to_s
        @mode = file_path.stat.mode
        @part_size = 100 * MEGA_BYTE
      end

      def write(tar)
        tar.add_file(path, mode) do |tar_file|
          tar_file.write(next_read) until eof?
        end
      end

      def next_read
        read(part_size)
      end

    end
  end
end