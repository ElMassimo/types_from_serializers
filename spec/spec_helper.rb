require "simplecov"
SimpleCov.start {
  skip "/spec/"
  skip "/playground/"
}

ENV["RACK_ENV"] = "development"
require "rails"
require "oj_serializers"
require "types_from_serializers"
require "rspec/given"

require_relative "support/snapshot_matcher"

$LOAD_PATH.push File.expand_path("../playground", __dir__)
