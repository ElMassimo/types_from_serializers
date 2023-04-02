require File.expand_path("../lib/types_from_serializers/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "types_from_serializers"
  s.version = TypesFromSerializers::VERSION
  s.authors = ["Máximo Mussini"]
  s.email = ["maximomussini@gmail.com"]
  s.summary = "Generate TypeScript interfaces from your JSON serializers."
  s.description = "types_from_serializers helps you by automatically generating TypeScript interfaces for your JSON serializers, allowing you typecheck your frontend code to ship fast and with confidence."
  s.homepage = "https://github.com/ElMassimo/types_from_serializers"
  s.license = "MIT"
  s.extra_rdoc_files = ["README.md"]
  s.files = Dir.glob("{lib,exe,templates}/**/*") + %w[README.md CHANGELOG.md LICENSE.txt]
  s.require_path = "lib"

  s.add_dependency "railties", ">= 5.1"
  s.add_dependency "oj_serializers", ">= 2.0.2", "~> 2.0"
  s.add_dependency "listen", "~> 3.2"

  s.add_development_dependency "bundler", "~> 2"
  s.add_development_dependency "pry-byebug", "~> 3.9"
  s.add_development_dependency "rake", "~> 13"
  s.add_development_dependency "rspec-given", "~> 3.8"
  s.add_development_dependency "rspec-snapshot"
  s.add_development_dependency "simplecov", "< 0.18"
  s.add_development_dependency "standard", "~> 1.0"
  s.add_development_dependency "activerecord"
  s.add_development_dependency "js_from_routes"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "rubocop-rails"
  s.add_development_dependency "rubocop-rspec"
  s.add_development_dependency "rubocop-performance"
end
