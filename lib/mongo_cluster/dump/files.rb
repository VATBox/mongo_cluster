require 'rubygems/package'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require_relative '../../aws/efs'

module MongoCluster
  module Dump
    class Files

      cattr_reader :path do
        Aws::Efs
            .path
            .join('dump')
            .tap(&:mkpath)
      end

      cattr_accessor :tar_path do
        path.join('dump.tar')
      end

      attr_reader :queue

      def initialize
        @queue = Queue.new
        path
            .children
            .map! {|child| child.directory? ? child.children : child}
            .flatten!
            .sort_by!(&:size)
            .each {|file_path| queue.push(file_path)}
      end

      def self.to_tar
        files = self.new
        Gem::Package::TarWriter.new(tar_path.open('w')) do |tar|
          files.directories_names.each {|directory_name| tar.mkdir(directory_name, 33188)}
          while(file = files.next_file) do
            tar.add_file(file.relative_path_from(path).to_s, file.stat.mode) {|tar_file| tar_file.write file.read}
          end
        end
      end

      def directories_names
        path
            .children
            .keep_if(&:directory?)
            .map!(&:basename)
            .map!(&:to_s)
      end

      def next_file
        return if queue.empty?
        queue.shift
      end

    end
  end
end