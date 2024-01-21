# frozen_string_literal: true

require "active_support/concern"

# Internal: A DSL to specify types for serializer attributes.
module TypesFromSerializers
  module Ams
    extend ActiveSupport::Concern

    module ClassMethods
      # Override: Capture the name of the model related to the serializer.
      #
      # name - An alias for the internal object in the serializer.
      # model - The name of an ActiveRecord model to infer types from the schema.
      # types_from - The name of a TypeScript interface to infer types from.
      def object_as(name, model: nil, types_from: nil)
        # NOTE: Avoid taking memory for type information that won't be used.
        if Rails.env.development?
          model ||= name.is_a?(Symbol) ? name : try(:_serializer_model_name) || name
          define_singleton_method(:_serializer_model_name) { model }
          define_singleton_method(:_serializer_types_from) { types_from } if types_from
        end
      end

      # Public: Shortcut for typing a serializer attribute.
      #
      # It specifies the type for a serializer method that will be defined
      # immediately after calling this method.
      def type(type, **options)
        attribute type: type, **options
      end

      def prepare_attributes(transform_keys: nil, sort_by: nil)
        attributes = _attributes_data.transform_values do |attribute|
          {
            value_from: attribute.name.to_s,
            attribute: :method,
            identifier: attribute.name == :id,
          }
        end

        association_attributes = _reflections.transform_values do |association|
          {
            value_from: association.name.to_s,
            association: one_association?(association) ? :one : :many,
            serializer: association.options[:serializer],
            identifier: association.name == :id,
          }
        end

        attributes.merge!(association_attributes)
      end

    private

      def one_association?(association)
        # rubocop:disable Style/ClassEqualityComparison
        return false if association.class.name == "ActiveModel::Serializer::HasManyReflection"
        # rubocop:enable Style/ClassEqualityComparison

        true
      end

      # Override: Remove unnecessary options in production, types are only
      # used when generating code in development.
      unless Rails.env.development?
        def add_attribute(name, type: nil, optional: nil, **options)
          super(name, **options)
        end
      end
    end
  end
end
