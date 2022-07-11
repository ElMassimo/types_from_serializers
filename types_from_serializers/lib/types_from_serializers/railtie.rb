# frozen_string_literal: true

require "rails/railtie"

# NOTE: Not strictly required, but it helps to simplify the setup.
class TypesFromSerializers::Railtie < Rails::Railtie
  railtie_name :types_from_serializers

  if Rails.env.development?
    # Automatically generates code whenever a serializer is loaded.
    initializer "types_from_serializers.reloader" do |app|
      if Rails.autoloaders.main.respond_to?(:on_load)
        require_relative "generator"
        Rails.autoloaders.main.on_load do |name, klass, abs_path|
          TypesFromSerializers.on_load(name, klass, abs_path)
        end
      else
        Rails.logger.warn "TypesFromSerializers::Railtie requires Zeitwerk as the autoloader for the Rails app to automatically generate code on changes."
      end
    end
  end

  # Suitable when triggering code generation manually.
  rake_tasks do |app|
    namespace :types_from_serializers do
      desc "Generates TypeScript interfaces for each serializer in the app."
      task generate: :environment do
        require_relative "generator"
        serializers = TypesFromSerializers.generate!(force: true)
        puts "Generated TypeScript interfaces for #{serializers.size} serializers:"
        puts serializers.map { |s| "\t#{s.name}" }.join("\n")
      end
    end
  end
end
