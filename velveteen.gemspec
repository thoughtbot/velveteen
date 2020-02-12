require_relative "lib/velveteen/version"

Gem::Specification.new do |spec|
  spec.name = "velveteen"
  spec.version = Velveteen::VERSION
  spec.authors = ["Chris Thorn", "May Miller-Ricci"]
  spec.email = ["thorn@thoughtbot.com", "may@thoughtbot.com"]

  spec.summary = "Transform your background jobs into a real data pipeline with Velveteen."
  spec.description = "Velveteen provides a lightweight, opinionated framework for setting up a RabbitMQ data pipeline in Ruby."
  spec.homepage = "https://github.com/thoughtbot/velveteen"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "bunny", "~> 2.14"
end
