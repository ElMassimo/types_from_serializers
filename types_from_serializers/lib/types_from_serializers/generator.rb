# frozen_string_literal: true

require "digest"
require "fileutils"
require "pathname"

# Public: Automatically generates TypeScript interfaces for Ruby serializers.
module TypesFromSerializers
  DEFAULT_TRANSFORM_KEYS = ->(key) { key.camelize(:lower).chomp("?") }

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

      # Internal: If the serializer was defined inside a file.
      def inline_serializer?
        name.include?("Serializer::")
      end

      # Internal: The TypeScript properties of the serialzeir interface.
      def ts_properties
        @ts_properties ||= begin
          model_class = _serializer_model_name&.to_model
          model_columns = model_class.try(:columns_hash) || {}
          model_enums = model_class.try(:defined_enums) || {}
          types_from = try(:_serializer_types_from)

          prepare_attributes(
            sort_by: TypesFromSerializers.config.sort_properties_by,
            transform_keys: TypesFromSerializers.config.transform_keys || try(:_transform_keys) || DEFAULT_TRANSFORM_KEYS,
          )
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
                  property.infer_type_from(model_columns, model_enums, types_from)
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
    :global_types,
    :sort_properties_by,
    :sql_to_typescript_type_mapping,
    :skip_serializer_if,
    :transform_keys,
    :namespace,
    keyword_init: true,
  ) do
    def relative_custom_types_dir
      @relative_custom_types_dir ||= (custom_types_dir || output_dir.parent).relative_path_from(output_dir)
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
        .reject { |type| type.name == name } # avoid self-imports (e.g. for recursive types)
        .map { |type| [type.name, relative_path(type.pathname, pathname)] }

      custom_type_imports = attribute_types
        .flat_map { |type| extract_typescript_types(type.to_s) }
        .uniq
        .reject { |type| global_type?(type) }
        .map { |type|
          type_path = TypesFromSerializers.config.relative_custom_types_dir.join(type)
          [type, relative_path(type_path, pathname)]
        }

      (custom_type_imports + serializer_type_imports)
        .map { |interface, filename| "import type #{interface} from '#{filename}'\n" }
    end

    def as_typescript
      indent = TypesFromSerializers.config.namespace ? 3 : 1
      <<~TS.gsub(/\n$/, "")
        interface #{name} {
        #{"  " * indent}#{properties.index_by(&:name).values.map(&:as_typescript).join("\n#{"  " * indent}")}
        #{"  " * (indent - 1)}}
      TS
    end

  protected

    def pathname
      @pathname ||= Pathname.new(filename)
    end

    # Internal: Calculates a relative path that can be used in an import.
    def relative_path(target_path, importer_path)
      path = target_path.relative_path_from(importer_path.parent).to_s
      path.start_with?(".") ? path : "./#{path}"
    end

    # Internal: Extracts any types inside generics or array types.
    def extract_typescript_types(type)
      type.split(/[<>\[\],\s|]+/)
    end

    # NOTE: Treat uppercase names as custom types.
    # Lowercase names would be native types, such as :string and :boolean.
    def global_type?(type)
      type[0] == type[0].downcase || TypesFromSerializers.config.global_types.include?(type)
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
    def infer_type_from(columns_hash, defined_enums, ts_interface)
      if type
        type
      elsif (enum = defined_enums[column_name.to_s])
        self.type = enum.keys.map(&:inspect).join(" | ")
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

      if config.namespace
        load_serializers(all_serializer_files) if force
      else
        generate_index_file
      end

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

      write_if_changed(filename: interface.filename, cache_key: interface.inspect, extension: config.namespace ? "d.ts" : "ts") {
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
      serializer.name.in?(config.base_serializers) ||
        config.skip_serializer_if.call(serializer)
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
        name_from_serializer: ->(name) {
          name.split("::").map { |n| n.delete_suffix("Serializer") }.join("::")
        },

        # Types that don't need to be imported in TypeScript.
        global_types: [
          "Array",
          "Record",
          "Date",
        ].to_set,

        # Allows to choose a different sort order, alphabetical by default.
        sort_properties_by: :name,

        # Allows to avoid generating a serializer.
        skip_serializer_if: ->(serializer) { false },

        # Maps SQL column types to TypeScript native and custom types.
        sql_to_typescript_type_mapping: {
          boolean: :boolean,
          time: "string | Date",
          date: "string | Date",
          datetime: "string | Date",
          decimal: "string | number",
          integer: :number,
          string: :string,
          text: :string,
          citext: :string,
          uuid: :string,
          json: "Record<string, any>",
          jsonb: "Record<string, any>",
        }.tap do |types|
          types.default = :unknown
        end,

        # Allows to transform keys, useful when converting objects client-side.
        transform_keys: nil,

        # Allows scoping typescript definitions to a namespace
        namespace: nil,
      )
    end

    # Internal: Writes if the file does not exist or the cache key has changed.
    # The cache strategy consists of a comment on the first line of the file.
    #
    # Yields to receive the rendered file content when it needs to.
    def write_if_changed(filename:, cache_key:, extension: "ts")
      filename = config.output_dir.join("#{filename}.#{extension}")
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
        #{serializers.reject(&:inline_serializer?).map { |s|
          "export type { default as #{s.ts_name} } from './#{s.ts_filename}'"
        }.join("\n")}
      TS
    end

    def serializer_interface_content(interface)
      config.namespace ? declaration_interface_definition(interface) : standard_interface_definition(interface)
    end

    def standard_interface_definition(interface)
      <<~TS
        //
        // DO NOT MODIFY: This file was automatically generated by TypesFromSerializers.
        #{interface.used_imports.join}
        export default #{interface.as_typescript}
      TS
    end

    def declaration_interface_definition(interface)
      <<~TS
        //
        // DO NOT MODIFY: This file was automatically generated by TypesFromSerializers.
        #{interface.used_imports.empty? ? "export {}\n" : interface.used_imports.join}
        declare global {
          namespace #{config.namespace} {
            #{interface.as_typescript}
          }
        }
      TS
    end

    # Internal: Returns true if the cache key has changed since the last codegen.
    def stale?(file, cache_key_comment)
      @force_generation || file.gets != cache_key_comment
    end
  end
end
