require 'rubygems/package'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute_accessors'
require_relative '../../aws/efs'

module MongoCluster
  module Dump
    module Files

      mattr_reader :path do
        Aws::Efs
            .path
            .join('dump')
      end

      def self.clear
        FileUtils.rm_r(path, force: true) if path.exist?
        path.mkpath
      end

      def self.all
        path
            .children
            .map! {|child| child.directory? ? child.children : child}
            .flatten!
            .sort_by!(&:size)
      end

      def self.directories_names
        path
            .children
            .keep_if(&:directory?)
            .map!(&:basename)
            .map!(&:to_s)
      end

    end
  end
end