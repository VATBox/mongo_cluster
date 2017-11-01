
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mongo_cluster/version"

Gem::Specification.new do |spec|
  spec.name          = "mongo_cluster"
  spec.version       = MongoCluster::VERSION
  spec.authors       = ["Steb Veksler"]
  spec.email         = ["steb@vatbox.com"]
  spec.summary       = 'Mongo Cluster Creation'
  spec.description   = 'Create / Modify Mongo Cluster on AWS'
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir['CHANGELOG.md', 'README.rdoc', 'MIT-LICENSE', 'lib/**/*', 'exe/*', 'bin/*']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency 'aws-sdk', '~> 2'
  spec.add_dependency 'activesupport', "~> 4.2"
  spec.add_dependency 'daemons'
  spec.add_dependency 'mongo'
  spec.add_dependency 'rufus-scheduler'
end
