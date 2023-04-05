require "simplecov"
SimpleCov.start {
  add_filter "/spec/"
  add_filter "/playground/"
}

ENV["RACK_ENV"] = "development"
require "rails"
require "oj_serializers"
require "types_from_serializers"
require "rspec/given"

begin
  require "pry-byebug"
rescue LoadError
end

$LOAD_PATH.push File.expand_path("../playground", __dir__)
