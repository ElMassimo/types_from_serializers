# frozen_string_literal: true

# Splitting the generator file allows consumers to skip the Railtie if desired:
#  - gem 'types_from_serializers', require: false
#  - require 'types_from_serializers/generator'
require_relative "types_from_serializers/version"
require_relative "types_from_serializers/railtie"
require_relative "types_from_serializers/generator" if Rails.env.development?
