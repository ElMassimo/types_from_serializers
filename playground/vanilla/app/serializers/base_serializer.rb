class BaseSerializer < Oj::Serializer
  include TypesFromSerializer::DSL

  transform_keys :camelize
end
