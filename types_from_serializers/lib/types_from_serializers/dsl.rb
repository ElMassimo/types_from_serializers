# frozen_string_literal: true

require "active_support/concern"

# Internal: A DSL to specify types for serializer attributes.
module TypesFromSerializer
  module DSL
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
          model ||= name.is_a?(Symbol) ? name : try(:_serializer_model_name)
          define_method(:_serializer_model_name) { model || name }
          define_method(:_serializer_types_from) { types_from } if types_from
        end

        super(name)
      end

      # Public: Shortcut for typing a serializer attribute.
      #
      # It specifies the type for a serializer method that will be defined
      # immediately after calling this method.
      def type(type, **options)
        attribute type: type, **options
      end

    private

      # Override: Remove unnecessary options in production, types are only
      # used when generating code in development.
      unless Rails.env.development?
        def add_attribute(name, options)
          options.except!(:type, :optional)
          super
        end
      end
    end
  end
end
