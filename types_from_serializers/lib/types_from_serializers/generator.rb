# frozen_string_literal: true

require "digest"
require "fileutils"
require "pathname"

# Public: Automatically generates TypeScript interfaces for Ruby serializers.
module TypesFromSerializers
  # Internal: Extensions that simplify the implementation of the generator.
  module SerializerRefinements
    refine String do
      # Internal: Converts a name such as :user to the User constant.
      def to_model
        classify.safe_constantize
      end
    end

    refine Symbol do
      def safe_constantize
        to_s.classify.safe_constantize
      end

      def to_model
        to_s.to_model
      end
    end

    refine Class do
      # Internal: Name of the TypeScript interface.
      def ts_name
        TypesFromSerializers.config.name_from_serializer.call(name).tr_s(":", "")
      end

      # Internal: The base name of the TypeScript file to be written.
      def ts_filename
        TypesFromSerializers.config.name_from_serializer.call(name).gsub("::", "/")
      end

      # Internal: The columns corresponding to the serializer model, if it's a
      # record.
      def model_columns
        @model_columns ||= _serializer_model_name&.to_model.try(:columns_hash) || {}
      end

      # Internal: The TypeScript properties of the serialzeir interface.
      def ts_properties
        @ts_properties ||= begin
          types_from = try(:_serializer_types_from)

          prepare_attributes(sort_by: :name)
            .flat_map { |key, options|
              if options[:association] == :flat
                options.fetch(:serializer).ts_properties
              else
                Property.new(
                  name: key,
                  type: options[:serializer] || options[:type],
                  optional: options[:optional] || options.key?(:if),
                  multi: options[:association] == :many,
                  column_name: options.fetch(:value_from),
                ).tap do |property|
                  property.infer_type_from(model_columns, types_from)
                end
              end
            }
        end
      end

      # Internal: A first pass of gathering types for the serializer attributes.
      def ts_interface
        @ts_interface ||= Interface.new(
          name: ts_name,
          filename: ts_filename,
          properties: ts_properties,
        )
      end
    end
  end

  # Internal: The configuration for TypeScript generation.
  Config = Struct.new(
    :base_serializers,
    :serializers_dirs,
    :output_dir,
    :custom_types_dir,
    :name_from_serializer,
    :native_types,
    :sql_to_typescript_type_mapping,
    keyword_init: true,
  ) do
    def custom_types_dir
      @relative_custom_types_dir ||= (@custom_types_dir || output_dir)
        .relative_path_from(output_dir)
    end

    def unknown_type
      sql_to_typescript_type_mapping.default
    end
  end

  # Internal: Information to generate a TypeScript interface for a serializer.
  Interface = Struct.new(
    :name,
    :filename,
    :properties,
    keyword_init: true,
  ) do
    using SerializerRefinements

    def inspect
      to_h.inspect
    end

    # Internal: Returns a list of imports for types used in this interface.
    def used_imports
      association_serializers, attribute_types = properties.map(&:type).compact.uniq
        .partition { |type| type.respond_to?(:ts_interface) }

      serializer_type_imports = association_serializers.map(&:ts_interface)
        .map { |type| [type.name, type.import_path_from(filename)] }

      custom_type_imports = attribute_types
        .flat_map { |type| extract_typescript_types(type.to_s) }
        .uniq
        .reject { |type| native_type?(type) }
        .map { |type|
          type_path = TypesFromSerializers.config.custom_types_dir.join(type)
          [type, type_path.relative_path_from(filename)]
        }

      (custom_type_imports + serializer_type_imports)
        .map { |interface, filename| "import type #{interface} from '#{filename}'\n" }
    end

    def as_typescript
      <<~TS
        interface #{name} {
          #{properties.index_by(&:name).values.map(&:as_typescript).join("\n  ")}
        }
      TS
    end

  protected

    # Internal: Name of the TypeScript file that defines the type for this serializer.
    def import_path_from(importer_path)
      path = Pathname.new(filename).relative_path_from(Pathname.new(importer_path).parent).to_s
      path.start_with?(".") ? path : "./#{path}"
    end

    # Internal: Extracts any types inside generics or array types.
    def extract_typescript_types(type)
      type.split(/[<>\[\],\s|]+/)
    end

    # NOTE: Treat uppercase names as custom types.
    # Lowercase names would be native types, such as :string and :boolean.
    def native_type?(type)
      type[0] == type[0].downcase || TypesFromSerializers.config.native_types.include?(type)
    end
  end

  # Internal: The type metadata for a serializer attribute.
  Property = Struct.new(
    :name,
    :type,
    :optional,
    :multi,
    :column_name,
    keyword_init: true,
  ) do
    using SerializerRefinements

    def inspect
      to_h.inspect
    end

    # Internal: Infers the property's type by checking a corresponding SQL
    # column, or falling back to a TypeScript interface if provided.
    def infer_type_from(columns_hash, ts_interface)
      if type
        type
      elsif (column = columns_hash[column_name.to_s])
        self.multi = true if column.try(:array)
        self.optional = true if column.null && !column.default
        self.type = TypesFromSerializers.config.sql_to_typescript_type_mapping[column.type]
      elsif ts_interface
        self.type = "#{ts_interface}['#{name}']"
      end
    end

    def as_typescript
      type_str = if type.respond_to?(:ts_name)
        type.ts_name
      else
        type || TypesFromSerializers.config.unknown_type
      end

      "#{name}#{"?" if optional}: #{type_str}#{"[]" if multi}"
    end
  end

  # Internal: Structure to keep track of changed files.
  class Changes
    def initialize(dirs)
      @added = Set.new
      @removed = Set.new
      @modified = Set.new
      track_changes(dirs)
    end

    def updated?
      @modified.any? || @added.any? || @removed.any?
    end

    def any_removed?
      @removed.any?
    end

    def modified_files
      @modified
    end

    def only_modified?
      @added.empty? && @removed.empty?
    end

    def clear
      @added.clear
      @removed.clear
      @modified.clear
    end

  private

    def track_changes(dirs)
      Listen.to(*dirs, only: %r{.rb$}) do |modified, added, removed|
        modified.each { |file| @modified.add(file) }
        added.each { |file| @added.add(file) }
        removed.each { |file| @removed.add(file) }
      end.start
    end
  end

  class << self
    using SerializerRefinements

    attr_reader :force_generation

    # Public: Configuration of the code generator.
    def config
      (@config ||= default_config(root)).tap do |config|
        yield(config) if block_given?
      end
    end

    # Public: Generates code for all serializers in the app.
    def generate(force: ENV["SERIALIZER_TYPES_FORCE"])
      @force_generation = force
      config.output_dir.rmtree if force && config.output_dir.exist?
      generate_index_file

      loaded_serializers.each do |serializer|
        generate_interface_for(serializer)
      end
    end

    def generate_changed
      if changes.updated?
        config.output_dir.rmtree if changes.any_removed?
        load_serializers(changes.modified_files)
        generate
        changes.clear
      end
    end

    # Internal: Defines a TypeScript interface for the serializer.
    def generate_interface_for(serializer)
      interface = serializer.ts_interface

      write_if_changed(filename: interface.filename, cache_key: interface.inspect) {
        serializer_interface_content(interface)
      }
    end

    # Internal: Allows to import all serializer types from a single file.
    def generate_index_file
      cache_key = all_serializer_files.map { |file| file.delete_prefix(root.to_s) }.join
      write_if_changed(filename: "index", cache_key: cache_key) {
        load_serializers(all_serializer_files)
        serializers_index_content(loaded_serializers)
      }
    end

    # Internal: Checks if it should avoid generating an interface.
    def skip_serializer?(serializer)
      serializer.name.include?("BaseSerializer") ||
        serializer.name.in?(config.base_serializers) ||
        # NOTE: Ignore inline serializers.
        serializer.ts_name.include?("Serializer")
    end

    # Internal: Returns an object compatible with FileUpdateChecker.
    def track_changes
      changes
    end

  private

    def root
      defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)
    end

    def changes
      @changes ||= Changes.new(config.serializers_dirs)
    end

    def all_serializer_files
      config.serializers_dirs.flat_map { |dir| Dir["#{dir}/**/*.rb"] }.sort
    end

    def load_serializers(files)
      files.each { |file| require file }
    end

    def loaded_serializers
      config.base_serializers.map(&:constantize)
        .flat_map(&:descendants)
        .uniq
        .sort_by(&:name)
        .reject { |s| skip_serializer?(s) }
    rescue NameError
      raise ArgumentError, "Please ensure all your serializers extend BaseSerializer, or configure `config.base_serializers`."
    end

    def default_config(root)
      Config.new(
        # The base serializers that all other serializers extend.
        base_serializers: ["BaseSerializer"],

        # The dirs where the serializer files are located.
        serializers_dirs: [root.join("app/serializers").to_s],

        # The dir where interface files are placed.
        output_dir: root.join(defined?(ViteRuby) ? ViteRuby.config.source_code_dir : "app/frontend").join("types/serializers"),

        # Remove the serializer suffix from the class name.
        name_from_serializer: ->(name) { name.delete_suffix("Serializer") },

        # Types that don't need to be imported in TypeScript.
        native_types: [
          "Array",
          "Record",
          "Date",
        ].to_set,

        # Maps SQL column types to TypeScript native and custom types.
        sql_to_typescript_type_mapping: {
          boolean: :boolean,
          date: "string | Date",
          datetime: "string | Date",
          decimal: :number,
          integer: :number,
          string: :string,
          text: :string,
        }.tap do |types|
          types.default = :unknown
        end,
      )
    end

    # Internal: Writes if the file does not exist or the cache key has changed.
    # The cache strategy consists of a comment on the first line of the file.
    #
    # Yields to receive the rendered file content when it needs to.
    def write_if_changed(filename:, cache_key:)
      filename = config.output_dir.join("#{filename}.ts")
      FileUtils.mkdir_p(filename.dirname)
      cache_key_comment = "// TypesFromSerializers CacheKey #{Digest::MD5.hexdigest(cache_key)}\n"
      File.open(filename, "a+") { |file|
        if stale?(file, cache_key_comment)
          file.truncate(0)
          file.write(cache_key_comment)
          file.write(yield)
        end
      }
    end

    def serializers_index_content(serializers)
      <<~TS
        //
        // DO NOT MODIFY: This file was automatically generated by TypesFromSerializers.
        #{serializers.map { |s|
          "export type { default as #{s.ts_name} } from './#{s.ts_filename}'"
        }.join("\n")}
      TS
    end

    def serializer_interface_content(interface)
      <<~TS
        //
        // DO NOT MODIFY: This file was automatically generated by TypesFromSerializers.
        #{interface.used_imports.join}
        export default #{interface.as_typescript}
      TS
    end

    # Internal: Returns true if the cache key has changed since the last codegen.
    def stale?(file, cache_key_comment)
      @force_generation || file.gets != cache_key_comment
    end
  end
end
