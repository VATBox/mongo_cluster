require 'rubygems/package'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require_relative '../../aws/efs'
require_relative 'files'
require_relative 'tar_file'

module MongoCluster
  module Dump
    class Tar

      cattr_reader :path do
        Aws::Efs
            .path
            .join('dump.tar')
      end

      delegate :mkdir, :close, to: :@object

      attr_reader :object
      attr_reader :queue

      def initialize
        @object = Gem::Package::TarWriter.new(path.open('w'))
        @queue = Queue.new
        Files
            .all
            .each {|file_path| queue.push(TarFile.new(file_path))}
      end

      def self.write!
        self.new.write!
      end

      def self.clear
        path.delete if path.exist?
      end

      def write!
        make_directories
        next_file.write(object) until queue.empty?
      ensure
        close
      end

      private

      def make_directories
        Files
            .directories_names
            .each {|directory_name| mkdir(directory_name, 33188)}
      end

      def next_file
        queue.shift
      end

    end
  end
end