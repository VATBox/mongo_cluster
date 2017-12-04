require 'rubygems/package'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require_relative '../../aws/efs'
require_relative 'tar_file'

module MongoCluster
  module Storage
    class Archive

      cattr_reader :path do
        Aws::Efs
            .path
            .join('archive.tar.gz')
      end

      attr_reader :path_to_archive
      attr_reader :queue

      def initialize(path)
        @path_to_archive = path
        @queue = Queue.new
        all.each {|file| queue.push(TarFile.new(file, path_to_archive))}
      end

      def to_efs
        clear
        path.open('wb') do |tar_gz|
          Zlib::GzipWriter.wrap(tar_gz) do |gz|
            Gem::Package::TarWriter.new(gz) do |tar|
              directories_names.each {|directory_name| tar.mkdir(directory_name, 33188)}
              next_file.write(tar) until queue.empty?
            end
          end
        end
      end

      def to_s3
        to_efs
        Aws::S3.upload!(path)
      ensure
        clear
      end

      def clear
        path.delete if path.exist?
      end

      private

      def all
        path_to_archive
            .children
            .map! {|child| child.directory? ? child.children : child}
            .flatten!
            .sort_by!(&:size)
      end

      def directories_names
        path_to_archive
            .children
            .keep_if(&:directory?)
            .map!(&:basename)
            .map!(&:to_s)
      end

      def next_file
        queue.shift
      end

    end
  end
end