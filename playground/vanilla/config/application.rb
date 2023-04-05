require_relative "boot"

require "action_controller/railtie"
require "active_record/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

begin
  require "pry-byebug"
rescue LoadError, NameError
end

module SampleApp
  class Application < Rails::Application
    config.autoloader = :zeitwerk
  end
end
