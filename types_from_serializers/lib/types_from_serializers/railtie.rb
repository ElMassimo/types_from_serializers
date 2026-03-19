# frozen_string_literal: true

require "rails/railtie"

class TypesFromSerializers::Railtie < Rails::Railtie
  railtie_name :types_from_serializers

  # Automatically generates code whenever a serializer is loaded.
  if defined?(Rails.env) && Rails.env.development?
    require_relative "generator"

    initializer "types_from_serializers.reloader" do |app|
      if Gem.loaded_specs["listen"]
        require "listen"

        app.config.after_initialize do
          TypesFromSerializers.all_changes.each do |changes|
            app.reloaders << changes
          end
        end

        app.config.to_prepare do
          TypesFromSerializers.generate_all_changed
        end
      else
        app.config.to_prepare do
          TypesFromSerializers.generate_all
        end

        Rails.logger.warn "Add 'listen' to your Gemfile to automatically generate code on serializer changes."
      end
    end
  end

  # Suitable when triggering code generation manually.
  rake_tasks do |app|
    namespace :types_from_serializers do
      desc "Generates TypeScript interfaces for each serializer in the app."
      task generate: :environment do
        require_relative "generator"
        start_time = Time.zone.now
        print "Generating TypeScript interfaces..."
        TypesFromSerializers.generate_all(force: true)
        puts "completed in #{(Time.zone.now - start_time).round(2)} seconds."
      end
    end
  end
end
