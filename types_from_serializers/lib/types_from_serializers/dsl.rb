# frozen_string_literal: true

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
          @_serializer_model_name = model || name
          @_serializer_types_from = types_from if types_from
        end

        super(name)
      end

      # Public: Like `attributes`, but providing type information for each field.
      def typed_attributes(attrs)
        attributes(*attrs.keys)

        # NOTE: Avoid taking memory for type information that won't be used.
        if Rails.env.development?
          _typed_attributes.update(attrs.map { |key, type|
            [key.to_s, type.is_a?(Hash) ? type : {type: type}]
          }.to_h)
        end
      end

      # Public: Allows to specify the type for a serializer method that will
      # be defined immediately after calling this method.
      def type(type = :unknown, optional: false)
        @_current_attribute_type = {type: type, optional: optional}
      end

      # Internal: Intercept a method definition, tying a type that was
      # previously specified to the name of the attribute.
      def method_added(name)
        super(name)
        if @_current_attribute_type
          serializer_attributes name

          # NOTE: Avoid taking memory for type information that won't be used.
          if Rails.env.development?
            _typed_attributes[name.to_s] = @_current_attribute_type
          end

          @_current_attribute_type = nil
        end
      end

      # NOTE: Avoid taking memory for type information that won't be used.
      if Rails.env.development?
        # Internal: Contains type information for serializer attributes.
        def _typed_attributes
          unless defined?(@_typed_attributes)
            @_typed_attributes = superclass.try(:_typed_attributes)&.dup || {}
          end
          @_typed_attributes
        end

        # Internal: The name of the model that will be serialized by this
        # serializer, used to infer field types from the SQL columns.
        def _serializer_model_name
          unless defined?(@_serializer_model_name)
            @_serializer_model_name = superclass.try(:_serializer_model_name)
          end
          @_serializer_model_name
        end

        # Internal: The TypeScript interface that will be used by default to
        # infer the serializer field types when not explicitly provided.
        def _serializer_types_from
          unless defined?(@_serializer_types_from)
            @_serializer_types_from = superclass.try(:_serializer_types_from)
          end
          @_serializer_types_from
        end
      end
    end
  end
end
