require 'rubygems/package'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require_relative '../../aws/efs'
require_relative 'tar_file'

module MongoCluster
  module Storage
    class Archive

      %i[path_to_archive archive_name queue].each(&method(:attr_reader))

      def initialize(path, archive_name: path.basename)
        @path_to_archive, @archive_name, @queue = path, archive_name, Queue.new
        all.each {|file| queue.push(TarFile.new(file, path_to_archive))}
      end

      def to_tar_gz(path = tar_gz_path)
        path.tap do |path|
          path.open('wb') do |tar_gz|
            Zlib::GzipWriter.wrap(tar_gz) do |gz|
              to_tar(gz)
            end
          end
        end
      rescue => exception
        path.delete if path.exist?
        raise exception
      end

      def to_tar(path = tar_path)
        path.tap do |path|
          path = path.open('wb') unless path.is_a?(Zlib::GzipWriter)
          Gem::Package::TarWriter.new(path) do |tar|
            directories_names.each {|directory_name| tar.mkdir(directory_name, 33188)}
            next_file.write(tar) until queue.empty?
          end
        end
      rescue => exception
        path.delete unless path.is_a?(Zlib::GzipWriter) || !path.exist?
        raise exception
      end

      private

      def tar_path
        Aws::Efs
            .path
            .join(archive_name)
            .sub_ext('.tar')
      end

      def tar_gz_path
        tar_path.sub_ext('.tar.gz')
      end

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