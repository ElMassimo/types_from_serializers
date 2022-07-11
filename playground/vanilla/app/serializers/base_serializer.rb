require "types_from_serializers/dsl"

class BaseSerializer < Oj::Serializer
  include TypesFromSerializer::DSL
end
