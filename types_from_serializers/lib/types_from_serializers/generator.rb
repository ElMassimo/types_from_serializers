# frozen_string_literal: true

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
        self.optional = true if column.null && column.default.nil?
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

    # Public: Registry of named configurations for multi-app setups.
    def configs
      @configs ||= {}
    end

    # Public: Configuration of the code generator.
    # Without a name: returns/modifies the default config (backward compatible).
    # With a name: returns/creates a named config for a specific sub-app.
    def config(name = :default, &block)
      cfg = if name == :default
        @config ||= default_config(root)
      else
        configs[name] ||= default_config(root)
      end
      cfg.tap { |c| yield(c) if block }
    end

    # Public: Generates code for all serializers in the app.
    #
    # force - Deletes the output dir first, so that files for serializers that
    #         were renamed or removed don't linger.
    def generate(force: ENV["SERIALIZER_TYPES_FORCE"])
      config.output_dir.rmtree if force && config.output_dir.exist?
      load_serializers(all_serializer_files)
      generate_index_file unless config.namespace
      generate_interfaces
    end

    # Public: Generates types for all registered configurations (default + named).
    # Use this in monolith setups with multiple sub-apps.
    def generate_all(force: ENV["SERIALIZER_TYPES_FORCE"])
      all_configs_list.each do |cfg|
        with_active_config(cfg) { generate(force: force) }
      end
    end

    # Public: Generates code only for serializers whose files changed since the
    # last run, which avoids loading every serializer on each reload.
    #
    # When files were only modified, the index can't have changed (it's derived
    # from file names), so only the modified serializers and the ones that
    # depend on them are regenerated. Added or removed files require a full pass.
    def generate_changed
      chg = changes_for(config)
      return unless chg.updated?

      if chg.only_modified?
        load_serializers_and_dependents(chg.modified_files)
        generate_interfaces
      else
        generate(force: chg.any_removed?)
      end
      chg.clear
    end

    # Public: Like generate_changed but for all registered configurations.
    def generate_all_changed
      all_configs_list.each do |cfg|
        with_active_config(cfg) { generate_changed }
      end
    end

    # Internal: Defines a TypeScript interface for the serializer.
    def generate_interface_for(serializer)
      interface = serializer.ts_interface

      write_if_changed(filename: interface.filename, extension: config.namespace ? "d.ts" : "ts") {
        serializer_interface_content(interface)
      }
    end

    # Internal: Allows to import all serializer types from a single file.
    def generate_index_file
      write_if_changed(filename: "index") {
        serializers_index_content(loaded_serializers)
      }
    end

    # Internal: Checks if it should avoid generating an interface.
    def skip_serializer?(serializer)
      serializer.name.in?(config.base_serializers) ||
        config.skip_serializer_if.call(serializer)
    end

    # Internal: Returns the Changes tracker for the default config (backward compatible).
    def track_changes
      changes_for(config)
    end

    # Public: Returns Changes trackers for all registered configurations.
    def all_changes
      all_configs_list.map { |cfg| changes_for(cfg) }
    end

  private

    def root
      defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)
    end

    def changes_for(cfg)
      @changes_registry ||= {}
      @changes_registry[cfg.object_id] ||= Changes.new(cfg.serializers_dirs)
    end

    # Internal: Returns the default config followed by all named configs.
    def all_configs_list
      [(@config || default_config(root))] + configs.values
    end

    # Internal: Temporarily sets the active config for the duration of a block,
    # so all internal methods and refinements pick up the correct config.
    def with_active_config(cfg)
      saved, @config = @config, cfg
      yield
    ensure
      @config = saved
    end

    def generate_interfaces
      loaded_serializers.each { |serializer| generate_interface_for(serializer) }
    end

    # Internal: Requires the given serializer files, plus every serializer file
    # whose interface depends on a serializer they define, transitively. Rails
    # unloads all classes before to_prepare, so subclasses and flat associations
    # of a modified serializer would otherwise stay unloaded, and their files
    # stale.
    def load_serializers_and_dependents(files)
      loaded = Set.new
      pending = files.to_a
      until pending.empty?
        load_serializers(pending)
        loaded.merge(pending)
        names = serializer_names_defined_in(pending)
        pending = names.empty? ? [] : serializer_files_depending_on(names).reject { |file| loaded.include?(file) }
      end
    end

    def serializer_names_defined_in(files)
      base_serializers = config.base_serializers.filter_map(&:safe_constantize)
      (base_serializers + base_serializers.flat_map(&:descendants))
        .select { |serializer| files.include?(Object.const_source_location(serializer.name)&.first) }
        .map { |serializer| serializer.name.demodulize }
        .uniq
    end

    # Internal: Files whose serializers inherit from, or flat-embed, one of the
    # named serializers: the only references that change a generated interface,
    # since plain associations only import the other interface by name.
    #
    # A file is scanned as text rather than loaded, so this is cheap. Flat
    # associations are matched loosely (a flat call anywhere plus the name
    # anywhere) so that multi-line calls aren't missed.
    def serializer_files_depending_on(names)
      alternatives = names.map { |name| Regexp.escape(name) }.join("|")
      inherits = /<\s*(?:\w+::)*(?:#{alternatives})\b/
      mentions = /\b(?:#{alternatives})\b/
      all_serializer_files.select { |file|
        source = File.read(file)
        source.match?(inherits) || (source.include?("flat") && source.match?(mentions))
      }
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

    # Internal: Writes the file unless it already has the same content, which
    # keeps mtimes stable so file watchers don't react to no-op generations.
    #
    # Yields to receive the rendered file content.
    def write_if_changed(filename:, extension: "ts")
      filename = config.output_dir.join("#{filename}.#{extension}")
      content = yield
      return if filename.exist? && filename.read == content

      FileUtils.mkdir_p(filename.dirname)
      filename.write(content)
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
  end
end
